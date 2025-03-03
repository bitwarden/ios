import Foundation

// MARK: - Alert+Error

extension Alert {
    // MARK: Methods

    /// The default alert style with a standard ok button to dismiss.
    ///
    /// - Parameters:
    ///   - title: The alert's title.
    ///   - message: The alert's message.
    ///
    /// - Returns a default styled alert.
    ///
    static func defaultAlert(
        title: String? = nil,
        message: String? = nil,
        alertActions: [AlertAction]? = nil
    ) -> Alert {
        Alert(
            title: title,
            message: message,
            alertActions: alertActions ?? [AlertAction(title: Localizations.ok, style: .cancel)]
        )
    }

    /// Creates an alert for an `InputValidationError`.
    ///
    /// - Parameter error: The error to create the alert for.
    /// - Returns: An alert that can be displayed to the user for an `InputValidationError`.
    ///
    static func inputValidationAlert(error: InputValidationError) -> Alert {
        Alert(
            title: Localizations.anErrorHasOccurred,
            message: error.message,
            alertActions: [AlertAction(title: Localizations.ok, style: .default)]
        )
    }
}
