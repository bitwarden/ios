import BitwardenSdk
import UIKit

// MARK: - Alert+Vault

extension Alert {
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
            ]
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
            ]
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
            ]
        )
    }

    /// An alert presenting the user with options to select a file.
    ///
    /// - Parameter handler: A block that is executed when one of the selections is made.
    ///
    static func fileSelectionOptions(
        handler: @MainActor @escaping (FileSelectionRoute) -> Void
    ) -> Alert {
        Alert(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: [
                AlertAction(
                    title: Localizations.photos,
                    style: .default,
                    handler: { _ in await handler(.photo) }
                ),
                AlertAction(
                    title: Localizations.camera,
                    style: .default,
                    handler: { _ in await handler(.camera) }
                ),
                AlertAction(
                    title: Localizations.browse,
                    style: .default,
                    handler: { _ in await handler(.file) }
                ),
                AlertAction(
                    title: Localizations.cancel,
                    style: .cancel
                ),
            ]
        )
    }

    /// An alert presenting the user with more options for a vault list item.
    ///
    /// - Parameters:
    ///   - cipherView: The cipher view to show.
    ///   - id: The id of the item.
    ///   - showEdit: Whether to show the edit option (should be `false` for items in the trash).
    ///   - action: The action to perform after selecting an option.
    ///
    /// - Returns: An alert presenting the user with options to select an attachment type.
    @MainActor
    static func moreOptions( // swiftlint:disable:this function_body_length
        cipherView: CipherView,
        id: String,
        showEdit: Bool,
        action: @escaping (_ action: MoreOptionsAction) async -> Void
    ) -> Alert {
        // All the cipher types have the option to view the cipher.
        var alertActions = [
            AlertAction(title: Localizations.view, style: .default) { _, _ in await action(.view(id: id)) },
        ]

        // Add the option to edit the cipher if desired.
        if showEdit {
            alertActions.append(AlertAction(title: Localizations.edit, style: .default) { _, _ in
                await action(.edit(cipherView: cipherView))
            })
        }

        // Add any additional actions for the type of cipher selected.
        switch cipherView.type {
        case .card:
            if let number = cipherView.card?.number {
                alertActions.append(AlertAction(title: Localizations.copyNumber, style: .default) { _, _ in
                    await action(.copy(
                        toast: Localizations.number,
                        value: number,
                        requiresMasterPasswordReprompt: cipherView.reprompt == .password
                    ))
                })
            }
            if let code = cipherView.card?.code {
                alertActions.append(AlertAction(title: Localizations.copySecurityCode, style: .default) { _, _ in
                    await action(.copy(
                        toast: Localizations.securityCode,
                        value: code,
                        requiresMasterPasswordReprompt: cipherView.reprompt == .password
                    ))
                })
            }
        case .login:
            if let username = cipherView.login?.username {
                alertActions.append(AlertAction(title: Localizations.copyUsername, style: .default) { _, _ in
                    await action(.copy(
                        toast: Localizations.username,
                        value: username,
                        requiresMasterPasswordReprompt: false
                    ))
                })
            }
            if let password = cipherView.login?.password,
               cipherView.viewPassword {
                alertActions.append(AlertAction(title: Localizations.copyPassword, style: .default) { _, _ in
                    await action(.copy(
                        toast: Localizations.password,
                        value: password,
                        requiresMasterPasswordReprompt: cipherView.reprompt == .password
                    ))
                })
            }
            if let totp = cipherView.login?.totp, let totpKey = TOTPKeyModel(authenticatorKey: totp) {
                alertActions.append(AlertAction(title: Localizations.copyTotp, style: .default) { _, _ in
                    await action(.copyTotp(
                        totpKey: totpKey,
                        requiresMasterPasswordReprompt: cipherView.reprompt == .password
                    ))
                })
            }
            if let uri = cipherView.login?.uris?.first?.uri,
               let url = URL(string: uri) {
                alertActions
                    .append(AlertAction(title: Localizations.launch, style: .default) { _, _ in
                        await action(.launch(url: url))
                    })
            }
        case .identity:
            // No-op: no extra options beyond view and edit.
            break
        case .secureNote:
            if let notes = cipherView.notes {
                alertActions.append(AlertAction(title: Localizations.copyNotes, style: .default) { _, _ in
                    await action(.copy(
                        toast: Localizations.notes,
                        value: notes,
                        requiresMasterPasswordReprompt: false
                    ))
                })
            }
        }

        // Return the alert.
        return Alert(
            title: cipherView.name,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: alertActions + [AlertAction(title: Localizations.cancel, style: .cancel)]
        )
    }

    /// An alert that informs the user about password autofill.
    ///
    /// - Returns: An alert that informs the user about password autofill.
    ///
    static func passwordAutofillInformation() -> Alert {
        Alert.defaultAlert(
            title: Localizations.passwordAutofill,
            message: Localizations.bitwardenAutofillAlert2
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
            ]
        )
    }
}
