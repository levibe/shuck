/// Below this, lines are too short to tell a wrap from a deliberate break.
private let minimumWrapWidth = 40

/// The measured width is only an estimate: wrapping by eye isn't exactly greedy,
/// and a glyph wider than one column still counts as one Character.
private let widthSlack = 2

/// Hanging indents set with a tab or by hand can overshoot the content column slightly.
private let indentTolerance = 2

/// A greedy wrap leaves each line within about a word of its width.
private let raggedness = 10

/// How many lines must end near a width before it counts as a hand wrap.
private let quorum = 3

/// Estimates the width the text was wrapped at, or nil when nothing looks wrapped.
func wrapWidth(of lines: [Line]) -> Int? {
	guard let width = lines.lazy.filter(\.isProse).map(\.width).max(),
		width >= minimumWrapWidth
	else { return nil }
	return width
}

/// Estimates the width a writer wrapped the text at before a narrower terminal wrapped
/// it again, given the text with the terminal's breaks joined. Only a joined line can
/// be wider than the terminal, so several of them ending near one width, each with
/// text still broken off after it, show the writer's wrap.
func handWrapWidth(of lines: [Line], beyond terminalWidth: Int) -> Int? {
	let widths = zip(lines, lines.dropFirst())
		.filter { line, next in line.isProse && next.kind == .plain && line.width > terminalWidth }
		.map { line, _ in line.width }
		.sorted(by: >)
	// The few lines past the crowd are the writer's breaks the terminal pass already joined.
	return widths.indices.dropLast(quorum - 1)
		.first { widths[$0] - widths[$0 + quorum - 1] <= raggedness }
		.map { widths[$0] }
}

func rejoin(_ lines: [Line], width: Int) -> [String] {
	var logicalLines: [LogicalLine] = []
	for line in lines {
		if let separator = logicalLines.last?.separator(joining: line, width: width) {
			logicalLines[logicalLines.count - 1].append(line, separator: separator)
		} else {
			logicalLines.append(LogicalLine(line))
		}
	}
	return logicalLines.map(\.text)
}

/// Physical lines joined so far, and what decides whether the next one continues them.
private struct LogicalLine {
	private(set) var text: String
	private var last: Line
	private let continuationIndents: ClosedRange<Int>

	init(_ line: Line) {
		text = line.text
		last = line
		continuationIndents = line.indent...(line.contentColumn + indentTolerance)
	}

	/// How to join `next` onto this line, or nil when the break looks deliberate.
	func separator(joining next: Line, width: Int) -> String? {
		// A trailing backslash is a shell continuation or a markdown hard break. A
		// terminal wraps an indented line back to the margin, not to its indent.
		guard last.isWrappable, next.kind == .plain, !last.text.hasSuffix("\\"),
			continuationIndents.contains(next.indent) || next.indent == 0
		else { return nil }
		// Greedy wrappers break only when the next word won't fit, so a word that
		// would have fit on the previous line means the break was deliberate.
		guard last.width + 1 + columns(next.firstWord) > width - widthSlack else { return nil }
		if isHardBreak(before: next, width: width) {
			return ""
		}
		// A long lone token fails the fit test after almost any line, so the test
		// can't tell a wrapped path or URL from one listed on its own line.
		guard !last.isLongToken, !next.isLongToken else { return nil }
		return " "
	}

	/// A terminal cuts a token longer than the line mid-token, filling the line
	/// exactly; two separate tokens that long are implausible.
	private func isHardBreak(before next: Line, width: Int) -> Bool {
		let filled = last.width
		// A lone token well past the width overflowed a soft wrap instead of being
		// cut, and a cut never leaves a continuation longer than the line it left.
		return (width...width + widthSlack).contains(filled)
			&& next.width <= filled
			&& columns(last.lastToken) + columns(next.firstToken) > width - next.indent
	}

	mutating func append(_ line: Line, separator: String) {
		text += separator + line.content
		last = line
	}
}
