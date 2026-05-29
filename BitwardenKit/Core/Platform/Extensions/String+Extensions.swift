import Foundation

/// Extension helpers for `String`.
public extension String {
    /// Tries to convert the string to an `URL`, if it can't then it tries to fix it by adding
    /// a http scheme prefix if it's an IP address or https scheme prefix in any other case.
    /// - Returns: The same `String` if it can be converted to an `URL` or the fixed
    /// `String` otherwise.
    func fixURLIfNeeded() -> String {
        if URL(string: self) != nil {
            return self
        }

        if let url = URL(string: "http://\(self)"), url.isIPAddress {
            return url.absoluteString
        }

        if !hasPrefix("http") {
            return "https://\(self)"
        }

        return self
    }

    /// Returns a copy of the string with common markdown formatting removed, suitable for VoiceOver labels.
    ///
    /// Strips bold (`**text**`, `__text__`), italic (`*text*`, `_text_`), strikethrough (`~~text~~`),
    /// and inline links (`[text](url)` → `text`). Bold patterns are applied before italic to avoid
    /// partial matches on double markers.
    ///
    func removingMarkdownForVoiceOver() -> String {
        var text = self
        let patterns = [
            "\\*\\*(.*?)\\*\\*",
            "__(.*?)__",
            "\\*(.*?)\\*",
            "_(.*?)_",
            "~~(.*?)~~",
            "\\[(.*?)\\]\\(.*?\\)",
        ]
        for pattern in patterns {
            text = text.replacingOccurrences(of: pattern, with: "$1", options: .regularExpression)
        }
        return text
    }
}
