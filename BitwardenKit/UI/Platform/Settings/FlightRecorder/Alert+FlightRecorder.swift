import BitwardenResources

// MARK: - Alert + Settings

extension Alert {
    // MARK: Methods

    /// Confirm deleting a flight recorder log.
    ///
    /// - Parameters:
    ///   - isBulkDeletion: Whether the user is attempting to delete all logs or just a single log.
    ///   - action: The action to perform if the user selects yes to confirm deletion.
    /// - Returns: An alert to confirm deleting a flight recorder log.
    ///
    static func confirmDeleteLog(isBulkDeletion: Bool, action: @MainActor @escaping () async -> Void) -> Alert {
        Alert(
            title: isBulkDeletion
                ? Localizations.doYouReallyWantToDeleteAllRecordedLogs
                : Localizations.doYouReallyWantToDeleteThisLog,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
        )
    }
}
