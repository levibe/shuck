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

/// Whether a word `wordColumns` wide would have fit after `line`.
private func fits(_ wordColumns: Int, after line: Line, width: Int) -> Bool {
	line.width + 1 + wordColumns <= width - widthSlack
}

/// `firstLineMayBeCut` is for a selection that may have started partway into its
/// first line, leaving that line too short to pass the fit test.
func rejoin(_ lines: [Line], width: Int, firstLineMayBeCut: Bool = false) -> [String] {
	var logicalLines: [LogicalLine] = []
	for line in lines {
		if let separator = logicalLines.last?.separator(joining: line, width: width) {
			logicalLines[logicalLines.count - 1].append(line, separator: separator, width: width)
		} else {
			logicalLines.append(LogicalLine(line, after: logicalLines.last))
		}
	}
	if firstLineMayBeCut, logicalLines.count > 1, logicalLines[0].isCutItem(over: logicalLines[1]) {
		logicalLines[0].append(logicalLines.remove(at: 1))
	}
	return logicalLines.map(\.text)
}

/// Physical lines joined so far, and what decides whether the next one continues them.
private struct LogicalLine {
	private(set) var text: String
	private let first: Line
	private var last: Line
	/// Whether the fit test could have refused one of its joins. A line within a few
	/// columns of the wrap width passes it whatever follows, so a join after one shows nothing.
	private var hasTellingJoin = false
	private let continuationIndents: ClosedRange<Int>
	/// Where the text of the list item this line belongs to continues, if it's in one.
	private let itemIndents: ClosedRange<Int>?

	init(_ line: Line, after previous: LogicalLine?) {
		text = line.text
		first = line
		last = line
		continuationIndents = line.indent...(line.contentColumn + indentTolerance)
		// An indented line under an item is more of the item's text; under anything
		// else it's code, a command or a stack frame.
		itemIndents = if line.kind == .listItem {
			continuationIndents
		} else if let indents = previous?.itemIndents, line.indent > 0, indents.contains(line.indent) {
			indents
		} else {
			nil
		}
	}

	/// How to join `next` onto this line, or nil when the break looks deliberate.
	func separator(joining next: Line, width: Int) -> String? {
		// A trailing backslash is a shell continuation or a markdown hard break. A
		// terminal wraps an item's indented text back to the margin, not to its indent.
		guard last.isWrappable, next.kind == .plain, !last.text.hasSuffix("\\"),
			continuationIndents.contains(next.indent) || (itemIndents != nil && next.indent == 0)
		else { return nil }
		// Greedy wrappers break only when the next word won't fit, so a word that
		// would have fit on the previous line means the break was deliberate.
		guard !fits(columns(next.firstWord), after: last, width: width) else { return nil }
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

	/// A selection starting partway into a list item cuts off its marker, so the
	/// item's wrapped text hangs under a line that looks unrelated. Indented lines
	/// are more likely code or a command unless the fit test shows they wrapped, and
	/// a line ending in a colon (or a shell continuation) introduces them.
	func isCutItem(over next: LogicalLine) -> Bool {
		first.kind == .plain && text == first.text && !text.hasSuffix(":") && !text.hasSuffix("\\")
			&& next.first.kind == .plain && next.first.indent > first.indent && next.hasTellingJoin
	}

	mutating func append(_ line: Line, separator: String, width: Int) {
		// The shortest word the fit test could weigh is one column.
		hasTellingJoin = hasTellingJoin || fits(1, after: last, width: width)
		text += separator + line.content
		last = line
	}

	mutating func append(_ next: LogicalLine) {
		text += " " + next.text.drop(while: \.isIndentation)
		last = next.last
	}
}
