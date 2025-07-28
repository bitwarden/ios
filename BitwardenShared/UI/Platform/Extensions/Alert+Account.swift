import BitwardenResources

// MARK: - Alert+Account

extension Alert {
    /// An alert notifying the user that their account has been permanently deleted.
    ///
    /// - Returns: An alert notifying the user that their account has been permanently deleted.
    ///
    static func accountDeletedAlert() -> Alert {
        Alert(
            title: Localizations.yourAccountHasBeenPermanentlyDeleted,
            message: nil,
            alertActions: [AlertAction(title: Localizations.ok, style: .default)]
        )
    }

    /// An alert notifying the user that a pending login request has been answered.
    ///
    /// - Parameter action: The action to perform when the user exits the alert.
    ///
    /// - Returns: An alert notifying the user that a pending login request has been answered.
    ///
    static func requestAnswered(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.thisRequestIsNoLongerValid,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default) { _, _ in await action() },
            ]
        )
    }

    /// An alert notifying the user that a pending login request has expired.
    ///
    /// - Parameter action: The action to perform when the user exits the alert.
    ///
    /// - Returns: An alert notifying the user that a pending login request has expired.
    ///
    static func requestExpired(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.loginRequestHasAlreadyExpired,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default) { _, _ in await action() },
            ]
        )
    }
}
