/// Below this, lines are too short to tell a wrap from a deliberate break.
private let minimumWrapWidth = 40

/// The measured width is only an estimate: wrapping by eye isn't exactly greedy,
/// and a glyph wider than one column still counts as one Character.
private let widthSlack = 2

/// Hanging indents set with a tab or by hand can overshoot the content column slightly.
private let indentTolerance = 2

/// Estimates the width the text was wrapped at, or nil when nothing looks wrapped.
func wrapWidth(of lines: [Line]) -> Int? {
	guard let width = lines.lazy.filter(\.isProse).map(\.width).max(),
		width >= minimumWrapWidth
	else { return nil }
	return width
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
		// A trailing backslash is a shell continuation or a markdown hard break.
		guard last.isWrappable, next.kind == .plain, !last.text.hasSuffix("\\"),
			continuationIndents.contains(next.indent)
		else { return nil }
		// Greedy wrappers break only when the next word won't fit, so a word that
		// would have fit on the previous line means the break was deliberate.
		guard last.width + 1 + columns(next.firstToken) > width - widthSlack else { return nil }
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
