import Foundation

// MARK: - FillAssistSelectorParser

/// Parses a CSS selector string into `FillAssistFieldAttributes` by extracting
/// HTML element attributes (id, name, type, role, tagName).
///
enum FillAssistSelectorParser {
    // MARK: Private Constants

    /// Matches `[attr='value']`, `[attr="value"]`, and `[attr=value]` attribute selector syntax,
    /// including hyphenated attribute names (e.g. `data-type`).
    private static let attributeRegex = try? NSRegularExpression(
        pattern: #"\[([-\w]+)\s*=\s*['"]?([^'"\]]+)['"]?\]"#,
        options: [],
    )

    // MARK: Methods

    /// Parses a CSS selector string and returns the extracted HTML attributes, or `nil` if
    /// the selector is unsupported (shadow DOM boundary or class-only selector).
    ///
    /// - Parameter selector: A CSS selector string.
    /// - Returns: Extracted `FillAssistFieldAttributes`, or `nil` for excluded selectors.
    ///
    static func parse(_ selector: String) -> FillAssistFieldAttributes? {
        // Exclude shadow DOM selectors — elements past >>> are not accessible to autofill.
        guard !selector.contains(">>>") else { return nil }

        // Strip the leading tag name (word before first `#`, `[`, `.`).
        let tagName = extractTagName(from: selector)

        // Reject class-only selectors (.foo, .bar) — not actionable.
        if tagName == nil, selector.first == "." { return nil }

        var id: String?
        var name: String?
        var role: String?
        var type: String?

        // Extract `#id` shorthand.
        if let hashRange = selector.range(of: "#") {
            let afterHash = selector[hashRange.upperBound...]
            let idEnd = afterHash.firstIndex(where: { ".[:#".contains($0) }) ?? afterHash.endIndex
            let value = String(afterHash[..<idEnd])
            if !value.isEmpty { id = value }
        }

        // Extract attribute selectors: [attr='value'] / [attr="value"].
        let nsSelector = selector as NSString
        let fullRange = NSRange(location: 0, length: nsSelector.length)
        attributeRegex?.enumerateMatches(in: selector, range: fullRange) { match, _, _ in
            guard let match,
                  let attrRange = Range(match.range(at: 1), in: selector),
                  let valRange = Range(match.range(at: 2), in: selector)
            else { return }
            let attr = String(selector[attrRange])
            let val = String(selector[valRange])
            switch attr {
            case "id": id = id ?? val
            case "name": name = val
            case "role": role = val
            case "type": type = val
            default: break
            }
        }

        // Return nil if no useful attributes were found.
        guard tagName != nil || id != nil || name != nil || role != nil || type != nil else {
            return nil
        }

        return FillAssistFieldAttributes(id: id, name: name, role: role, tagName: tagName, type: type)
    }

    // MARK: Private

    /// Extracts the leading tag name from a selector (e.g. `"input"` from `"input#user"`).
    ///
    private static func extractTagName(from selector: String) -> String? {
        let stopChars = CharacterSet(charactersIn: "#[.:")
        let trimmed = selector.trimmingCharacters(in: .whitespaces)
        guard let stopIndex = trimmed.unicodeScalars.firstIndex(where: { stopChars.contains($0) }) else {
            // No stop character — entire string is the tag (if non-empty and not a class selector).
            return trimmed.isEmpty || trimmed.first == "." ? nil : trimmed
        }
        let tag = String(trimmed[..<stopIndex])
        return tag.isEmpty || tag.first == "." ? nil : tag
    }
}
