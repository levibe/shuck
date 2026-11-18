import Foundation

/// Claude Code draws a markdown table with box-drawing characters, padded out to
/// the terminal's width, with long cells wrapped onto extra lines between the row
/// rules. Turning it back into markdown puts each row on one line and shrinks the
/// paste to a fraction of its size. Fenced code, box diagrams and tables the
/// selection cut off stay as drawn.
func restoringMarkdownTables(_ lines: [String]) -> [String] {
	let fenced = fencedLines(lines)
	var result: [String] = []
	var index = lines.startIndex
	while index < lines.endIndex {
		if !fenced[index], let table = markdownTable(at: index, in: lines) {
			result += table.markdown
			index = table.end
		} else {
			result.append(lines[index])
			index += 1
		}
	}
	return result
}

/// The markdown for a whole table whose top border is `lines[start]`, and the
/// index of the line after its bottom border.
private func markdownTable(at start: Int, in lines: [String]) -> (markdown: [String], end: Int)? {
	let top = lines[start].drop(while: \.isIndentation)
	guard top.wholeMatch(of: /┌─+(?:┬─+)+┐/) != nil else { return nil }
	let columns = top.count { $0 == "┬" } + 1
	let body = lines[(start + 1)...].prefix { isRow($0) || isRule($0) }
	guard body.endIndex < lines.endIndex,
		lines[body.endIndex].drop(while: \.isIndentation).wholeMatch(of: /└─+(?:┴─+)+┘/) != nil
	else { return nil }
	// Each block of lines between rules is one row.
	var blocks = body.split(whereSeparator: isRule).map { $0.map(cells) }
	guard blocks.count > 1, blocks.joined().allSatisfy({ $0.count == columns }) else { return nil }
	// With a rule under the header only, lines with every cell filled are a row each;
	// an empty cell shows a row wrapped onto several lines.
	if blocks.count == 2, !blocks[1].joined().contains("") {
		blocks = [blocks[0]] + blocks[1].map { [$0] }
	}
	let rows = blocks.map { block in
		(0..<columns).map { column in
			block.map { $0[column] }.filter { !$0.isEmpty }.joined(separator: " ")
		}
	}
	let indent = lines[start].prefix(while: \.isIndentation)
	let markdown = ([rows[0], Array(repeating: "---", count: columns)] + rows.dropFirst()).map { cells in
		indent + "| " + cells.map { $0.replacingOccurrences(of: "|", with: #"\|"#) }.joined(separator: " | ") + " |"
	}
	return (markdown, body.endIndex + 1)
}

private func isRule(_ line: String) -> Bool {
	line.drop(while: \.isIndentation).wholeMatch(of: /├─+(?:┼─+)+┤/) != nil
}

private func isRow(_ line: String) -> Bool {
	let content = line.drop(while: \.isIndentation)
	return content.count > 1 && content.first == "│" && content.last == "│"
}

/// The trimmed text of each cell in a `│ a │ b │` line.
private func cells(of line: String) -> [String] {
	line.split(separator: "│", omittingEmptySubsequences: false)
		.dropFirst().dropLast()
		.map { $0.trimmingCharacters(in: .whitespaces) }
}
