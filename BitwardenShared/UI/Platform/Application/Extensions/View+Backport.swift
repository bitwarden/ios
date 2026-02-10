import SwiftUI

// MARK: - View

/// Extension of `View` to have the `backport` object available to ease
/// with available APIs.
///
/// Adapted from https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/
///
extension View {
    /// Helper to apply backport operations for available APIs.
    var backport: Backport<Self> { Backport(self) }
}

// MARK: - Backport<View>

/// Backport for `View` content.
///
/// Adapted from https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/
///
extension Backport where Content: View {
    /// On iOS 26+, configures the button style to use `glassProminent`.
    ///
    @available(iOS, deprecated: 26.0, message: "Use `buttonStyle(.glassProminent)` instead.")
    func buttonStyleGlassProminent() -> some View {
        if #available(iOS 26, *) {
            return content.buttonStyle(.glassProminent)
        } else {
            return content
        }
    }

    /// On iOS 16+, configures the scroll view to dismiss the keyboard immediately.
    ///
    func dismissKeyboardImmediately() -> some View {
        if #available(iOS 16, *) {
            return content.scrollDismissesKeyboard(.immediately)
        } else {
            return content
        }
    }

    /// On iOS 16+, configures the scroll view to dismiss the keyboard interactively.
    ///
    func dismissKeyboardInteractively() -> some View {
        if #available(iOS 16, *) {
            return content.scrollDismissesKeyboard(.interactively)
        } else {
            return content
        }
    }

    /// On iOS 16+, handles geometry changes.
    ///
    @preconcurrency
    public nonisolated func onGeometryChange<T>(
        for type: T.Type,
        of transform: @escaping @Sendable (GeometryProxy) -> T,
        action: @escaping (_ newValue: T) -> Void,
    ) -> some View where T: Equatable, T: Sendable {
        if #available(iOS 16, *) {
            return content.onGeometryChange(for: type, of: transform, action: action)
        } else {
            return content
        }
    }

    //// Configures the content margin for scroll content of a specific view.
    ///
    /// Use this modifier to customize the content margins of different
    /// kinds of views. For example, you can use this modifier to customize
    /// the scroll content margins of scrollable views like ``ScrollView``. In the
    /// following example, the scroll view will automatically inset
    /// its content by the safe area plus an additional 20 points
    /// on the leading and trailing edge.
    ///
    ///     ScrollView(.horizontal) {
    ///         // ...
    ///     }
    ///     .contentMargins(.horizontal, 20.0)
    ///
    /// - Parameters:
    ///   - edges: The edges to add the margins to.
    ///   - length: The amount of margins to add.
    @ViewBuilder
    func scrollContentMargins(_ edges: Edge.Set = .all, _ length: CGFloat?) -> some View {
        if #available(iOS 17.0, *) {
            content.contentMargins(edges, length, for: .scrollContent)
        } else {
            content
        }
    }
}

// MARK: - Backport<Content>

/// Helper to deal with available APIs and provide backport operations
///
/// Adapted from https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/
///
public struct Backport<Content> {
    /// The content to apply backport operations.
    public let content: Content

    /// Initializes a backport with some content to apply backrpot operations.
    /// - Parameter content: The content to apply backport operations.
    public init(_ content: Content) {
        self.content = content
    }
}
