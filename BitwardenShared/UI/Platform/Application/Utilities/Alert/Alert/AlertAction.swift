import UIKit

// MARK: - AlertAction

/// An action that can be added to an `Alert`. This is modeled after `UIAlertAction`
/// and allows the handler to be invoked from tests.
///
public class AlertAction {
    // MARK: Properties

    /// An optional handler that is called when the user taps on the action from the alert.
    let handler: ((AlertAction) -> Void)?

    /// The style of the action.
    let style: UIAlertAction.Style

    /// The title of the alert action to display in the alert.
    let title: String?

    // MARK: Initialization

    /// Initializes an `AlertAction` with a title, style and optional handler.
    ///
    /// - Parameters:
    ///   - title: The title of the alert action.
    ///   - style: The style of the alert action to use when creating a `UIAlertAction`.
    ///   - handler: The handler that is called when the user taps on the action in the alert.
    ///
    public init(
        title: String?,
        style: UIAlertAction.Style,
        handler: ((AlertAction) -> Void)? = nil
    ) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

extension AlertAction: Equatable {
    public static func == (lhs: AlertAction, rhs: AlertAction) -> Bool {
        guard lhs.style == rhs.style, lhs.title == rhs.title else { return false }
        switch (lhs.handler, rhs.handler) {
        case (.none, .none),
             (.some, .some):
            return true
        case (_, .some),
             (.some, _):
            return false
        }
    }
}
