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

    /// The amount of padding to apply around the content.
    var padding: CGFloat

    /// Whether or not to show the scrolling indicators .
    var showsIndicators = true

    // MARK: View

    func body(content: Content) -> some View {
        ScrollView(showsIndicators: showsIndicators) {
            content
                .padding(.horizontal, padding)
                .padding([.top, .bottom], addVerticalPadding ? padding : 0)
        }
        .background(backgroundColor)
    }
}
