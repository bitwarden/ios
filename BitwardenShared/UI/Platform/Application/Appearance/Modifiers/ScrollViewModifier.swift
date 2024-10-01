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

    // MARK: View

    func body(content: Content) -> some View {
        ScrollView {
            content
                .padding(.horizontal, 16)
                .padding([.top, .bottom], addVerticalPadding ? 16 : 0)
        }
        .background(backgroundColor)
    }
}
