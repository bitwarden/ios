import BitwardenKit
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
        handleOpenURL: @escaping (URL) -> Void,
    ) async
}

// MARK: - DefaultVaultItemMoreOptionsHelper

/// A default implementation of `VaultItemMoreOptionsHelper`.
///
@MainActor
class DefaultVaultItemMoreOptionsHelper: VaultItemMoreOptionsHelper {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasConfigService
        & HasEnvironmentService
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
        services: Services,
    ) {
        self.coordinator = coordinator
        self.masterPasswordRepromptHelper = masterPasswordRepromptHelper
        self.services = services
    }

    // MARK: Methods

    func showMoreOptionsAlert(
        for item: VaultListItem,
        handleDisplayToast: @escaping (Toast) -> Void,
        handleOpenURL: @escaping (URL) -> Void,
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

            let isArchiveVaultItemsFFEnabled: Bool = await services.configService.getFeatureFlag(.archiveVaultItems)

            coordinator.showAlert(.moreOptions(
                context: MoreOptionsAlertContext(
                    canArchive: isArchiveVaultItemsFFEnabled && cipherView.canBeArchived,
                    canCopyTotp: hasPremium || cipherView.organizationUseTotp,
                    canUnarchive: isArchiveVaultItemsFFEnabled && cipherView.canBeUnarchived,
                    cipherView: cipherView,
                    id: item.id,
                    showEdit: canEdit,
                ),
            ) { action in
                await self.handleMoreOptionsAction(
                    action,
                    cipherView: cipherView,
                    handleDisplayToast: handleDisplayToast,
                    handleOpenURL: handleOpenURL,
                    hasPremium: hasPremium,
                )
            })
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    // MARK: Private Methods

    /// Archives a cipher.
    ///
    /// - Parameters:
    ///   - cipher: The cipher to archive.
    ///   - handleDisplayToast: A closure to display a toast.
    ///   - handleOpenURL: A closure called to open a URL.
    ///   - hasPremium: Whether the user has premium account.
    private func archive(
        _ cipher: CipherView,
        handleDisplayToast: @escaping (Toast) -> Void,
        handleOpenURL: @escaping (URL) -> Void,
        hasPremium: Bool,
    ) async {
        guard hasPremium else {
            coordinator.showAlert(
                Alert.archiveUnavailable(action: { [weak self] in
                    guard let self else { return }
                    handleOpenURL(services.environmentService.upgradeToPremiumURL)
                }),
            )
            return
        }

        await masterPasswordRepromptHelper.repromptForMasterPasswordIfNeeded(cipherView: cipher) {
            await self.performOperationAndShowToast(
                handleDisplayToast: handleDisplayToast,
                loadingTitle: Localizations.sendingToArchive,
                toastTitle: Localizations.itemMovedToArchive,
            ) {
                try await self.services.vaultRepository.archiveCipher(cipher)
            }
        }
    }

    /// Generates and copies a TOTP code for the cipher's TOTP key.
    ///
    /// - Parameter totpKey: The TOTP key used to generate a TOTP code.
    ///
    private func generateAndCopyTotpCode(
        totpKey: TOTPKeyModel,
        handleDisplayToast: @escaping (Toast) -> Void,
    ) async {
        do {
            let response = try await services.vaultRepository.refreshTOTPCode(for: totpKey)
            guard let code = response.codeModel?.code else {
                throw TOTPServiceError.unableToGenerateCode(nil)
            }
            services.pasteboardService.copy(code)
            handleDisplayToast(
                Toast(title: Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp)),
            )
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Handle the result of the selected option on the More Options alert.
    ///
    /// - Parameters:
    ///   - action: The selected action.
    ///   - cipherView: The cipher to act upon.
    ///   - handleDisplayToast: A closure to display a toast.
    ///   - handleOpenURL: A closure to open an URL.
    ///   - hasPremium: Whether the user has premium account.
    private func handleMoreOptionsAction( // swiftlint:disable:this function_body_length
        _ action: MoreOptionsAction,
        cipherView: CipherView,
        handleDisplayToast: @escaping (Toast) -> Void,
        handleOpenURL: @escaping (URL) -> Void,
        hasPremium: Bool,
    ) async {
        switch action {
        case let .archive(cipher):
            await archive(
                cipher,
                handleDisplayToast: handleDisplayToast,
                handleOpenURL: handleOpenURL,
                hasPremium: hasPremium,
            )
        case let .copy(toast, value, requiresMasterPasswordReprompt, event, cipherId):
            let copyBlock = {
                self.services.pasteboardService.copy(value)
                handleDisplayToast(Toast(title: Localizations.valueHasBeenCopied(toast)))
                if let event {
                    Task {
                        await self.services.eventService.collect(
                            eventType: event,
                            cipherId: cipherId,
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
        case let .unarchive(cipher):
            await masterPasswordRepromptHelper.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
                await self.performOperationAndShowToast(
                    handleDisplayToast: handleDisplayToast,
                    loadingTitle: Localizations.movingItemToVault,
                    toastTitle: Localizations.itemMovedToVault,
                ) {
                    try await self.services.vaultRepository.unarchiveCipher(cipher)
                }
            }
        case let .view(id):
            await masterPasswordRepromptHelper.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
                self.coordinator.navigate(to: .viewItem(id: id, masterPasswordRepromptCheckCompleted: true))
            }
        }
    }

    /// Performs an operation and shows a toast.
    /// - Parameters:
    ///   - loadingTitle: The title of the loading overlay.
    ///   - operation: The operation to execute.
    ///   - toastTitle: The title of the toast.
    private func performOperationAndShowToast(
        handleDisplayToast: @escaping (Toast) -> Void,
        loadingTitle: String,
        toastTitle: String,
        operation: () async throws -> Void,
    ) async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            coordinator.showLoadingOverlay(.init(title: loadingTitle))

            try await operation()

            handleDisplayToast(Toast(title: toastTitle))
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }
}
