// MARK: - Alert + Settings

extension Alert {
    // MARK: Methods

    /// Confirm deleting the folder.
    ///
    /// - Parameter action: The action to perform if the user selects yes.
    ///
    /// - Returns: An alert to confirm deleting the folder.
    ///
    static func confirmDeleteFolder(action: @MainActor @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.doYouReallyWantToDelete,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },
                AlertAction(title: Localizations.no, style: .cancel),
            ]
        )
    }

    /// Confirm that the user wants to export their items.
    ///
    /// - Parameters:
    ///   - action: The action performed when they select export items.
    /// - Returns: An alert confirming that the user wants to export their items unencrypted.
    ///
    static func confirmExportItems(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.exportItemsConfirmationTitle,
            message: Localizations.exportItemsWarning,
            alertActions: [
                AlertAction(title: Localizations.exportItems, style: .default) { _ in await action() },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ]
        )
    }

    /// Show the alert notifying the user that the language has been changed.
    ///
    /// - Parameters:
    ///   - newLanguage: The title of the new language.
    ///   - action: The action to run after the user clicks ok.
    /// - Returns: An alert confirming the language change.
    ///
    @MainActor
    static func languageChanged(to newLanguage: String, action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.languageChangeXDescription(newLanguage),
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default) { _ in
                    action()
                },
            ]
        )
    }

    /// An alert that asks if the user wants to navigate to the privacy policy in a browser.
    ///
    /// - Parameter action: The action taken if they select continue.
    /// - Returns: An alert that asks if the user wants to navigate to the app store to leave a review.
    ///
    static func privacyPolicyAlert(action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.continueToPrivacyPolicy,
            message: Localizations.privacyPolicyDescriptionLong,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    action()
                },
            ]
        )
    }
}
