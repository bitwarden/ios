import SwiftUI

// MARK: - NavigationBarViewModifier

/// A modifier that customizes a navigation bar's title and title display mode.
///
struct NavigationBarViewModifier: ViewModifier {
    // MARK: Properties

    /// The navigation bar title.
    var title: String

    /// The navigation bar title display mode.
    var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode

    // MARK: View

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(navigationBarTitleDisplayMode)
            .navigationTitle(title)
    }
}
