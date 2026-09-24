import Foundation

/// Claude Code marks the first line of a reply with one of these where every
/// other line carries a two-space gutter.
private let gutterGlyphs: Set<Unicode.Scalar> = ["\u{23FA}", "\u{25CF}"]
private let gutter = "  "

/// Strips trailing whitespace, Claude Code's gutter and any common indent, and
/// drops blank lines at either end. Leading tabs are kept as they are.
func normalizedLines(_ text: String) -> [String] {
	let lines = text
		.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
		.map(trimmingTrailingWhitespace)
	guard let first = lines.firstIndex(where: { !$0.isEmpty }),
		let last = lines.lastIndex(where: { !$0.isEmpty })
	else { return [] }
	var trimmed = Array(lines[first...last])
	trimmed[0] = blankingGutterGlyph(trimmed[0])
	return strippingPartialGutter(trimmed) ?? dedented(trimmed)
}

private func trimmingTrailingWhitespace(_ line: Substring) -> String {
	var line = line
	while line.last?.isWhitespace == true {
		line.removeLast()
	}
	return String(line)
}

/// Swapping the glyph for a space lets `dedented` strip the gutter uniformly.
private func blankingGutterGlyph(_ line: String) -> String {
	guard let glyph = line.unicodeScalars.first, gutterGlyphs.contains(glyph),
		line.dropFirst().first == " "
	else { return line }
	return " " + line.dropFirst()
}

/// A terminal selection usually starts at the first word, so that line lacks the
/// gutter every other line still has. The gutter's width is known, so strip exactly
/// that and keep deeper indents relative to it.
private func strippingPartialGutter(_ lines: [String]) -> [String]? {
	let rest = lines.dropFirst()
	guard lines[0].first?.isIndentation == false,
		rest.contains(where: { !$0.isEmpty }),
		rest.allSatisfy({ $0.isEmpty || $0.hasPrefix(gutter) })
	else { return nil }
	return [lines[0]] + rest.map { String($0.dropFirst(gutter.count)) }
}

/// Removes the leading whitespace every non-blank line shares, compared as text
/// (Python's `textwrap.dedent`), so mixed tabs and spaces are never half-stripped.
private func dedented(_ lines: [String]) -> [String] {
	let indents = lines.filter { !$0.isEmpty }.map { String($0.prefix(while: \.isIndentation)) }
	let margin = indents.dropFirst().reduce(indents[0]) { $0.commonPrefix(with: $1) }
	return lines.map { String($0.dropFirst(margin.count)) }
}
