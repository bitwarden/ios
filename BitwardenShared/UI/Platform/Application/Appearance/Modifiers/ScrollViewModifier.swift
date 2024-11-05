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

    /// Whether or not to show the scrolling indicators .
    var showsIndicators = true

    // MARK: View

    func body(content: Content) -> some View {
        ScrollView(showsIndicators: showsIndicators) {
            content
                .padding(.horizontal, 16)
                .padding([.top, .bottom], addVerticalPadding ? 16 : 0)
        }
        .background(backgroundColor)
    }
}
