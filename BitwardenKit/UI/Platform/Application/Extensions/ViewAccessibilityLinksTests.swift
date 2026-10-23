import Foundation
import Testing

@testable import BitwardenKit

// MARK: - ViewAccessibilityLinksTests

struct ViewAccessibilityLinksTests {
    // MARK: Tests

    /// `links(in:)` returns an empty array if the markdown doesn't contain any links.
    @Test(arguments: ["", "Plain text with **bold** content"])
    func links_none(markdown: String) {
        #expect(AccessibilityLink.links(in: markdown).isEmpty)
    }

    /// `links(in:)` returns the link contained in the markdown.
    @Test
    func links_single() {
        let links = AccessibilityLink.links(
            in: "For details, visit the [Bitwarden Help Center](https://bitwarden.com/help).",
        )

        #expect(links == [
            AccessibilityLink(label: "Bitwarden Help Center", url: URL(string: "https://bitwarden.com/help")!),
        ])
    }

    /// `links(in:)` returns each of the links contained in the markdown, in order.
    @Test
    func links_multiple() {
        let links = AccessibilityLink.links(
            in: "By continuing, you agree to the [Terms of Service](https://bitwarden.com/terms) " +
                "and [Privacy Policy](https://bitwarden.com/privacy)",
        )

        #expect(links == [
            AccessibilityLink(label: "Terms of Service", url: URL(string: "https://bitwarden.com/terms")!),
            AccessibilityLink(label: "Privacy Policy", url: URL(string: "https://bitwarden.com/privacy")!),
        ])
    }

    /// `links(in:)` returns a link that contains nested formatting as a single link.
    @Test
    func links_nestedFormatting() {
        let links = AccessibilityLink.links(in: "[Learn **more**](https://bitwarden.com)")

        #expect(links == [
            AccessibilityLink(label: "Learn more", url: URL(string: "https://bitwarden.com")!),
        ])
    }
}
