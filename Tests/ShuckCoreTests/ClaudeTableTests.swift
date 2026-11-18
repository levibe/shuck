import Testing
import ShuckCore

/// A markdown table as Claude Code draws it: boxed, padded to the terminal's width,
/// and with long cells wrapped onto extra lines between the row rules.
private let expected = """
	Where each stack stands before the next e2e run:

	| Group | PRs | State | Before a run |
	| --- | --- | --- | --- |
	| Bookmarks bar | #7047 (⇢ #7048) | 88 behind #7048; last red was the outage plus one focusModeSpec failure | merge #7048 in |
	| Tasks sidebar stack | #7087 → #7091 → #7092 | all green Nov 17; #7087 is 110 behind #6640 | merge #6640 into the bottom and cascade up, then 3 runs |
	| Probably skip | #6722 popup preload (2,630 behind, from September), #7049 glossary (docs only, no e2e needed) |  | your call |
	"""

@Test(arguments: Paste.allCases)
func claudeTableBecomesMarkdown(_ paste: Paste) throws {
	#expect(shuck(paste.applied(to: try fixture("claude-table"))) == expected)
}

@Test func restoredClaudeTableIsStable() {
	#expect(shuck(expected) == expected)
}
