/// Rejoins lines that were hard-wrapped for display (by a terminal, or by the
/// writer) so the paste target can reflow them, keeping deliberate structure.
public func shuck(_ text: String) -> String {
	let lines = Line.classify(normalizedLines(text))
	let rejoined = wrapWidth(of: lines).map { rejoin(lines, width: $0) } ?? lines.map(\.text)
	return rejoined.joined(separator: "\n")
}
