import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - MigrateToMyItemsProcessorDelegate

/// A delegate for the `MigrateToMyItemsProcessor` to communicate events back to the coordinator.
///
@MainActor
protocol MigrateToMyItemsProcessorDelegate: AnyObject {
    /// Called when the user has left the organization.
    ///
    func didLeaveOrganization()
}

// MARK: - MigrateToMyItemsProcessor

/// The processor used to manage state and handle actions for the migrate to my items screen.
///
final class MigrateToMyItemsProcessor: StateProcessor<
    MigrateToMyItemsState,
    MigrateToMyItemsAction,
    MigrateToMyItemsEffect,
> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasVaultRepository

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>

    /// The delegate to notify of events.
    private weak var delegate: MigrateToMyItemsProcessorDelegate?

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `MigrateToMyItemsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate to notify of events.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>,
        delegate: MigrateToMyItemsProcessorDelegate?,
        services: Services,
        state: MigrateToMyItemsState,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: MigrateToMyItemsEffect) async {
        switch effect {
        case .acceptTransferTapped:
            await acceptTransfer()
        case .appeared:
            await loadOrganizationName()
        case .leaveOrganizationTapped:
            await leaveOrganization()
        }
    }

    override func receive(_ action: MigrateToMyItemsAction) {
        switch action {
        case .backTapped:
            state.page = .transfer
        case .declineAndLeaveTapped:
            state.page = .declineConfirmation
        }
    }

    // MARK: Private Methods

    /// Accepts the item transfer.
    ///
    private func acceptTransfer() async {
        coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.loading))

        do {
            try await services.vaultRepository.migratePersonalVault(to: state.organizationId)
            coordinator.hideLoadingOverlay()
            coordinator.navigate(to: .dismiss())
        } catch {
            coordinator.hideLoadingOverlay()
            await coordinator.showErrorAlert(error: error, onDismissed: {
                self.coordinator.navigate(to: .dismiss())
            })
            services.errorReporter.log(error: error)
        }
    }

    /// Leaves the organization after declining the item transfer.
    ///
    private func leaveOrganization() async {
        coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.loading))

        // TODO: PM-29710 Implement leave organization API call

        defer { coordinator.hideLoadingOverlay() }
        delegate?.didLeaveOrganization()
    }

    /// Loads the organization name from the vault repository using the organization ID.
    ///
    private func loadOrganizationName() async {
        do {
            let organization = try await services.vaultRepository.fetchOrganization(withId: state.organizationId)

            guard let organizationName = organization?.name else {
                coordinator.showAlert(.defaultAlert(title: Localizations.organizationNotFound)) {
                    self.coordinator.navigate(to: .dismiss())
                }
                return
            }
            state.organizationName = organizationName
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }
}
