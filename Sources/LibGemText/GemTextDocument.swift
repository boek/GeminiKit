import Foundation

public struct GemTextDocument: Sendable {
    public let lines: [GemTextLine]

    public init(parsing text: String) {
        var result: [GemTextLine] = []
        var inPreformatted = false
        var preformattedAltText: String? = nil
        var preformattedLines: [String] = []

        for rawLine in text.components(separatedBy: "\n") {
            let line = rawLine.hasSuffix("\r") ? String(rawLine.dropLast()) : rawLine

            if inPreformatted {
                if line.hasPrefix("```") {
                    result.append(.preformatted(altText: preformattedAltText, lines: preformattedLines))
                    inPreformatted = false
                    preformattedAltText = nil
                    preformattedLines = []
                } else {
                    preformattedLines.append(line)
                }
                continue
            }

            if line.hasPrefix("```") {
                inPreformatted = true
                let altText = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                preformattedAltText = altText.isEmpty ? nil : altText
            } else if line.hasPrefix("=>") {
                let rest = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if let spaceIndex = rest.firstIndex(where: { $0.isWhitespace }) {
                    let urlString = String(rest[rest.startIndex..<spaceIndex])
                    let labelStart = rest.index(after: spaceIndex)
                    let label = labelStart < rest.endIndex
                        ? String(rest[labelStart...]).trimmingCharacters(in: .whitespaces)
                        : nil
                    if let url = URL(string: urlString) {
                        result.append(.link(GemTextLink(url: url, label: label.flatMap { $0.isEmpty ? nil : $0 })))
                    } else {
                        result.append(.text(line))
                    }
                } else if let url = URL(string: rest), !rest.isEmpty {
                    result.append(.link(GemTextLink(url: url, label: nil)))
                } else {
                    result.append(.text(line))
                }
            } else if line.hasPrefix("###") {
                result.append(.heading3(String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("##") {
                result.append(.heading2(String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("#") {
                result.append(.heading1(String(line.dropFirst(1)).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("* ") {
                result.append(.listItem(String(line.dropFirst(2))))
            } else if line.hasPrefix(">") {
                result.append(.blockquote(String(line.dropFirst(1)).trimmingCharacters(in: .whitespaces)))
            } else {
                result.append(.text(line))
            }
        }

        if inPreformatted {
            result.append(.preformatted(altText: preformattedAltText, lines: preformattedLines))
        }

        self.lines = result
    }
}
