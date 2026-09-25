import Testing
import ShuckCore

@Suite("Terminal commands")
struct CommandTests {
	@Test func wrappedCommandJoinsWithSpace() {
		let pasted = """
			  gh pr create --base main --title "#3: Add the shuck text core" --body-file
			  /tmp/body.md
			"""
		#expect(shuck(pasted) == "gh pr create --base main --title \"#3: Add the shuck text core\" --body-file /tmp/body.md")
	}

	@Test func hardBrokenURLJoinsWithoutSpace() {
		let pasted = """
			  curl -fsSL https://raw.githubusercontent.com/levibe/shuck/refs/heads/ma
			  in/scripts/install-shuck.sh | bash
			"""
		#expect(shuck(pasted) == "curl -fsSL https://raw.githubusercontent.com/levibe/shuck/refs/heads/main/scripts/install-shuck.sh | bash")
	}

	@Test func urlCutAcrossSeveralLinesRejoins() {
		let pasted = """
			⏺ The release build failed on the second try after one flaky
			  network step timed out, and the full log is at https://githu
			  b.com/levibe/shuck/actions/runs/17283946512/job/49051763288?
			  check_suite_focus=true&pr=12&attempt=2&filter=shuck-core-tes
			  ts#step:6:1042 if you need it.
			"""
		#expect(shuck(pasted) == "The release build failed on the second try after one flaky network step timed out, and the full log is at https://github.com/levibe/shuck/actions/runs/17283946512/job/49051763288?check_suite_focus=true&pr=12&attempt=2&filter=shuck-core-tests#step:6:1042 if you need it.")
	}

