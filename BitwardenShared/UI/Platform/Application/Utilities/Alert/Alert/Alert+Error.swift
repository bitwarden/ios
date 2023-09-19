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
        title: String,
        message: String
    ) -> Alert {
        Alert(
            title: title,
            message: message,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .cancel),
            ]
        )
    }
}
