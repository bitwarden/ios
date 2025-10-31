import UIKit

// MARK: - Alert

/// A helper class that can create a `UIAlertController`.
/// This allows for easier testing of alert controllers and actions.
///
public class Alert {
    // MARK: Properties

    /// A list of actions that the user can tap on in the alert.
    public var alertActions: [AlertAction] = []

    /// A list of text fields that the user can use to enter text.
    public var alertTextFields: [AlertTextField] = []

    /// The message that is displayed in the alert.
    public let message: String?

    /// The preferred action for the user to take in the alert, which emphasis is given.
    public var preferredAction: AlertAction?

    /// The alert's style.
    public let preferredStyle: UIAlertController.Style

    /// The title of the message that is displayed at the top of the alert.
    public let title: String?

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
        alertTextFields: [AlertTextField] = [],
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
    public func add(_ action: AlertAction) -> Self {
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
    public func add(_ textField: AlertTextField) -> Self {
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
    public func addPreferred(_ action: AlertAction) -> Self {
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
    public func createAlertController(onDismissed: (() -> Void)? = nil) -> UIAlertController {
        let alertController = AlertController(title: title, message: message, preferredStyle: preferredStyle)
        alertController.onDismissed = onDismissed

        let shouldUpdateActions = alertActions.contains { $0.shouldEnableAction != nil }

        addTextFields(to: alertController, updateActionsIfNeeded: shouldUpdateActions)
        addActions(to: alertController)

        return alertController
    }

    private func addTextFields(to alertController: UIAlertController, updateActionsIfNeeded: Bool) {
        for alertTextField in alertTextFields {
            alertController.addTextField { textField in
                self.configure(textField, with: alertTextField)

                textField.addTarget(
                    alertTextField,
                    action: #selector(AlertTextField.textChanged(in:)),
                    for: .editingChanged,
                )
            }

            if updateActionsIfNeeded {
                alertTextField.onTextChanged = { [weak self, weak alertController] in
                    guard let self, let alertController else { return }

                    for (index, alertAction) in alertActions.enumerated() {
                        guard let shouldEnable = alertAction.shouldEnableAction else { continue }
                        if index < alertController.actions.count {
                            alertController.actions[index].isEnabled = shouldEnable(alertTextFields)
                        }
                    }
                }
            }
        }
    }

    private func addActions(to alertController: UIAlertController) {
        for alertAction in alertActions {
            let action = UIAlertAction(title: alertAction.title, style: alertAction.style) { _ in
                Task {
                    await alertAction.handler?(alertAction, self.alertTextFields)
                }
            }

            action.isEnabled = alertAction.shouldEnableAction?(alertTextFields) ?? true
            alertController.addAction(action)

            if let preferredAction, preferredAction === alertAction {
                alertController.preferredAction = action
            }
        }
    }

    private func configure(_ textField: UITextField, with model: AlertTextField) {
        textField.placeholder = model.placeholder
        textField.keyboardType = model.keyboardType
        textField.isSecureTextEntry = model.isSecureTextEntry
        textField.autocapitalizationType = model.autocapitalizationType
        textField.autocorrectionType = model.autocorrectionType
        textField.text = model.text
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
