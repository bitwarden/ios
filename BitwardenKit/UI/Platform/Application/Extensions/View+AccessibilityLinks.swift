import SwiftUI

// MARK: - AccessibilityLink

/// A link parsed from a markdown string that should be exposed as an accessibility action.
///
struct AccessibilityLink: Equatable {
    // MARK: Properties

    /// The text displayed for the link, used as the name of the accessibility action.
    let label: String

    /// The URL to open when the link is activated.
    let url: URL

    // MARK: Static Methods

    /// Parses the inline links from a markdown string.
    ///
    /// - Parameter markdown: The markdown string containing zero or more inline links.
    /// - Returns: The links contained in the markdown string, in the order they appear.
    ///
    static func links(in markdown: String) -> [AccessibilityLink] {
        guard let attributedString = try? AttributedString(
            markdown: markdown,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
            ),
        ) else { return [] }

        // Slicing the runs by only the link attribute ensures that a link containing nested
        // formatting is returned as a single link.
        return attributedString.runs[\.link].compactMap { url, range in
            guard let url else { return nil }
            return AccessibilityLink(label: String(attributedString[range].characters), url: url)
        }
    }
}

// MARK: - AccessibilityLinksModifier

/// A modifier that exposes the inline links in a markdown string as accessibility actions, so
/// that they can be activated with Full Keyboard Access and VoiceOver.
///
struct AccessibilityLinksModifier: ViewModifier {
    // MARK: Properties

    /// Whether a single link should be exposed as the element's default action with the link
    /// trait. If `false`, all links are exposed as named actions, preserving the element's
    /// existing default action.
    let isDefaultActionEnabled: Bool

    /// The links to expose as accessibility actions.
    let links: [AccessibilityLink]

    /// The action used to open URLs.
    @Environment(\.openURL) private var openURL

    // MARK: View

    func body(content: Content) -> some View {
        if links.isEmpty {
            content
        } else if isDefaultActionEnabled, links.count == 1, let link = links.first {
            content
                .accessibilityAddTraits(.isLink)
                .accessibilityAction {
                    openURL(link.url)
                }
        } else {
            let baseView = content.accessibilityAddTraits(isDefaultActionEnabled ? .isLink : [])
            links.reduce(baseView) { view, link in
                view.accessibilityAction(named: Text(link.label)) {
                    openURL(link.url)
                }
            }
        }
    }
}

// MARK: - View

public extension View {
    /// Exposes the inline links in a markdown string as accessibility actions. SwiftUI renders
    /// markdown links in a `Text` as tappable, but doesn't expose them to Full Keyboard Access.
    ///
    /// If the markdown contains a single link, activating the element opens the link. Otherwise,
    /// each link is exposed as a named accessibility action.
    ///
    /// - Parameters:
    ///   - markdown: The markdown string displayed by the view, containing zero or more links.
    ///   - isDefaultActionEnabled: Whether a single link should become the element's default
    ///     action. Pass `false` for views with their own default action (e.g. a toggle), so that
    ///     the links are only added as named actions.
    /// - Returns: A view with the links exposed as accessibility actions.
    ///
    func accessibilityLinks(in markdown: String, isDefaultActionEnabled: Bool = true) -> some View {
        modifier(AccessibilityLinksModifier(
            isDefaultActionEnabled: isDefaultActionEnabled,
            links: AccessibilityLink.links(in: markdown),
        ))
    }
}
