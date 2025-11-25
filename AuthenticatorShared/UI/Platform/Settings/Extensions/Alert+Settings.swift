import BitwardenKit
import BitwardenResources

// MARK: - Alert + Settings

extension Alert {
    // MARK: Methods

    /// Provide information about data backup.
    ///
    /// - Parameters:
    ///   - action: The action to perform if the user selects Learn More.
    /// - Returns: An alert for providing backup information.
    ///
    static func backupInformation(action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.bitwardenAuthenticatorDataIsBackedUpAndCanBeRestored,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.learnMore, style: .default) { _ in
                    action()
                },
                AlertAction(title: Localizations.ok, style: .default),
            ],
        )
    }

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
            ],
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
            ],
        )
    }

    /// An alert notifying the user that their import file was corrupted or not valid JSON.
    ///
    /// - Parameter action: The action taken if they select continue.
    /// - Returns: An alert indicating their import file was corrupted or not valid JSON
    ///
    @MainActor
    static func importFileCorrupted(action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.fileCouldNotBeProcessed,
            message: [
                Localizations.ensureItsValidJsonAndTryAgain,
                Localizations.needHelpVisitOurHelpCenterForGuidance,
            ].joined(separator: "\n\n"),
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    action()
                },
            ],
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
            ],
        )
    }

    /// An alert notifying the user their import file was missing some required information.
    ///
    /// - Parameter action: The action taken if they select continue.
    /// - Returns: An alert indicating their import file was missing some required information.
    ///
    @MainActor
    static func requiredInfoMissing(keyPath: String, action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.requiredInformationMissing,
            message: [
                Localizations.requiredInformationIsMissing(keyPath),
                Localizations.needHelpVisitOurHelpCenterForGuidance,
            ].joined(separator: "\n\n"),
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    action()
                },
            ],
        )
    }

    /// An alert notifying the user that we do not currently support password-protected
    /// files when importing from 2FAS.
    ///
    /// - Returns: An alert indicating we don't support password-protected 2FAS files
    @MainActor
    static func twoFasPasswordProtected() -> Alert {
        Alert(
            title: Localizations.importingFromTwoFasPasswordProtectedNotSupported,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ],
        )
    }

    /// An alert notifying the user that there was a type mismatch in their import file
    ///
    /// - Parameter action: The action taken if they select continue.
    /// - Returns: An alert indicating there was a type mismatch in their import file
    ///
    @MainActor
    static func typeMismatch(action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.unexpectedDataFormat,
            message: [
                Localizations.theDataFormatProvidedDoesntMatchWhatsExpected,
                Localizations.needHelpVisitOurHelpCenterForGuidance,
            ].joined(separator: "\n\n"),
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    action()
                },
            ],
        )
    }
}
