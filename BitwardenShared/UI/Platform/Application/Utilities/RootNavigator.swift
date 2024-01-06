import UIKit

// MARK: - RootNavigator

/// A navigator that displays a single child navigator.
///
@MainActor
public protocol RootNavigator: Navigator {
    /// The app's theme.
    var theme: ThemeOption { get set }

    /// Shows the specified child navigator.
    ///
    /// - Parameter child: The navigator to show.
    func show(child: Navigator)

    /// Update the app's theme.
    ///
    /// - Parameter themeOption: The new app theme to use.
    ///
    func updateTheme(to themeOption: ThemeOption)
}

public extension RootNavigator {
    /// Update the app's theme.
    ///
    /// - Parameter themeOption: The new app theme to use.
    ///
    func updateTheme(to themeOption: ThemeOption) {
        theme = themeOption
        rootViewController?.overrideUserInterfaceStyle = themeOption.userInterfaceStyle
        rootViewController?.setNeedsStatusBarAppearanceUpdate()
    }
}

// MARK: - RootViewController

extension RootViewController: RootNavigator {
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }

    public var rootViewController: UIViewController? {
        self
    }

    public func show(child: Navigator) {
        childViewController = child.rootViewController
    }
}
