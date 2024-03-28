import UIKit

// MARK: - RootNavigator

/// A navigator that displays a single child navigator.
///
@MainActor
public protocol RootNavigator: Navigator {
    /// Shows the specified child navigator.
    ///
    /// - Parameter child: The navigator to show.
    func show(child: Navigator?)
}
