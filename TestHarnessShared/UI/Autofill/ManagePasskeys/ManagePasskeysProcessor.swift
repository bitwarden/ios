import BitwardenKit
import Combine

// MARK: - ManagePasskeysProcessor

/// The processor for the manage passkeys screen.
///
class ManagePasskeysProcessor: StateProcessor<
    ManagePasskeysState,
    ManagePasskeysAction,
    ManagePasskeysEffect,
> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    /// The service used to read and delete passkey registry entries.
    private let passkeyRegistryService: PasskeyRegistryService

    // MARK: Initialization

    /// Initializes a `ManagePasskeysProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - passkeyRegistryService: The service that manages the passkey registry.
    ///
    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        passkeyRegistryService: PasskeyRegistryService,
    ) {
        self.coordinator = coordinator
        self.passkeyRegistryService = passkeyRegistryService
        super.init(state: ManagePasskeysState())
    }

    // MARK: Methods

    override func perform(_ effect: ManagePasskeysEffect) async {
        switch effect {
        case .clearAll:
            await passkeyRegistryService.clearAll()
            state.passkeys = []
        case let .deletePasskey(entry):
            await passkeyRegistryService.deletePasskey(entry)
            state.passkeys = await passkeyRegistryService.loadPasskeys()
        case .loadPasskeys:
            state.passkeys = await passkeyRegistryService.loadPasskeys()
        }
    }
}
