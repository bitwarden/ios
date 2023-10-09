// MARK: - Alert

extension Alert {
    /// An invalid email error alert.
    ///
    static var invalidEmail: Alert {
        Alert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.invalidEmail,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        )
    }
}
