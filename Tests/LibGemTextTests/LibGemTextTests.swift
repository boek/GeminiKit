import Testing
import Foundation
import LibGemText

@Suite struct GemTextDocumentTests {
    @Test func parsesPlainText() {
        let doc = GemTextDocument(parsing: "Hello, world!")
        #expect(doc.lines == [.text("Hello, world!")])
    }

    @Test func parsesEmptyLine() {
        let doc = GemTextDocument(parsing: "")
        #expect(doc.lines == [.text("")])
    }

    @Test func parsesLinkWithLabel() {
        let doc = GemTextDocument(parsing: "=> gemini://example.com Visit Example")
        #expect(doc.lines == [.link(GemTextLink(url: URL(string: "gemini://example.com")!, label: "Visit Example"))])
    }

    @Test func parsesLinkWithMultiWordLabel() {
        let doc = GemTextDocument(parsing: "=> gemini://example.com A Multi Word Label")
        #expect(doc.lines == [.link(GemTextLink(url: URL(string: "gemini://example.com")!, label: "A Multi Word Label"))])
    }

    @Test func parsesLinkWithoutLabel() {
        let doc = GemTextDocument(parsing: "=> gemini://example.com")
        #expect(doc.lines == [.link(GemTextLink(url: URL(string: "gemini://example.com")!, label: nil))])
    }

    @Test func parsesH1() {
        let doc = GemTextDocument(parsing: "# Heading One")
        #expect(doc.lines == [.heading1("Heading One")])
    }

    @Test func parsesH2() {
        let doc = GemTextDocument(parsing: "## Heading Two")
        #expect(doc.lines == [.heading2("Heading Two")])
    }

    @Test func parsesH3() {
        let doc = GemTextDocument(parsing: "### Heading Three")
        #expect(doc.lines == [.heading3("Heading Three")])
    }

    @Test func parsesListItem() {
        let doc = GemTextDocument(parsing: "* An item")
        #expect(doc.lines == [.listItem("An item")])
    }

    @Test func parsesBlockquote() {
        let doc = GemTextDocument(parsing: "> A quoted line")
        #expect(doc.lines == [.blockquote("A quoted line")])
    }

    @Test func parsesPreformattedBlock() {
        let text = "```\ncode here\nmore code\n```"
        let doc = GemTextDocument(parsing: text)
        #expect(doc.lines == [.preformatted(altText: nil, lines: ["code here", "more code"])])
    }

    @Test func parsesPreformattedBlockWithAltText() {
        let text = "```swift\nlet x = 1\n```"
        let doc = GemTextDocument(parsing: text)
        #expect(doc.lines == [.preformatted(altText: "swift", lines: ["let x = 1"])])
    }

    @Test func parsesUnclosedPreformattedBlock() {
        let text = "```\nsome code"
        let doc = GemTextDocument(parsing: text)
        #expect(doc.lines == [.preformatted(altText: nil, lines: ["some code"])])
    }

    @Test func parsesMixedDocument() {
        let text = "# Heading\nSome text\n=> gemini://example.com A link\n* List item"
        let doc = GemTextDocument(parsing: text)
        #expect(doc.lines == [
            .heading1("Heading"),
            .text("Some text"),
            .link(GemTextLink(url: URL(string: "gemini://example.com")!, label: "A link")),
            .listItem("List item")
        ])
    }

    @Test func stripsWindowsLineEndings() {
        let doc = GemTextDocument(parsing: "Hello\r\nWorld")
        #expect(doc.lines == [.text("Hello"), .text("World")])
    }
}
