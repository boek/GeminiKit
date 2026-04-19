public enum GemTextLine: Sendable, Equatable {
    case text(String)
    case link(GemTextLink)
    case heading1(String)
    case heading2(String)
    case heading3(String)
    case listItem(String)
    case blockquote(String)
    case preformatted(altText: String?, lines: [String])
}
