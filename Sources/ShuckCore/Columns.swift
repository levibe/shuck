private let tabWidth = 4

extension Character {
	var isIndentation: Bool { self == " " || self == "\t" }
}

/// The one width measure the joining rules use: a Character is a column, a tab is four.
func columns(_ text: some StringProtocol) -> Int {
	text.reduce(0) { $0 + ($1 == "\t" ? tabWidth : 1) }
}
