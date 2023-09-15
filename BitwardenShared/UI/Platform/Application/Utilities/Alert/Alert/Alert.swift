import UIKit

// MARK: - Alert

/// A helper class that can create a `UIAlertController`.
/// This allows for easier testing of alert controllers and actions.
///
public class Alert {
    // MARK: Properties

    /// A list of actions that the user can tap on in the alert.
    var alertActions: [AlertAction] = []

    /// The message that is displayed in the alert.
    let message: String?

    /// The preferred action for the user to take in the alert, which emphasis is given.
    var preferredAction: AlertAction?

    /// The alert's style.
    let preferredStyle: UIAlertController.Style

    /// The title of the message that is displayed at the top of the alert.
    let title: String?

    // MARK: Initialization

    /// Initializes an `Alert`.
    ///
    /// - Parameters:
    ///   - title: The title of the message that is displayed at the top of the alert.
    ///   - message: The message that is displayed in the alert.
    ///   - preferredStyle: The alert's style.
    ///   - alertActions: A list of actions that the user can tap on in the alert.
    ///
    public init(
        title: String?,
        message: String?,
        preferredStyle: UIAlertController.Style = .alert,
        alertActions: [AlertAction] = []
    ) {
        self.title = title
        self.message = message
        self.preferredStyle = preferredStyle
        self.alertActions = alertActions
    }

    // MARK: Methods

    /// Adds an `AlertAction` to the `Alert`.
    ///
    /// - Parameter action: The `AlertAction` to add to the `Alert`.
    ///
    /// - Returns `self` to allow `add(_:)` methods to be chained.
    ///
    func add(_ action: AlertAction) -> Self {
        alertActions.append(action)
        return self
    }

    /// Adds a preferred `AlertAction` to the `Alert`. The preferred action is the action that the
    /// user should take and is given emphasis. This replaces an existing preferred action, if one
    /// exists.
    ///
    /// - Parameter action: The preferred `AlertAction` to add to the `Alert`.
    ///
    /// - Returns `self` to allow `add(_:)` methods to be chained.
    ///
    func addPreferred(_ action: AlertAction) -> Self {
        alertActions.append(action)
        preferredAction = action
        return self
    }

    /// Creates a `UIAlertController` from the `Alert` that can be presented in the view.
    ///
    /// - Returns An initialized `UIAlertController` that has the `AlertAction`s added.
    ///
    @MainActor
    func createAlertController() -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)

        alertActions.forEach { alertAction in
            let action = UIAlertAction(title: alertAction.title, style: alertAction.style) { _ in
                alertAction.handler?(alertAction)
            }

            alert.addAction(action)

            if let preferredAction, preferredAction === alertAction {
                alert.preferredAction = action
            }
        }

        return alert
    }
}

extension Alert: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        Alert(title: \(title ?? "nil"), message: \(message ?? "nil"), alertActions: \(alertActions))
        """
    }
}

extension Alert: Equatable {
    public static func == (lhs: Alert, rhs: Alert) -> Bool {
        lhs.alertActions == rhs.alertActions
            && lhs.message == rhs.message
            && lhs.preferredAction == rhs.preferredAction
            && lhs.preferredStyle == rhs.preferredStyle
            && lhs.title == rhs.title
    }
}
