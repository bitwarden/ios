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
        & HasPolicyService
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

        // TODO: PM-29709 Implement accept transfer API call

        defer { coordinator.hideLoadingOverlay() }
        coordinator.navigate(to: .dismiss())
    }

    /// Leaves the organization after declining the item transfer.
    ///
    private func leaveOrganization() async {
        coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.loading))

        // TODO: PM-29710 Implement leave organization API call

        defer { coordinator.hideLoadingOverlay() }
        delegate?.didLeaveOrganization()
    }

    /// Loads the organization name from the policy service and vault repository.
    ///
    private func loadOrganizationName() async {
        do {
            let organizationIds = await services.policyService.organizationsApplyingPolicyToUser(.personalOwnership)
            guard let organizationId = organizationIds.first else { return }

            let organization = try await services.vaultRepository.fetchOrganization(withId: organizationId)
            state.organizationName = organization?.name ?? "Test Org"
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}
