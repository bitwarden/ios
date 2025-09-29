import BitwardenResources
import BitwardenSdk
import UIKit

// MARK: - Alert+Vault

extension Alert {
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
        copyAction: @escaping (String) -> Void
    ) -> Alert {
        let message = if isFromCipherTap {
            Localizations.bitwardenCouldNotDecryptThisVaultItemDescriptionLong
        } else {
            cipherIds.count == 1
                ? Localizations.bitwardenCouldNotDecryptOneVaultItemDescriptionLong
                : Localizations.bitwardenCouldNotDecryptXVaultItemsDescriptionLong(cipherIds.count)
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
            ]
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
            ]
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
            ]
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
            ]
        )
    }

    /// An alert informing the user that no logins were imported.
    ///
    /// - Parameter action: The action taken when the user taps import logins later.
    /// - Returns: An alert informing the user that no logins were imported.
    ///
    static func importLoginsEmpty(
        action: @escaping () async -> Void
    ) -> Alert {
        Alert(
            title: Localizations.importError,
            message: Localizations.noLoginsWereImported,
            alertActions: [
                AlertAction(title: Localizations.tryAgain, style: .cancel),
                AlertAction(title: Localizations.importLoginsLater, style: .default) { _ in
                    await action()
                },
            ]
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
            ]
        )
    }

    /// An alert presenting the user with more options for a vault list item.
    ///
    /// - Parameters:
    ///   - canCopyTotp: Whether the user can copy the TOTP code (because they have premium or the
    ///     organization uses TOTP).
    ///   - cipherView: The cipher view to show.
    ///   - id: The id of the item.
    ///   - showEdit: Whether to show the edit option (should be `false` for items in the trash).
    ///   - action: The action to perform after selecting an option.
    ///
    /// - Returns: An alert presenting the user with options to select an attachment type.
    @MainActor
    static func moreOptions( // swiftlint:disable:this function_body_length
        canCopyTotp: Bool,
        cipherView: CipherView,
        id: String,
        showEdit: Bool,
        action: @escaping (_ action: MoreOptionsAction) async -> Void
    ) -> Alert {
        // All the cipher types have the option to view the cipher.
        var alertActions = [
            AlertAction(title: Localizations.view, style: .default) { _, _ in
                await action(.view(id: id))
            },
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
                        requiresMasterPasswordReprompt: true,
                        logEvent: nil,
                        cipherId: nil
                    ))
                })
            }
            if let code = cipherView.card?.code {
                alertActions.append(AlertAction(title: Localizations.copySecurityCode, style: .default) { _, _ in
                    await action(.copy(
                        toast: Localizations.securityCode,
                        value: code,
                        requiresMasterPasswordReprompt: true,
                        logEvent: .cipherClientCopiedCardCode,
                        cipherId: cipherView.id
                    ))
                })
            }
        case .login:
            if let username = cipherView.login?.username {
                alertActions.append(AlertAction(title: Localizations.copyUsername, style: .default) { _, _ in
                    await action(.copy(
                        toast: Localizations.username,
                        value: username,
                        requiresMasterPasswordReprompt: false,
                        logEvent: nil,
                        cipherId: nil
                    ))
                })
            }
            if let password = cipherView.login?.password,
               cipherView.viewPassword {
                alertActions.append(AlertAction(title: Localizations.copyPassword, style: .default) { _, _ in
                    await action(.copy(
                        toast: Localizations.password,
                        value: password,
                        requiresMasterPasswordReprompt: true,
                        logEvent: .cipherClientCopiedPassword,
                        cipherId: cipherView.id
                    ))
                })
            }
            if canCopyTotp, let totp = cipherView.login?.totp {
                alertActions.append(AlertAction(title: Localizations.copyTotp, style: .default) { _, _ in
                    await action(.copyTotp(totpKey: TOTPKeyModel(authenticatorKey: totp)))
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
                        requiresMasterPasswordReprompt: true,
                        logEvent: nil,
                        cipherId: nil
                    ))
                })
            }
        case .sshKey:
            if let sshKey = cipherView.sshKey {
                alertActions.append(AlertAction(title: Localizations.copyPublicKey, style: .default) { _, _ in
                    await action(.copy(
                        toast: Localizations.publicKey,
                        value: sshKey.publicKey,
                        requiresMasterPasswordReprompt: true,
                        logEvent: nil,
                        cipherId: cipherView.id
                    ))
                })
                if cipherView.viewPassword {
                    alertActions.append(AlertAction(title: Localizations.copyPrivateKey, style: .default) { _, _ in
                        await action(.copy(
                            toast: Localizations.privateKey,
                            value: sshKey.privateKey,
                            requiresMasterPasswordReprompt: true,
                            logEvent: nil,
                            cipherId: cipherView.id
                        ))
                    })
                }
                alertActions.append(AlertAction(title: Localizations.copyFingerprint, style: .default) { _, _ in
                    await action(.copy(
                        toast: Localizations.fingerprint,
                        value: sshKey.fingerprint,
                        requiresMasterPasswordReprompt: true,
                        logEvent: nil,
                        cipherId: cipherView.id
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
