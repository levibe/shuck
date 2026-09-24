import AppKit
import Foundation
import ShuckCore

let usage = """
	Usage: shuck [-h | --help]

	  Piped stdin:  reads all of stdin, writes the shucked text to stdout.
	    e.g. pbpaste | shuck | pbcopy

	  No stdin (TTY): shucks the general pasteboard's string in place.
	    e.g. shuck
	"""

let arguments = CommandLine.arguments.dropFirst()
if arguments.contains("-h") || arguments.contains("--help") {
	print(usage)
	exit(0)
}

if isatty(FileHandle.standardInput.fileDescriptor) != 0 {
	let pasteboard = NSPasteboard.general
	guard let original = pasteboard.string(forType: .string) else {
		FileHandle.standardError.write(Data("shuck: no string on the pasteboard\n".utf8))
		exit(1)
	}
	pasteboard.clearContents()
	pasteboard.setString(shuck(original), forType: .string)
} else {
	let input = String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
	print(shuck(input), terminator: "")
}
