import Testing
import ShuckCore

/// A prompt Claude wrapped by hand at about 88 columns inside a code block, which
/// Claude Code then wrapped again at 58, sending indented lines back to the margin.
private let expected = """
	Prompt for the 0.3.0 release notes

	Finish the release notes for Shuck 0.3.0 on the 21-release-notes branch before tagging.

	Where: branch 21-release-notes (PR #22), worktree .worktrees/21-release-notes, stacked on 19-hand-wrapped-prompts-in-code-blocks (#20) and the tagging branch release-sep-26. Do merges in throwaway worktrees, never in the main checkout: other sessions switch its HEAD without warning.

	Rule: each entry says what changed in one sentence, with a second sentence only for a caveat that changes what a caller gets.
	Leave out of the notes: refactors, test-only changes, and anything reverted before the release.

	Steps:
	1. Collect every PR merged since v0.2.0 with `gh pr list --state merged --base main`, and sort them into Added, Changed and Fixed.
	2. Write the entries and lint them (`npx markdownlint-cli2 <file>`, `npx prettier --check <file>`, never on the vendored docs). Run `make test`.
	3. Build with `make dist SIGN_IDENTITY=levibe` and check that the zip opens on a clean account before you upload it.
	"""

@Test(arguments: Paste.allCases)
func claudePromptUnwraps(_ paste: Paste) throws {
	#expect(shuck(paste.applied(to: try fixture("claude-prompt"))) == expected)
}

@Test func unwrappedClaudePromptIsStable() {
	#expect(shuck(expected) == expected)
}
