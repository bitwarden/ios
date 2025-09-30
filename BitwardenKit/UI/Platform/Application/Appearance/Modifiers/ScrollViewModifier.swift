import BitwardenResources
import SwiftUI

// MARK: - ScrollViewModifier

/// A modifier that adds padded content to a `ScrollView`.
///
struct ScrollViewModifier: ViewModifier {
    // MARK: Properties

    /// Whether or not to add the vertical padding.
    var addVerticalPadding = true

    /// The background color to apply to the scroll view.
    var backgroundColor: Color

    /// Whether the content should be vertically centered in the scroll view, if the content height
    /// is less than the scroll view's height.
    var centerContentVertically = false

    /// The amount of padding to apply around the content.
    var padding: CGFloat

    /// Whether or not to show the scrolling indicators .
    var showsIndicators = true

    // MARK: View

    func body(content: Content) -> some View {
        if centerContentVertically {
            GeometryReader { reader in
                scrollView(content: content, minHeight: reader.size.height)
            }
        } else {
            scrollView(content: content)
        }
    }

    // MARK: Private

    private func scrollView(content: Content, minHeight: CGFloat? = nil) -> some View {
        ScrollView(showsIndicators: showsIndicators) {
            content
                .padding(.horizontal, padding)
                .padding([.top, .bottom], addVerticalPadding ? padding : 0)
                .frame(maxWidth: .infinity, minHeight: minHeight)
        }
        .background(backgroundColor)
    }
}

// MARK: - View + ScrollViewModifier

extension View {
    /// Applies the `ScrollViewModifier` to a view.
    ///
    /// - Parameters:
    ///   - addVerticalPadding: Whether or not to add vertical padding. Defaults to `true`.
    ///   - centerContentVertically: Whether the content should be vertically centered in the scroll
    ///     view, if the content height is less than the scroll view's height.
    ///   - backgroundColor: The background color to apply to the scroll view. Defaults to `backgroundPrimary`.
    ///   - padding: The amount of padding to apply around the content.
    ///   - showsIndicators: Whether or not the scroll indicators are shown.
    ///
    /// - Returns: A view within a `ScrollView`.
    ///
    func scrollView(
        addVerticalPadding: Bool = true,
        backgroundColor: Color = SharedAsset.Colors.backgroundPrimary.swiftUIColor,
        centerContentVertically: Bool = false,
        padding: CGFloat = 12,
        showsIndicators: Bool = true
    ) -> some View {
        modifier(ScrollViewModifier(
            addVerticalPadding: addVerticalPadding,
            backgroundColor: backgroundColor,
            centerContentVertically: centerContentVertically,
            padding: padding,
            showsIndicators: showsIndicators
        ))
    }
}
