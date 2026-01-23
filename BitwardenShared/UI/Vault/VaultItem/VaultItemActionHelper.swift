import BitwardenKit
import BitwardenResources
import BitwardenSdk
import Foundation

/// A protocol for a helper to centralize and execute vault item actions.
protocol VaultItemActionHelper { // sourcery: AutoMockable
    /// Archives a cipher.
    ///
    /// - Parameters:
    ///   - cipher: The cipher to archive.
    ///   - handleOpenURL: A closure to open a link.
    ///   - completionHandler: The closure to execute when completing the archive process.
    func archive(
        cipher: CipherView,
        handleOpenURL: @escaping (URL) -> Void,
        completionHandler: @escaping () -> Void,
    ) async

    /// Unarchives a cipher.
    ///
    /// - Parameters:
    ///   - cipher: The cipher to archive
    ///   - completionHandler: The closure to execute when completing the unarchive process
    func unarchive(
        cipher: CipherView,
        completionHandler: @escaping () -> Void,
    ) async
}

/// The default implementation of `VaultItemActionHelper`.
class DefaultVaultItemActionHelper: VaultItemActionHelper {
    // MARK: Types

    typealias Services = HasEnvironmentService
        & HasErrorReporter
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>

    /// The services used by this helper.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `DefaultVaultItemActionHelper`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this helper.
    ///
    init(
        coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>,
        services: Services,
    ) {
        self.coordinator = coordinator
        self.services = services
    }

    // MARK: Methods

    func archive(
        cipher: CipherView,
        handleOpenURL: @escaping (URL) -> Void,
        completionHandler: @escaping () -> Void,
    ) async {
        guard await services.vaultRepository.doesActiveAccountHavePremium() else {
            await coordinator.showAlert(
                Alert.archiveUnavailable(action: { [weak self] in
                    guard let self else { return }
                    handleOpenURL(services.environmentService.upgradeToPremiumURL)
                }),
            )
            return
        }

        let alert = Alert.confirmation(title: Localizations.doYouReallyWantToArchiveThisItem) { [weak self] in
            guard let self else { return }

            await performOperation(
                loadingTitle: Localizations.sendingToArchive,
                operation: {
                    try await self.services.vaultRepository.archiveCipher(cipher)
                },
                completionHandler: completionHandler,
            )
        }
        await coordinator.showAlert(alert)
    }

    func unarchive(
        cipher: CipherView,
        completionHandler: @escaping () -> Void,
    ) async {
        let alert = Alert.confirmation(title: Localizations.doYouReallyWantToUnarchiveThisItem) { [weak self] in
            guard let self else { return }

            await performOperation(
                loadingTitle: Localizations.unarchiving,
                operation: {
                    try await self.services.vaultRepository.unarchiveCipher(cipher)
                },
                completionHandler: completionHandler,
            )
        }
        await coordinator.showAlert(alert)
    }

    // MARK: Private methods

    /// Performs an operation and dismisses the view with an action.
    /// - Parameters:
    ///   - loadingTitle: The title of the loading overlay.
    ///   - operation: The operation to execute.
    ///   - onSucceed: The action to execute when operation succeeds.
    @MainActor
    private func performOperation(
        loadingTitle: String,
        operation: () async throws -> Void,
        completionHandler: @escaping () -> Void,
    ) async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            coordinator.showLoadingOverlay(.init(title: loadingTitle))

            try await operation()

            completionHandler()
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }
}
