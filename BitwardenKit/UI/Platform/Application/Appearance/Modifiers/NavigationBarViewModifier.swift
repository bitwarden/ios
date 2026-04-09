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

// MARK: View + NavigationBarViewModifier

public extension View {
    /// Applies a custom navigation bar title and title display mode to a view.
    ///
    /// - Parameters:
    ///   - title: The navigation bar title.
    ///   - titleDisplayMode: The navigation bar title display mode.
    ///
    /// - Returns: A view with a custom navigation bar.
    ///
    func navigationBar(
        title: String,
        titleDisplayMode: NavigationBarItem.TitleDisplayMode,
    ) -> some View {
        modifier(NavigationBarViewModifier(
            title: title,
            navigationBarTitleDisplayMode: titleDisplayMode,
        ))
    }
}