	/// Known limitation: a URL the terminal started on a fresh row looks like one
	/// listed on its own line, so only its cut pieces rejoin.
	@Test func urlStartingItsOwnRowStaysOnItsOwnLine() {
		let pasted = """
			⏺ The release build failed on the second try after one flaky
			  network step timed out, and the full log for that run is at
			  https://github.com/levibe/shuck/actions/runs/17283946512/job
			  /49051763288?check_suite_focus=true&pr=12&attempt=2&filter=s
			  huck-core-tests#step:6:1042 if you need it.
			"""
		#expect(shuck(pasted) == """
			The release build failed on the second try after one flaky network step timed out, and the full log for that run is at
			https://github.com/levibe/shuck/actions/runs/17283946512/job/49051763288?check_suite_focus=true&pr=12&attempt=2&filter=shuck-core-tests#step:6:1042 if you need it.
			""")
	}

	@Test func trailingBackslashKeepsBreak() {
		let pasted = #"""
			  swift build -c release --product shuck --arch arm64 --arch x86_64 \
			    --scratch-path .build/universal
			"""#
		#expect(shuck(pasted) == #"""
			swift build -c release --product shuck --arch arm64 --arch x86_64 \
			  --scratch-path .build/universal
			"""#)
	}
}

@Suite("Prose")
struct ProseTests {
	@Test func lineEndingInURLJoinsWithSpace() {
		let pasted = """
			The fix follows the approach described in https://github.com/levibe/shuck/issues/42
			so the heuristics stay predictable for pastes copied out of a terminal window.
			"""
		#expect(shuck(pasted) == "The fix follows the approach described in https://github.com/levibe/shuck/issues/42 so the heuristics stay predictable for pastes copied out of a terminal window.")
	}

	@Test func shortLastWordJoins() {
		let pasted = """
			Greedy wrappers only break a line when the next word would not fit
			on it, so wrapped text ends with a short line like this one from the
			terminal.
			"""
		#expect(shuck(pasted) == "Greedy wrappers only break a line when the next word would not fit on it, so wrapped text ends with a short line like this one from the terminal.")
	}

	@Test func codeSpanStartingALineCountsAsOneWord() {
		let pasted = """
			Before committing, lint each file with `npx eslint --fix <file>`,
			`npx stylelint --fix <file>` and `swift format`, then run the full test suite.
			"""
		#expect(shuck(pasted) == "Before committing, lint each file with `npx eslint --fix <file>`, `npx stylelint --fix <file>` and `swift format`, then run the full test suite.")
	}

	@Test func numberedListJoinsAtContentColumn() {
		let pasted = """
			9. Build the release configuration of the command line tool, then copy the
			   binary into place.
			10. Launch the menu bar app, copy a hard-wrapped reply from the terminal,
			    and paste it into Slack to confirm it reflows.
			"""
		#expect(shuck(pasted) == """
			9. Build the release configuration of the command line tool, then copy the binary into place.
			10. Launch the menu bar app, copy a hard-wrapped reply from the terminal, and paste it into Slack to confirm it reflows.
			""")
	}

	@Test func longUnbreakableListItemsDoNotSetWrapWidth() {
		let pasted = """
			I moved each heuristic into its own file, so that every rule
			can be read and tested on its own:
			- /Users/jappleseed/Projects/shuck/Tests/ShuckCoreTests/ShuckTests.swift
			- /Users/jappleseed/Projects/shuck/Sources/ShuckCore/Normalize.swift
			"""
		#expect(shuck(pasted) == """
			I moved each heuristic into its own file, so that every rule can be read and tested on its own:
			- /Users/jappleseed/Projects/shuck/Tests/ShuckCoreTests/ShuckTests.swift
			- /Users/jappleseed/Projects/shuck/Sources/ShuckCore/Normalize.swift
			""")
	}

	@Test func narrowTextIsLeftAlone() {
		let pasted = """
			This note was wrapped at a
			narrow width by its writer.
			"""
		#expect(shuck(pasted) == pasted)
	}

	@Test func blankLinesAtEdgesDropAndInteriorOnesStay() {
		let pasted = "\n\n   \n  First paragraph.\n\n\n  Second paragraph.\n  \n\n"
		#expect(shuck(pasted) == "First paragraph.\n\n\nSecond paragraph.")
	}

	@Test func emptyInput() {
		#expect(shuck("") == "")
		#expect(shuck(" \n\t\n") == "")
	}

	/// Known limitation: the widest line always passes the fit test, so a lone
	/// long line followed by a short one reads as a wrap.
	@Test func longestLineJoinsWhateverFollows() {
		let pasted = """
			Branch: 12-handle-tabs-in-hanging-indents-and-fenced-code
			PR: #57
			"""
		#expect(shuck(pasted) == "Branch: 12-handle-tabs-in-hanging-indents-and-fenced-code PR: #57")
	}
}

@Suite("Selection without the gutter")
struct PartialGutterTests {
	@Test func firstLineWithoutGutterJoinsTheRest() {
		let pasted = """
			Text copied from Claude has hard line breaks at roughly sixty
			  columns, plus hanging indents under list markers, and often a
			  gutter on every line.

			  Second paragraph.
			"""
		#expect(shuck(pasted) == """
			Text copied from Claude has hard line breaks at roughly sixty columns, plus hanging indents under list markers, and often a gutter on every line.

			Second paragraph.
			""")
	}

	@Test func deeperIndentsStayRelativeToTheGutter() {
		#expect(shuck("def f():\n      return 1") == "def f():\n    return 1")
	}

	/// Accepted cost: an unindented heading over an indented list reads as a
	/// selection that skipped the gutter.
	@Test func indentedListUnderUnindentedLineFlattens() {
		#expect(shuck("Steps:\n  - a\n  - b") == "Steps:\n- a\n- b")
	}

	@Test(arguments: ["⏺ Steps:\n    - a\n    - b", "  Steps:\n    - a\n    - b"])
	func selectionIncludingTheGutterKeepsNesting(_ pasted: String) {
		#expect(shuck(pasted) == "Steps:\n  - a\n  - b")
	}
}

@Suite("Bullets and alignment")
struct BulletTests {
	@Test func symbolBulletsStartItems() {
		let pasted = """
			✓ Build passed after fixing the lint errors in the core module
			✓ Tests passed
			"""
		#expect(shuck(pasted) == pasted)
	}

	@Test func symbolBulletContinuationJoins() {
		let pasted = """
			→ Launch the menu bar app, copy a hard-wrapped reply from the terminal,
			  and paste it into Slack to confirm it reflows.
			⚠️ Done.
			"""
		#expect(shuck(pasted) == """
			→ Launch the menu bar app, copy a hard-wrapped reply from the terminal, and paste it into Slack to confirm it reflows.
			⚠️ Done.
			""")
	}

	@Test func asciiSymbolDoesNotStartItem() {
		let pasted = """
			Adding up every row in the table, with duplicates removed, comes
			= 42 once the carried-over rows from last month are dropped.
			"""
		#expect(shuck(pasted) == "Adding up every row in the table, with duplicates removed, comes = 42 once the carried-over rows from last month are dropped.")
	}

	@Test(arguments: ["1.  ", "-   "])
	func spacesAfterMarkerAreNotAlignment(_ marker: String) {
		let pasted = """
			\(marker)Build the release configuration of the command line tool, then
			    copy the binary into place.
			\(marker)Done.
			"""
		#expect(shuck(pasted) == """
			\(marker)Build the release configuration of the command line tool, then copy the binary into place.
			\(marker)Done.
			""")
	}

	@Test func twoSpacesAfterSentenceAreNotAlignment() {
		let pasted = """
			This is prose typed with two spaces after a period.  It was
			wrapped by the terminal at around sixty columns wide here.
			"""
		#expect(shuck(pasted) == "This is prose typed with two spaces after a period.  It was wrapped by the terminal at around sixty columns wide here.")
	}
}

@Suite("Tabs")
struct TabTests {
	@Test func tabsInFencedCodeSurvive() {
		let pasted = """
			Here is the handler I changed, with the rest of the file left out so the
			diff stays short:
			```go
			func handle() error {
			\tif err != nil {
			\t\treturn err
			\t}
			}
			```
			"""
		#expect(shuck(pasted) == """
			Here is the handler I changed, with the rest of the file left out so the diff stays short:
			```go
			func handle() error {
			\tif err != nil {
			\t\treturn err
			\t}
			}
			```
			""")
	}

	@Test func dedentRemovesOnlyTheSharedPrefix() {
		#expect(shuck("\t\tfoo\n\t\t\tbar") == "foo\n\tbar")
		#expect(shuck("  foo\n\tbar") == "  foo\n\tbar")
	}

	@Test func tabCountsAsFourColumnsInTheFitTest() {
		let pasted = """
			Every tab-indented note below was wrapped at the same width as this line.
			\t- Launch the menu bar app, copy a reply from the terminal and paste
			\t  it into Slack to confirm that it reflows.
			"""
		#expect(shuck(pasted) == """
			Every tab-indented note below was wrapped at the same width as this line.
			\t- Launch the menu bar app, copy a reply from the terminal and paste it into Slack to confirm that it reflows.
			""")
	}

	@Test func tabIndentedContinuationJoins() {
		let pasted = "- Launch the menu bar app, copy a hard-wrapped reply from the terminal,\n\tand paste it into Slack to confirm it reflows."
		#expect(shuck(pasted) == "- Launch the menu bar app, copy a hard-wrapped reply from the terminal, and paste it into Slack to confirm it reflows.")
	}
}

@Suite("Indented lines wrapped to the margin")
struct MarginTests {
	@Test func itemTextWrappedToTheMarginRejoins() {
		let pasted = """
			⏺ Here's the prompt:

			  Steps:
			  1. Collect every PR merged since v0.2.0 with
			  `gh pr list --state merged`,
			     then sort them into Added, Changed and
			  Fixed before writing anything.
			  2. Write each entry in one sentence, lint with
			  `npx markdownlint-cli2 <file>`,
			     and never run the linter on the vendored
			  docs under third_party/docs.
			  3. Build with `make dist SIGN_IDENTITY=levibe`
			  and open the zip on a clean
			     account, then upload it to the draft
			  release and publish the notes.
			"""
		#expect(shuck(pasted) == """
			Here's the prompt:

			Steps:
			1. Collect every PR merged since v0.2.0 with `gh pr list --state merged`, then sort them into Added, Changed and Fixed before writing anything.
			2. Write each entry in one sentence, lint with `npx markdownlint-cli2 <file>`, and never run the linter on the vendored docs under third_party/docs.
			3. Build with `make dist SIGN_IDENTITY=levibe` and open the zip on a clean account, then upload it to the draft release and publish the notes.
			""")
	}

	@Test func stackFrameKeepsTheLineAfterIt() {
		let pasted = """
			TypeError: Cannot read properties of undefined (reading 'width')
			    at measureColumns (/Users/jappleseed/Projects/app/src/columns.js:12:18)
			Node.js v22.9.0
			"""
		#expect(shuck(pasted) == pasted)
	}

	@Test func indentedCommandKeepsTheProseAfterIt() {
		let pasted = """
			⏺ Install it, then link the command into your path:
			    sudo ln -s /Applications/Shuck.app/Contents/Helpers/shuck /usr/local/bin/shuck
			  Then run shuck --help to check that it works.
			"""
		#expect(shuck(pasted) == """
			Install it, then link the command into your path:
			  sudo ln -s /Applications/Shuck.app/Contents/Helpers/shuck /usr/local/bin/shuck
			Then run shuck --help to check that it works.
			""")
	}

	@Test func indentedCommandAmongFullLinesKeepsTheProseAfterIt() {
		let pasted = """
			⏺ I reran the release job after the flaky network step timed out, and
			  it passed on the second try, so the zip on the release page is good.

			  To install it locally, run:
			      make install SIGN_IDENTITY=levibe && open ~/Applications/Shuck.app
			  Then press the shortcut once to check that it still pastes.
			"""
		#expect(shuck(pasted) == """
			I reran the release job after the flaky network step timed out, and it passed on the second try, so the zip on the release page is good.

			To install it locally, run:
			    make install SIGN_IDENTITY=levibe && open ~/Applications/Shuck.app
			Then press the shortcut once to check that it still pastes.
			""")
	}

	/// Known limitation: an indented line outside a list item reads as code, so the
	/// rest of it, wrapped back to the margin, stays on its own line.
	@Test func indentedCommandWrappedToTheMarginStaysSplit() {
		let pasted = """
			⏺ Build both architectures from the root of the repository:
			    swift build -c release --product shuck --arch arm64 --arch x86_64 --scratch-path
			  .build/universal
			    make install
			"""
		#expect(shuck(pasted) == """
			Build both architectures from the root of the repository:
			  swift build -c release --product shuck --arch arm64 --arch x86_64 --scratch-path
			.build/universal
			  make install
			""")
	}
}

@Suite("Structure is preserved")
struct StructureTests {
	@Test func fencedCodeIsVerbatimAndProseAroundItJoins() {
		let pasted = """
			Run the formatter over the whole package before you commit anything so the
			diff stays small:

			```sh
			swift format --in-place --recursive Sources/ShuckCore Tests/ShuckCoreTests Sources/ShuckCLI
			swift test
			make install
			```

			Then open the app from the menu bar and paste something you copied from the
			terminal to check that it reflows.
			"""
		#expect(shuck(pasted) == """
			Run the formatter over the whole package before you commit anything so the diff stays small:

			```sh
			swift format --in-place --recursive Sources/ShuckCore Tests/ShuckCoreTests Sources/ShuckCLI
			swift test
			make install
			```

			Then open the app from the menu bar and paste something you copied from the terminal to check that it reflows.
			""")
	}

	@Test func boxDrawnTableIsPreserved() {
		let pasted = """
			Here is where each target stands after the latest round of changes, with
			the tests included in the core row of the summary table below this line:
			┌──────┬────────┐
			│ core │ green  │
			│ cli  │ red    │
			└──────┴────────┘
			"""
		#expect(shuck(pasted) == """
			Here is where each target stands after the latest round of changes, with the tests included in the core row of the summary table below this line:
			┌──────┬────────┐
			│ core │ green  │
			│ cli  │ red    │
			└──────┴────────┘
			""")
	}

	@Test func markdownTableIsPreserved() {
		let pasted = """
			Both targets build cleanly and the test suite passes on the release branch
			| Target | Status |
			| --- | --- |
			| core | green |
			"""
		#expect(shuck(pasted) == pasted)
	}

	@Test func headingIsNotJoined() {
		let pasted = """
			## A word that would have fit on the line means the break was deliberate
			Greedy wrappers only break a line when the next word would not fit on it, so
			the fit test can tell wrapped prose from lines that the writer ended early.
			"""
		#expect(shuck(pasted) == """
			## A word that would have fit on the line means the break was deliberate
			Greedy wrappers only break a line when the next word would not fit on it, so the fit test can tell wrapped prose from lines that the writer ended early.
			""")
	}

	@Test func blockquoteAndRuleAreNotJoined() {
		let pasted = """
			> Greedy wrappers only break a line when the next word would not fit on it,
			so the fit test can tell wrapped prose from lines that the writer ended early
			on purpose, which is why the rule below ends this paragraph without a join
			---
			"""
		#expect(shuck(pasted) == """
			> Greedy wrappers only break a line when the next word would not fit on it,
			so the fit test can tell wrapped prose from lines that the writer ended early on purpose, which is why the rule below ends this paragraph without a join
			---
			""")
	}

	@Test func shortKeyValueLinesAreUnchanged() {
		let pasted = """
			Branch: foo
			PR: #123
			Status: green
			"""
		#expect(shuck(pasted) == pasted)
	}

	@Test func shortKeyValueLinesAfterWrappedProseAreUnchanged() {
		let pasted = """
			Opened the pull request for the shuck core and pushed the latest round of
			fixes, so everything below is current as of the build from this morning:

			Branch: 3-shuck-core
			PR: #123
			Status: green
			"""
		#expect(shuck(pasted) == """
			Opened the pull request for the shuck core and pushed the latest round of fixes, so everything below is current as of the build from this morning:

			Branch: 3-shuck-core
			PR: #123
			Status: green
			""")
	}

	@Test func alignedColumnsAreNotJoined() {
		let pasted = """
			Open pull requests on the shuck repository as of the morning check-in:
			#3   Add the shuck text core           3-shuck-core      OPEN
			#4   Add the menu bar app and hotkey   4-menu-bar-app    DRAFT
			"""
		#expect(shuck(pasted) == pasted)
	}

	@Test(arguments: ["        ", "\t"])
	func gitStatusIsUnchanged(_ fileIndent: String) {
		let pasted = """
			On branch main
			Changes not staged for commit:
			  (use "git add <file>..." to update what will be committed)
			  (use "git restore <file>..." to discard changes in working directory)
			\(fileIndent)modified:   Sources/ShuckCore/Shuck.swift
			\(fileIndent)modified:   Tests/ShuckCoreTests/ShuckTests.swift

			Untracked files:
			  (use "git add <file>..." to include in what will be committed)
			\(fileIndent)Sources/ShuckCore/Rejoin.swift

			no changes added to commit (use "git add" and/or "git commit -a")
			"""
		#expect(shuck(pasted) == pasted)
	}
}

@Suite("Long lone tokens")
struct LongTokenTests {
	@Test func singleTokenLinesAreUnchanged() {
		let pasted = """
			/Users/jappleseed/Projects/shuck/Sources/ShuckCore/Normalize.swift
			/Users/jappleseed/Projects/shuck/Tests/ShuckCoreTests/ShuckTests.swift
			/Users/jappleseed/Projects/shuck/Sources/ShuckCore/Rejoin.swift
			"""
		#expect(shuck(pasted) == pasted)
	}

	@Test func pathsListedUnderAnIntroStayListed() {
		let pasted = """
			I changed these files in the last commit, please review them:
			/Users/jappleseed/Projects/shuck/Sources/ShuckCore/Normalize.swift
			/Users/jappleseed/Projects/shuck/Tests/ShuckCoreTests/ShuckTests.swift
			"""
		#expect(shuck(pasted) == pasted)
	}

	@Test func overlongTokenOnItsOwnLineStaysThere() {
		let pasted = """
			The upstream discussion of why greedy wrapping works is at
			https://github.com/levibe/shuck/discussions/12#discussioncomment-99887766
			and covers the slack constant as well.
			"""
		#expect(shuck(pasted) == pasted)
	}
}
