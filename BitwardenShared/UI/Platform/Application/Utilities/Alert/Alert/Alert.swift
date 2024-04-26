import UIKit

// MARK: - Alert

/// A helper class that can create a `UIAlertController`.
/// This allows for easier testing of alert controllers and actions.
///
public class Alert {
    // MARK: Properties

    /// A list of actions that the user can tap on in the alert.
    var alertActions: [AlertAction] = []

    /// A list of text fields that the user can use to enter text.
    var alertTextFields: [AlertTextField] = []

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
    ///   - alertTextFields: A list of text fields that the user can enter text into.
    ///
    public init(
        title: String?,
        message: String?,
        preferredStyle: UIAlertController.Style = .alert,
        alertActions: [AlertAction] = [],
        alertTextFields: [AlertTextField] = []
    ) {
        self.title = title
        self.message = message
        self.preferredStyle = preferredStyle
        self.alertActions = alertActions
        self.alertTextFields = alertTextFields
    }

    // MARK: Methods

    /// Adds an `AlertAction` to the `Alert`.
    ///
    /// - Parameter action: The `AlertAction` to add to the `Alert`.
    ///
    /// - Returns: `self` to allow `add(_:)` methods to be chained.
    ///
    @discardableResult
    func add(_ action: AlertAction) -> Self {
        alertActions.append(action)
        return self
    }

    /// Adds an `AlertTextField` to the `Alert`.
    ///
    /// - Parameter textField: The `AlertTextField` to add to the `Alert`.
    ///
    /// - Returns: `self` to allow `add(_:)` methods to be chained.
    ///
    @discardableResult
    func add(_ textField: AlertTextField) -> Self {
        alertTextFields.append(textField)
        return self
    }

    /// Adds a preferred `AlertAction` to the `Alert`. The preferred action is the action that the
    /// user should take and is given emphasis. This replaces an existing preferred action, if one
    /// exists.
    ///
    /// - Parameter action: The preferred `AlertAction` to add to the `Alert`.
    ///
    /// - Returns: `self` to allow `add(_:)` methods to be chained.
    ///
    @discardableResult
    func addPreferred(_ action: AlertAction) -> Self {
        alertActions.append(action)
        preferredAction = action
        return self
    }

    /// Creates a `UIAlertController` from the `Alert` that can be presented in the view.
    ///
    /// - Parameter onDismissed: An optional closure that is called when the alert is dismissed.
    /// - Returns An initialized `UIAlertController` that has the `AlertAction`s added.
    ///
    @MainActor
    func createAlertController(onDismissed: (() -> Void)? = nil) -> UIAlertController {
        let alert = AlertController(title: title, message: message, preferredStyle: preferredStyle)
        alert.onDismissed = onDismissed
        alertTextFields.forEach { alertTextField in
            alert.addTextField { textField in
                textField.placeholder = alertTextField.placeholder
                textField.tintColor = Asset.Colors.primaryBitwarden.color
                textField.keyboardType = alertTextField.keyboardType
                textField.isSecureTextEntry = alertTextField.isSecureTextEntry
                textField.autocapitalizationType = alertTextField.autocapitalizationType
                textField.autocorrectionType = alertTextField.autocorrectionType
                textField.text = alertTextField.text
                textField.addTarget(
                    alertTextField,
                    action: #selector(AlertTextField.textChanged(in:)),
                    for: .editingChanged
                )
            }
        }

        alertActions.forEach { alertAction in
            let action = UIAlertAction(title: alertAction.title, style: alertAction.style) { _ in
                Task {
                    await alertAction.handler?(alertAction, self.alertTextFields)
                }
            }

            alert.addAction(action)

            if let preferredAction, preferredAction === alertAction {
                alert.preferredAction = action
            }
        }
        alert.view.tintColor = Asset.Colors.primaryBitwarden.color

        return alert
    }
}

// swiftlint:disable line_length

extension Alert: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        Alert(title: \(title ?? "nil"), message: \(message ?? "nil"), alertActions: \(alertActions), alertTextFields: \(alertTextFields))
        """
    }
}

// swiftlint:enable line_length

extension Alert: Equatable {
    public static func == (lhs: Alert, rhs: Alert) -> Bool {
        lhs.alertActions == rhs.alertActions
            && lhs.message == rhs.message
            && lhs.preferredAction == rhs.preferredAction
            && lhs.preferredStyle == rhs.preferredStyle
            && lhs.title == rhs.title
    }
}

extension Alert: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(alertActions)
        hasher.combine(message)
        hasher.combine(preferredAction)
        hasher.combine(preferredStyle)
        hasher.combine(title)
    }
}

// MARK: - AlertController

/// An `UIAlertController` subclass that allows for setting a closure to be notified when the alert
/// controller is dismissed.
///
private class AlertController: UIAlertController {
    // MARK: Properties

    /// A closure that is called when the alert controller has been dismissed.
    var onDismissed: (() -> Void)?

    // MARK: UIViewController

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismissed?()
    }
}
