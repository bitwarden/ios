import BitwardenKit
import BitwardenResources
import BitwardenSdk
import UIKit

// swiftlint:disable file_length

// MARK: - Alert+Vault

extension Alert {
    /// Returns an alert for when archive is unavailable.
    ///
    /// - Parameters:
    ///   - action: A closure to execute on upgrading to Premium.
    /// - Returns: The alert when archive is unavailable.
    static func archiveUnavailable(
        action: @escaping () async -> Void,
    ) -> Alert {
        let preferredAction = AlertAction(title: Localizations.upgradeToPremium, style: .default) { _ in
            await action()
        }
        let alert = Alert(
            title: Localizations.premiumSubscriptionRequired,
            message: Localizations.archivingItemsIsAPremiumFeatureDescriptionLong,
            alertActions: [
                preferredAction,
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
        )
        alert.preferredAction = preferredAction
        return alert
    }

    /// Returns an alert for when attachments are unavailable.
    ///
    /// - Parameters:
    ///   - action: A closure to execute on upgrading to Premium.
    /// - Returns: The alert when attachments are unavailable.
    static func attachmentsUnavailable(
        action: @escaping () async -> Void,
    ) -> Alert {
        let preferredAction = AlertAction(title: Localizations.upgradeToPremium, style: .default) { _ in
            await action()
        }
        let alert = Alert(
            title: Localizations.premiumSubscriptionRequired,
            message: Localizations.addingAttachmentsIsAPremiumFeatureDescriptionLong,
            alertActions: [
                preferredAction,
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
        )
        alert.preferredAction = preferredAction
        return alert
    }

    /// Returns an alert notifying the user that one or more items in their vault were unable to be
    /// decrypted.
    ///
    /// - Parameters:
    ///   - cipherIds: The identifiers of any ciphers that were unable to be decrypted.
    ///   - isFromCipherTap: Whether the alert is being shown in response to a user tapping on a
    ///     cipher which failed to decrypt or a general alert that is displayed when the vault loads.
    ///   - copyAction: A closure that is called in response to tapping the copy button.
    /// - Returns: An alert notifying the user that one or more items in their vault were unable to
    ///     be decrypted.
    ///
    static func cipherDecryptionFailure(
        cipherIds: [String],
        isFromCipherTap: Bool = true,
        copyAction: @escaping (String) -> Void,
    ) -> Alert {
        let message = if isFromCipherTap {
            Localizations.bitwardenCouldNotDecryptThisVaultItemDescriptionLong
        } else {
            Localizations.bitwardenCouldNotDecryptXVaultItemsDescriptionLong(cipherIds.count)
        }

        return Alert(
            title: Localizations.decryptionError,
            message: message,
            alertActions: [
                AlertAction(title: Localizations.copyErrorReport, style: .default, handler: { _ in
                    let stringToCopy = Localizations.decryptionError
                        + "\n" + message
                        + "\n\n" + cipherIds.joined(separator: "\n")
                    copyAction(stringToCopy)
                }),
                AlertAction(title: Localizations.close, style: .cancel),
            ],
        )
    }

    /// Returns an alert asking the user to confirm archiving a vault item.
    ///
    /// - Parameters:
    ///   - action: A closure to execute when the user confirms archiving.
    /// - Returns: An alert confirming the archive action.
    ///
    static func confirmArchiveItem(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.archiveItem,
            message: Localizations.onceArchivedThisItemWillBeExcludedDescriptionLong,
            alertActions: [
                AlertAction(title: Localizations.archive, style: .default) { _, _ in await action() },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
        )
    }

    /// Returns an alert confirming cancelling the Credential Exchange export process.
    /// - Parameter action: The action to perform if the user confirms.
    /// - Returns: An alert confirming cancelling the Credential Exchange export process.
    static func confirmCancelCXFExport(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.cancel,
            message: Localizations.areYouSureYouWantToCancelTheExportProcessQuestionMark,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _, _ in await action() },
                AlertAction(title: Localizations.no, style: .cancel),
            ],
        )
    }

    /// Returns an alert confirming cancelling the Credential Exchange import process.
    /// - Parameter action: The action to perform if the user confirms.
    /// - Returns: An alert confirming cancelling the Credential Exchange import process.
    static func confirmCancelCXFImport(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.cancel,
            message: Localizations.areYouSureYouWantToCancelTheImportProcessQuestionMark,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _, _ in await action() },
                AlertAction(title: Localizations.no, style: .cancel),
            ],
        )
    }

    /// Returns an alert confirming whether to clone an item without the FIDO2 credential.
    ///
    /// - Parameter action: The action to perform if the user confirms.
    /// - Returns: An alert confirming whether to clone an item without the FIDO2 credential.
    ///
    static func confirmCloneExcludesFido2Credential(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.passkeyWillNotBeCopied,
            message: Localizations.thePasskeyWillNotBeCopiedToTheClonedItemDoYouWantToContinueCloningThisItem,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _, _ in await action() },
                AlertAction(title: Localizations.no, style: .cancel),
            ],
        )
    }

    /// Present an alert confirming deleting an attachment.
    ///
    /// - Parameter action: The action to perform if the user confirms.
    ///
    /// - Returns: An alert confirming deleting an attachment.
    ///
    static func confirmDeleteAttachment(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.doYouReallyWantToDelete,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _, _ in await action() },
                AlertAction(title: Localizations.no, style: .cancel),
            ],
        )
    }

    /// Present an alert confirming downloading a large attachment.
    ///
    /// - Parameters:
    ///   - fileSize: The size of the attachment to download.
    ///   - action: The action to perform if the user confirms.
    ///
    /// - Returns: An alert confirming downloading a large attachment.
    ///
    static func confirmDownload(fileSize: String, action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.attachmentLargeWarning(fileSize),
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _, _ in await action() },
                AlertAction(title: Localizations.no, style: .cancel),
            ],
        )
    }

    /// An alert presenting the user with options to select a file.
    ///
    /// - Parameter handler: A block that is executed when one of the selections is made.
    ///
    static func fileSelectionOptions(
        handler: @MainActor @escaping (FileSelectionRoute) -> Void,
    ) -> Alert {
        Alert(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: [
                AlertAction(
                    title: Localizations.photos,
                    style: .default,
                    handler: { _ in await handler(.photo) },
                ),
                AlertAction(
                    title: Localizations.camera,
                    style: .default,
                    handler: { _ in await handler(.camera) },
                ),
                AlertAction(
                    title: Localizations.browse,
                    style: .default,
                    handler: { _ in await handler(.file) },
                ),
                AlertAction(
                    title: Localizations.cancel,
                    style: .cancel,
                ),
            ],
        )
    }

    /// Returns an alert notifying the user that a Premium subscription is required to send files,
    /// with an option to upgrade.
    ///
    /// - Parameters:
    ///   - action: A closure to execute on upgrading to Premium.
    /// - Returns: The alert shown when a non-Premium user tries to send a file.
    static func fileSendPremiumRequired(
        action: @escaping () -> Void,
    ) -> Alert {
        let preferredAction = AlertAction(title: Localizations.upgradeToPremium, style: .default) { _, _ in action() }
        let alert = Alert(
            title: Localizations.premiumSubscriptionRequired,
            message: Localizations.sendFilePremiumRequired,
            alertActions: [
                preferredAction,
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
        )
        alert.preferredAction = preferredAction
        return alert
    }

    /// An alert asking the user if they have a computer available to import logins.
    ///
    /// - Parameter action: The action taken when the user taps on continue.
    /// - Returns: An alert asking the user if they have a computer available to import logins.
    ///
    static func importLoginsComputerAvailable(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.doYouHaveAComputerAvailable,
            message: Localizations.doYouHaveAComputerAvailableDescriptionLong,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    await action()
                },
            ],
        )
    }

    /// An alert informing the user that no logins were imported.
    ///
    /// - Parameter action: The action taken when the user taps import logins later.
    /// - Returns: An alert informing the user that no logins were imported.
    ///
    static func importLoginsEmpty(
        action: @escaping () async -> Void,
    ) -> Alert {
        Alert(
            title: Localizations.importError,
            message: Localizations.noLoginsWereImported,
            alertActions: [
                AlertAction(title: Localizations.tryAgain, style: .cancel),
                AlertAction(title: Localizations.importLoginsLater, style: .default) { _ in
                    await action()
                },
            ],
        )
    }

    /// An alert confirming that the user wants to import logins later in settings.
    ///
    /// - Parameter action: The action taken when the user taps on Confirm to import logins later
    ///     in settings.
    /// - Returns: An alert confirming that the user wants to import logins later in settings.
    ///
    static func importLoginsLater(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.importLoginsLaterQuestion,
            message: Localizations.youCanReturnToCompleteThisStepAnytimeInVaultUnderSettings,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.confirm, style: .default) { _ in
                    await action()
                },
            ],
        )
    }

    /// An alert presenting the user with more options for a vault list item.
    ///
    /// - Parameters:
    ///   - context: The context for the alert, including which options are applicable to the
    ///     cipher (see `CipherListView.applicableMoreOptionsActionKinds(hasPremium:)`).
    ///   - action: The action to perform after selecting an option.
    ///
    /// - Returns: An alert presenting the user with options to select an attachment type.
    @MainActor
    static func moreOptions(
        context: MoreOptionsAlertContext,
        action: @escaping (_ action: MoreOptionsAction) async -> Void,
    ) -> Alert {
        let alertActions = context.actionKinds.compactMap { kind -> AlertAction? in
            guard let moreOptionsAction = kind.moreOptionsAction(
                cipherView: context.cipherView,
                itemId: context.id,
            ) else {
                return nil
            }
            return AlertAction(title: kind.localizedName, style: .default) { _, _ in
                await action(moreOptionsAction)
            }
        }

        return Alert(
            title: context.cipherView.name,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: alertActions + [AlertAction(title: Localizations.cancel, style: .cancel)],
        )
    }

    /// An alert that informs the user about password autofill.
    ///
    /// - Returns: An alert that informs the user about password autofill.
    ///
    static func passwordAutofillInformation() -> Alert {
        Alert.defaultAlert(
            title: Localizations.passwordAutofill,
            message: Localizations.bitwardenAutofillAlert2,
        )
    }

    /// An alert that informs the user about receiving push notifications.
    ///
    /// - Parameter action: The action to perform when the user clicks through.
    /// - Returns: An alert that informs the user about receiving push notifications.
    ///
    static func pushNotificationsInformation(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.enableAutomaticSyncing,
            message: Localizations.pushNotificationAlert,
            alertActions: [
                AlertAction(title: Localizations.okGotIt, style: .default) { _, _ in await action() },
            ],
        )
    }

    /// Returns an alert notifying the user that an enterprise policy restricts them to a single
    /// Send type, and that the current action can't be completed.
    ///
    /// - Parameters:
    ///   - allowedType: The Send type permitted by policy.
    ///   - action: A closure to execute when the user acknowledges the alert.
    /// - Returns: The alert shown when a Send of the disallowed type would otherwise be created.
    static func sendTypeRestrictedByPolicy(
        _ allowedType: SendType,
        action: @escaping () -> Void,
    ) -> Alert {
        Alert(
            title: nil,
            message: Localizations.dueToAnEnterprisePolicyYouCanOnlyCreateXSends(allowedType.localizedName),
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default) { _, _ in action() },
            ],
        )
    }

    /// Returns an alert for when the "Specific People" Send feature is unavailable due to
    /// lack of Premium subscription.
    ///
    /// - Parameters:
    ///   - action: A closure to execute on upgrading to Premium.
    /// - Returns: The alert when "Specific People" is unavailable.
    static func specificPeopleUnavailable(
        action: @escaping () -> Void,
    ) -> Alert {
        let preferredAction = AlertAction(title: Localizations.upgradeToPremium, style: .default) { _, _ in action() }
        let alert = Alert(
            title: Localizations.premiumSubscriptionRequired,
            message: Localizations.sharingWithSpecificPeopleIsPremiumFeatureDescriptionLong,
            alertActions: [
                preferredAction,
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
        )
        alert.preferredAction = preferredAction
        return alert
    }

    /// An alert shown when a vault sync fails.
    ///
    /// - Parameters:
    ///   - message: The message to display — a server-supplied message when one is available,
    ///     otherwise the generic sync failure copy.
    ///   - tryAgainHandler: A closure called when the user taps "Try again".
    /// - Returns: An `Alert` with "Not now" and "Try again" actions.
    static func syncUnsuccessful(
        message: String,
        tryAgainHandler: @escaping () async -> Void,
    ) -> Alert {
        Alert(
            title: Localizations.syncUnsuccessful,
            message: message,
            alertActions: [
                AlertAction(
                    title: Localizations.notNow,
                    style: .cancel,
                ),
                AlertAction(
                    title: Localizations.tryAgain,
                    style: .default,
                    handler: { _, _ in
                        await tryAgainHandler()
                    },
                ),
            ],
        )
    }

    /// Returns an alert notifying the user that a Premium subscription is required to view TOTP
    /// codes, with an option to upgrade.
    ///
    /// - Parameters:
    ///   - action: A closure to execute on upgrading to Premium.
    /// - Returns: The alert shown when a non-Premium user taps the TOTP premium required field.
    static func totpPremiumRequired(
        action: @escaping () async -> Void,
    ) -> Alert {
        let preferredAction = AlertAction(title: Localizations.upgradeToPremium, style: .default) { _ in
            await action()
        }
        let alert = Alert(
            title: Localizations.premiumSubscriptionRequired,
            message: Localizations.premiumRequiredTOTPDescriptionLong,
            alertActions: [
                preferredAction,
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
        )
        alert.preferredAction = preferredAction
        return alert
    }

    /// An alert notifying the user to update their encryption settings.
    ///
    /// - Parameter completion: A closure that's executed when the user has entered their password.
    /// - Returns: An alert that prompts the user to enter their master password to update their
    ///     encryption settings.
    ///
    static func updateEncryptionSettings(
        completion: @MainActor @escaping (String) async -> Void,
    ) -> Alert {
        Alert(
            title: Localizations.updateYourEncryptionSettings,
            message: Localizations.theNewRecommendedEncryptionSettingsDescriptionLong,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(
                    title: Localizations.submit,
                    style: .default,
                ) { _, alertTextFields in
                    guard let password = alertTextFields.first(where: { $0.id == "password" })?.text else { return }
                    await completion(password)
                },
            ],
            alertTextFields: [
                AlertTextField(
                    id: "password",
                    autocapitalizationType: .none,
                    autocorrectionType: .no,
                    isSecureTextEntry: true,
                    keyboardType: .default,
                ),
            ],
        )
    }
}
