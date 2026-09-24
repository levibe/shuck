# Shuck

Copy text from Claude Code, press <kbd>⌃⌥⌘V</kbd>, and it pastes without the terminal's line breaks.

Copied from the terminal:

```
⏺ The release build failed on the second try because one flaky
  network step timed out, so I reran the job and it passed.
  The full log is still on the Actions tab if you want it.

  Next steps:
  - Merge the pull request once the review comes back, then
    tag the release
  - Update the changelog
```

Pasted with Shuck:

```
The release build failed on the second try because one flaky network step timed out, so I reran the job and it passed. The full log is still on the Actions tab if you want it.

Next steps:
- Merge the pull request once the review comes back, then tag the release
- Update the changelog
```

It works on any terminal or hard-wrapped text. Wrapped shell commands become one line again, and lists, headings, tables and code stay as they are.

## Installing

Requires macOS 13 or later, on Apple Silicon or Intel.

1. Download `Shuck.zip` from the [latest release](https://github.com/levibe/shuck/releases/latest), unzip it, and move Shuck into Applications.
2. Open it. macOS blocks it because it isn't notarized; click **Open Anyway** in System Settings > Privacy & Security.
3. Press <kbd>⌃⌥⌘V</kbd> once and allow Accessibility when asked.

Repeat step 2 for each new version.

## Using it

Shuck runs in the background, with no window or menu bar icon.

- <kbd>⌃⌥⌘V</kbd> pastes the clipboard without the line breaks. Pressing it again pastes the same result.
- **Right-click > Services > Shuck and Paste** does the same in most native Mac apps. Slack and other Electron apps don't show Services, so use the shortcut there.

The shortcut can't be changed. Pasted text is plain, so bold, links and other formatting are dropped.

Shuck starts at login; turn that off in System Settings > General > Login Items. To quit, run `killall Shuck` or use Activity Monitor.

## Accessibility and privacy

The shortcut needs Accessibility access so Shuck can press <kbd>⌘V</kbd> for you. macOS asks the first time you use it. Until you allow it, the shortcut beeps instead of pasting, but the clipboard is still cleaned up, so <kbd>⌘V</kbd> pastes the result. The right-click item doesn't need access.

Shuck only reads the clipboard when you use it, and never connects to the network.

Updates keep Accessibility access, because every release is signed with the same certificate.

## Command line

Shuck comes with a `shuck` command that does the same in a shell. To use it, link it into `/usr/local/bin`:

```
sudo mkdir -p /usr/local/bin
sudo ln -s /Applications/Shuck.app/Contents/Helpers/shuck /usr/local/bin/shuck
```

Then:

```
pbpaste | shuck        # stdin to stdout
shuck                  # no stdin: clean up the clipboard in place
```

## Building from source

Needs Swift 6 (Xcode 16 or later, or its Command Line Tools).

```
make install
```

This installs Shuck to `~/Applications` and links the `shuck` command into `~/.local/bin`, which needs to be on your `PATH`.

- `make test` runs the tests. It needs Xcode; set `XCODE_DEVELOPER` if Xcode isn't in `/Applications`.
- `make dist` builds `build/Shuck.zip` for Apple Silicon and Intel.
- `SIGN_IDENTITY` sets the signing certificate. Without one, macOS treats every build as a new app, and you have to allow Accessibility again after each rebuild.

A free self-signed certificate works:

1. In Keychain Access, choose Keychain Access > Certificate Assistant > Create a Certificate.
2. Set Identity Type to Self Signed Root and Certificate Type to Code Signing. Tick "Let me override defaults" to make it last longer than a year.
3. Build with `make install SIGN_IDENTITY="<name>"`, or export `SIGN_IDENTITY` in your shell profile.

## How it decides

Shuck guesses from line lengths and shape instead of parsing markdown:

- Removes trailing spaces and Claude Code's 2-space margin, even when your selection starts at the first word.
- Takes the longest line with a space in it as the wrap width.
- Joins a line to the one before only if its first word wouldn't have fit there. Otherwise the break was on purpose, so it stays.
- Never merges list items (including ✓ or → bullets), headings, blockquotes, tables, aligned columns, fenced code, or lines ending in `\`.
- Leaves a long path or URL on its own line alone, but rejoins a URL the terminal cut mid-word.

### Limitations

- The longest line can merge with an unrelated line after it. To get the original, copy it again and paste with <kbd>⌘V</kbd>.
- A URL that starts a new terminal row stays on its own line instead of joining the text before it.
- An indented list under an unindented line loses its indent.

## Uninstalling

1. Quit Shuck with `killall Shuck`.
2. Delete Shuck from Applications (or `~/Applications` if you built it), and the `shuck` link if you made one.
3. Remove Shuck from System Settings > General > Login Items and from Privacy & Security > Accessibility.

## License

[MIT](LICENSE)
