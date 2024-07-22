import Foundation

// MARK: - VaultItemMoreOptionsHelper

/// A protocol for a helper object to handle displaying the more options menu for a vault item and
/// responding to the user's selection.
///
protocol VaultItemMoreOptionsHelper {
    /// Show the more options alert for the selected item.
    ///
    /// - Parameters
    ///   - item: The selected item to show the options for.
    ///   - handleDisplayToast: A closure called to handle displaying a toast.
    ///   - handleOpenURL: A closure called to open a URL.
    ///
    func showMoreOptionsAlert(
        for item: VaultListItem,
        handleDisplayToast: @escaping (Toast) -> Void,
        handleOpenURL: @escaping (URL) -> Void
    ) async
}

// MARK: - DefaultVaultItemMoreOptionsHelper

/// A default implementation of `VaultItemMoreOptionsHelper`.
///
@MainActor
class DefaultVaultItemMoreOptionsHelper: VaultItemMoreOptionsHelper {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter
        & HasEventService
        & HasPasteboardService
        & HasStateService
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultRoute, AuthAction>

    /// The services used by this helper.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `VaultItemMoreOptionsHelper`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this helper.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
        services: Services
    ) {
        self.coordinator = coordinator
        self.services = services
    }

    // MARK: Methods

    func showMoreOptionsAlert(
        for item: VaultListItem,
        handleDisplayToast: @escaping (Toast) -> Void,
        handleOpenURL: @escaping (URL) -> Void
    ) async {
        do {
            // Only ciphers have more options.
            guard case let .cipher(cipherView, _) = item.itemType else { return }

            let hasPremium = try await services.vaultRepository.doesActiveAccountHavePremium()
            let hasMasterPassword = try await services.stateService.getUserHasMasterPassword()

            coordinator.showAlert(.moreOptions(
                canCopyTotp: hasPremium || cipherView.organizationUseTotp,
                cipherView: cipherView,
                hasMasterPassword: hasMasterPassword,
                id: item.id,
                showEdit: true
            ) { action in
                await self.handleMoreOptionsAction(
                    action,
                    handleDisplayToast: handleDisplayToast,
                    handleOpenURL: handleOpenURL
                )
            })
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    // MARK: Private Methods

    /// Generates and copies a TOTP code for the cipher's TOTP key.
    ///
    /// - Parameter totpKey: The TOTP key used to generate a TOTP code.
    ///
    private func generateAndCopyTotpCode(
        totpKey: TOTPKeyModel,
        handleDisplayToast: @escaping (Toast) -> Void
    ) async {
        do {
            let response = try await services.vaultRepository.refreshTOTPCode(for: totpKey)
            guard let code = response.codeModel?.code else {
                throw TOTPServiceError.unableToGenerateCode(nil)
            }
            services.pasteboardService.copy(code)
            handleDisplayToast(
                Toast(text: Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp))
            )
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Handle the result of the selected option on the More Options alert..
    ///
    /// - Parameter action: The selected action.
    ///
    private func handleMoreOptionsAction(
        _ action: MoreOptionsAction,
        handleDisplayToast: @escaping (Toast) -> Void,
        handleOpenURL: (URL) -> Void
    ) async {
        switch action {
        case let .copy(toast, value, requiresMasterPasswordReprompt, event, cipherId):
            let copyBlock = {
                self.services.pasteboardService.copy(value)
                handleDisplayToast(Toast(text: Localizations.valueHasBeenCopied(toast)))
                if let event {
                    Task {
                        await self.services.eventService.collect(
                            eventType: event,
                            cipherId: cipherId
                        )
                    }
                }
            }
            if requiresMasterPasswordReprompt {
                presentMasterPasswordRepromptAlert(completion: copyBlock)
            } else {
                copyBlock()
            }
        case let .copyTotp(totpKey, requiresMasterPasswordReprompt):
            if requiresMasterPasswordReprompt {
                presentMasterPasswordRepromptAlert {
                    await self.generateAndCopyTotpCode(totpKey: totpKey, handleDisplayToast: handleDisplayToast)
                }
            } else {
                await generateAndCopyTotpCode(totpKey: totpKey, handleDisplayToast: handleDisplayToast)
            }
        case let .edit(cipherView, requiresMasterPasswordReprompt):
            if requiresMasterPasswordReprompt {
                presentMasterPasswordRepromptAlert {
                    self.coordinator.navigate(to: .editItem(cipherView), context: self)
                }
            } else {
                coordinator.navigate(to: .editItem(cipherView), context: self)
            }
        case let .launch(url):
            handleOpenURL(url.sanitized)
        case let .view(id):
            coordinator.navigate(to: .viewItem(id: id))
        }
    }

    /// Presents the master password reprompt alert and calls the completion handler when the user's
    /// master password has been confirmed.
    ///
    /// - Parameter completion: A completion handler that is called when the user's master password
    ///     has been confirmed.
    ///
    private func presentMasterPasswordRepromptAlert(completion: @escaping () async -> Void) {
        let alert = Alert.masterPasswordPrompt { password in
            do {
                let isValid = try await self.services.authRepository.validatePassword(password)
                guard isValid else {
                    self.coordinator.showAlert(.defaultAlert(title: Localizations.invalidMasterPassword))
                    return
                }
                await completion()
            } catch {
                self.coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
                self.services.errorReporter.log(error: error)
            }
        }
        coordinator.showAlert(alert)
    }
}
