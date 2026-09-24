private let fenceMarkers = ["```", "~~~"]
private let boxDrawing: ClosedRange<Unicode.Scalar> = "\u{2500}"..."\u{257F}"

/// Past this length a lone token (a path, a URL) is as likely a line of its own
/// as a wrapped word.
private let longTokenLength = 24

/// One physical line after normalization, classified by how it may join its neighbours.
struct Line {
	enum Kind {
		case blank
		/// Never joined in either direction, and ignored when measuring the wrap width.
		case preformatted
		case listItem
		case plain
	}

	let text: String
	/// Leading whitespace, in `columns`.
	let indent: Int
	/// `text` after its leading whitespace.
	let content: Substring
	/// `content` after any list marker and the spaces that follow it.
	let body: Substring
	let kind: Kind

	var width: Int { columns(text) }
	var firstToken: Substring { content.prefix { $0 != " " } }
	var lastToken: Substring { content.split(separator: " ").last ?? content }

	/// Where the item's text starts, which a hanging indent lines up with.
	var contentColumn: Int { indent + columns(content[..<body.startIndex]) }

	var isWrappable: Bool {
		switch kind {
		case .plain, .listItem: true
		case .blank, .preformatted: false
		}
	}

	/// Only prose reveals the wrap width: a line with no space in its text is a
	/// single unbreakable token (a path, a URL fragment) and can run any length.
	var isProse: Bool { isWrappable && body.contains(" ") }

	var isLongToken: Bool { isWrappable && !body.contains(" ") && body.count > longTokenLength }

	static func classify(_ texts: [String]) -> [Line] {
		var openFence: String?
		var lines: [Line] = []
		for text in texts {
			let content = text.drop(while: \.isIndentation)
			var fenced = openFence != nil
			if let fence = openFence {
				if content.hasPrefix(fence) {
					openFence = nil
				}
			} else if let fence = fenceMarkers.first(where: { content.hasPrefix($0) }) {
				openFence = fence
				fenced = true
			}
			lines.append(Line(text, fenced: fenced))
		}
		return lines
	}

	private init(_ text: String, fenced: Bool) {
		let content = text.drop(while: \.isIndentation)
		// Symbols (✓ → ⚠️ ★) lead list-like lines in Claude's replies as often as bullets do.
		// ASCII math symbols (`=`, `<`, `~`) are left out: they start wrapped prose and code.
		let marker = content.prefixMatch(of: /(?:[-*+•◦▪‣]|[0-9]{1,3}[.)]|[[\p{So}\p{Sm}]--[\x00-\x7F]])[ ]+/)
		let body = marker.map { content[$0.range.upperBound...] } ?? content
		self.text = text
		self.content = content
		self.body = body
		indent = columns(text[..<content.startIndex])
		kind = if content.isEmpty {
			.blank
		} else if fenced || Self.isStructural(content) || Self.hasAlignmentGap(body) {
			.preformatted
		} else if marker != nil {
			.listItem
		} else {
			.plain
		}
	}

	private static func isStructural(_ content: Substring) -> Bool {
		// Markdown tables, and the box-drawn tables Claude Code renders them as.
		content.hasPrefix("|")
			|| content.unicodeScalars.contains { boxDrawing.contains($0) }
			|| content.prefixMatch(of: /#+[ ]/) != nil
			|| content.hasPrefix(">")
			|| content.wholeMatch(of: /-{3,}|\*{3,}|_{3,}/) != nil
	}

	/// A space run inside the text is column alignment (`git status`, `ls -l`), not
	/// prose, except a typist's two spaces after a sentence.
	private static func hasAlignmentGap(_ body: Substring) -> Bool {
		body.contains(/[ ]{3,}|[^.!?][ ]{2}/)
	}
}
