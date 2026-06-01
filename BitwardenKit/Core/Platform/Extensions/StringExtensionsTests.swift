import BitwardenKit
import Testing

// MARK: - StringExtensionsTests

struct StringExtensionsTests {
    // MARK: Tests - fixURLIfNeeded

    /// `fixURLIfNeeded()` returns the correct URL string for valid URLs, IP addresses, and broken URLs.
    @Test(arguments: zip(
        [
            "https://bitwarden.com",
            "192.168.0.1:8080",
            "ht tp://broken.com",
        ],
        [
            "https://bitwarden.com",
            "http://192.168.0.1:8080",
            "https://ht tp://broken.com",
<<<<<<< HEAD
        ],
=======
        ]
>>>>>>> main
    ))
    func fixURLIfNeeded(input: String, expected: String) {
        #expect(input.fixURLIfNeeded() == expected)
    }

    // MARK: Tests - removingMarkdownForVoiceOver

    /// `removingMarkdownForVoiceOver()` strips markdown syntax while preserving readable text.
    @Test(arguments: zip(
        [
            "Your charge is **$19.80**, due on **May 1**.",
            "__Bold text__",
            "This is *important*.",
            "This is _important_.",
            "~~Old price~~ New price.",
            "Visit [Bitwarden](https://bitwarden.com) now.",
            "**Bold text**",
            "No markdown here.",
        ],
        [
            "Your charge is $19.80, due on May 1.",
            "Bold text",
            "This is important.",
            "This is important.",
            "Old price New price.",
            "Visit Bitwarden now.",
            "Bold text",
            "No markdown here.",
<<<<<<< HEAD
        ],
=======
        ]
>>>>>>> main
    ))
    func removingMarkdownForVoiceOver(input: String, expected: String) {
        #expect(input.removingMarkdownForVoiceOver() == expected)
    }
}
