import Foundation
import Testing
import ShuckCore

private let expected = """
	Changes since the last release:
	- Config loader: "include" → "extends" now resolves relative to the file that names it ("./base.toml", "../shared/…"). Before this it resolved against the working directory.
	- Cache: stale entries are dropped when the lockfile changes, and a single "Cache cleared because dependencies changed" warning is printed. It only appears on the first run after the change, so CI logs stay quiet.
	- Output: --format now accepts json, yaml, table, markdown / {a template path}, and each format has its own snapshot test. Table is still the default.

	Still to do before tagging (see RELEASING.md):
	- Docs: four pages still show the old behavior:
	  - Quick start: "Run init to create a config file"
	  - Configuration: "Paths in include are resolved from the directory you run the command in"
	  - CLI reference: "--format accepts json, yaml or table"
	  - Troubleshooting: "Delete the cache folder when results look out of date"
	"""

/// The ways the same reply reaches the clipboard.
enum Paste: CaseIterable, CustomTestStringConvertible {
	case raw
	case claudeCodeGutter
	case bulletGutter
	case crlf
	case trailingSpaces

	var testDescription: String { "\(self)" }

	func applied(to text: String) -> String {
		let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
		switch self {
		case .raw:
			return text
		case .claudeCodeGutter:
			return "⏺" + lines.map { "  " + $0 }.joined(separator: "\n").dropFirst()
		case .bulletGutter:
			return "●" + lines.map { "  " + $0 }.joined(separator: "\n").dropFirst()
		case .crlf:
			return lines.joined(separator: "\r\n")
		case .trailingSpaces:
			// Terminals pad a copied line out to the pane width.
			return lines.map { $0 + String(repeating: " ", count: max(0, 80 - $0.count)) }.joined(separator: "\n")
		}
	}
}

func fixture(_ name: String) throws -> String {
	let url = try #require(Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures"))
	return try String(contentsOf: url, encoding: .utf8)
}

@Test(arguments: Paste.allCases)
func claudeListUnwraps(_ paste: Paste) throws {
	#expect(shuck(paste.applied(to: try fixture("claude-list"))) == expected)
}

@Test func unwrappedClaudeListIsStable() {
	#expect(shuck(expected) == expected)
}
