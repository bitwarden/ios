import BitwardenKit
import UIKit

/// A mock implementation of `RootNavigator` used for testing purposes.
///
/// This class provides a test double for the `RootNavigator` protocol, allowing unit tests
/// to verify navigation behavior without performing actual UI operations. It captures
/// navigation calls and stores them in accessible properties for test assertions.
///
/// ## Usage
/// ```swift
/// let mockNavigator = MockRootNavigator()
/// // Perform operations that use the navigator
/// // Assert on the captured state
/// XCTAssertEqual(mockNavigator.alerts.count, 1)
/// ```
public final class MockRootNavigator: RootNavigator {
    /// A collection of alerts that have been presented through this mock navigator.
    ///
    /// This array captures all alerts passed to the `present(_:)` and `present(_:onDismissed:)`
    /// methods, allowing tests to verify that the correct alerts were shown.
    public var alerts: [Alert] = []

    /// The current app theme being used by the navigator.
    ///
    /// Defaults to `.default` and can be modified to test theme-related behavior.
    public var appTheme: AppTheme = .default

    /// The most recently shown child navigator, if any.
    ///
    /// This property captures the navigator passed to the `show(child:)` method,
    /// allowing tests to verify that the correct child navigator was presented.
    public var navigatorShown: Navigator?

    /// The root view controller being managed by this navigator.
    ///
    /// This property can be set to provide a mock root view controller for testing scenarios
    /// that require one, or left as `nil` if not needed for the test.
    public var rootViewController: UIViewController?

    /// Creates a new mock root navigator instance.
    ///
    /// The mock navigator is initialized with default values and empty collections,
    /// ready to capture navigation operations during testing.
    public init() {}

    /// Presents an alert by adding it to the `alerts` collection.
    ///
    /// This method captures the alert for testing purposes instead of actually
    /// presenting it to the user. The alert can be retrieved from the `alerts`
    /// property for verification in tests.
    ///
    /// - Parameter alert: The alert to present.
    public func present(_ alert: Alert) {
        alerts.append(alert)
    }

    /// Presents an alert with a dismissal callback by adding it to the `alerts` collection.
    ///
    /// This method captures the alert for testing purposes instead of actually
    /// presenting it to the user. The dismissal callback is ignored in this mock
    /// implementation, but the alert can be retrieved from the `alerts` property
    /// for verification in tests.
    ///
    /// - Parameters:
    ///   - alert: The alert to present.
    ///   - onDismissed: A closure to execute when the alert is dismissed. This is ignored in the mock.
    public func present(_ alert: Alert, onDismissed: (() -> Void)?) {
        alerts.append(alert)
    }

    /// Presents a view controller (mock implementation).
    ///
    /// This method provides a no-op implementation for testing purposes. In a real
    /// implementation, this would present the view controller, but the mock ignores
    /// all parameters and performs no actual presentation.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present. Ignored in this mock.
    ///   - animated: Whether the presentation should be animated. Ignored in this mock.
    ///   - overFullscreen: Whether to present over fullscreen. Ignored in this mock.
    ///   - onCompletion: A closure to execute when presentation completes. Ignored in this mock.
    public func present(
        _ viewController: UIViewController,
        animated: Bool,
        overFullscreen: Bool,
        onCompletion: (() -> Void)?,
    ) {}

    /// Shows a child navigator by storing it in the `navigatorShown` property.
    ///
    /// This method captures the child navigator for testing purposes instead of
    /// actually presenting it. The navigator can be retrieved from the `navigatorShown`
    /// property for verification in tests.
    ///
    /// - Parameter child: The child navigator to show.
    public func show(child: Navigator) {
        navigatorShown = child
    }
}
