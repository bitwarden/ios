import BitwardenResources
import BitwardenSdk
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

    /// The helper to handle master password reprompts.
    private let masterPasswordRepromptHelper: MasterPasswordRepromptHelper

    /// The services used by this helper.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `VaultItemMoreOptionsHelper`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - masterPasswordRepromptHelper: The helper to handle master password reprompts.
    ///   - services: The services used by this helper.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
        masterPasswordRepromptHelper: MasterPasswordRepromptHelper,
        services: Services
    ) {
        self.coordinator = coordinator
        self.masterPasswordRepromptHelper = masterPasswordRepromptHelper
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
            guard case let .cipher(cipherListView, _) = item.itemType,
                  let cipherId = cipherListView.id,
                  let cipherView = try await services.vaultRepository.fetchCipher(withId: cipherId) else {
                return
            }

            let canEdit = cipherView.deletedDate == nil
            let hasPremium = await services.vaultRepository.doesActiveAccountHavePremium()

            coordinator.showAlert(.moreOptions(
                canCopyTotp: hasPremium || cipherView.organizationUseTotp,
                cipherView: cipherView,
                id: item.id,
                showEdit: canEdit
            ) { action in
                await self.handleMoreOptionsAction(
                    action,
                    cipherView: cipherView,
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
                Toast(title: Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp))
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
        cipherView: CipherView,
        handleDisplayToast: @escaping (Toast) -> Void,
        handleOpenURL: (URL) -> Void
    ) async {
        switch action {
        case let .copy(toast, value, requiresMasterPasswordReprompt, event, cipherId):
            let copyBlock = {
                self.services.pasteboardService.copy(value)
                handleDisplayToast(Toast(title: Localizations.valueHasBeenCopied(toast)))
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
                await masterPasswordRepromptHelper.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
                    copyBlock()
                }
            } else {
                copyBlock()
            }
        case let .copyTotp(totpKey):
            await masterPasswordRepromptHelper.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
                await self.generateAndCopyTotpCode(totpKey: totpKey, handleDisplayToast: handleDisplayToast)
            }
        case let .edit(cipherView):
            await masterPasswordRepromptHelper.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
                self.coordinator.navigate(to: .editItem(cipherView), context: self)
            }
        case let .launch(url):
            handleOpenURL(url.sanitized)
        case let .view(id):
            await masterPasswordRepromptHelper.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
                self.coordinator.navigate(to: .viewItem(id: id, masterPasswordRepromptCheckCompleted: true))
            }
        }
    }
}
