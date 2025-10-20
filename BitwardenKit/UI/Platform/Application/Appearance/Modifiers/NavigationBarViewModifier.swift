import SwiftUI

// MARK: - NavigationBarViewModifier

/// A modifier that customizes a navigation bar's title and title display mode.
///
public struct NavigationBarViewModifier: ViewModifier {
    // MARK: Properties

    /// The navigation bar title.
    var title: String

    /// The navigation bar title display mode.
    var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode

    // MARK: Initializer

    /// Initializes a `NavigationBarViewModifier`.
    ///
    /// - Parameters:
    ///   - title: The navigation bar title.
    ///   - navigationBarTitleDisplayMode: The display mode of the navigation bar.
    ///
    public init(title: String, navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode) {
        self.title = title
        self.navigationBarTitleDisplayMode = navigationBarTitleDisplayMode
    }

    // MARK: View

    public func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(navigationBarTitleDisplayMode)
            .navigationTitle(title)
    }
}
