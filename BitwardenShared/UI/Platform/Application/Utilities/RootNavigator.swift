import UIKit

// MARK: - RootNavigator

/// A navigator that displays a single child navigator.
///
@MainActor
public protocol RootNavigator: Navigator {
    /// The app's theme.
    var appTheme: AppTheme { get set }

    /// Shows the specified child navigator.
    ///
    /// - Parameter child: The navigator to show.
    func show(child: Navigator)
}

// MARK: - RootViewController

extension RootViewController: RootNavigator {
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        appTheme.statusBarStyle
    }

    public var rootViewController: UIViewController? {
        self
    }

    public func show(child: Navigator) {
        childViewController = child.rootViewController
    }
}
