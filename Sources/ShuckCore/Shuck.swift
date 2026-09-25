/// Rejoins lines that were hard-wrapped for display (by a terminal, or by the
/// writer) so the paste target can reflow them, keeping deliberate structure.
public func shuck(_ text: String) -> String {
	let lines = Line.classify(normalizedLines(text))
	guard let width = wrapWidth(of: lines) else { return lines.map(\.text).joined(separator: "\n") }
	let rejoined = Line.classify(rejoin(lines, width: width))
	// Text wrapped by hand, then again by a narrower terminal, is still wrapped at the
	// hand width once the terminal's breaks are joined.
	let unwrapped = handWrapWidth(of: rejoined, beyond: width).map { rejoin(rejoined, width: $0) } ?? rejoined.map(\.text)
	return unwrapped.joined(separator: "\n")
}
