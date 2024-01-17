import BitwardenSdk
import Combine
import Foundation

// MARK: - SendRepository

/// A protocol for a `SendRepository` which manages access to the data needed by the UI layer.
///
protocol SendRepository: AnyObject {
    // MARK: Methods

    /// Adds a new Send to the repository.
    ///
    /// - Parameter sendView: The send to add to the repository.
    ///
    func addSend(_ sendView: SendView) async throws

    /// Validates the user's active account has access to premium features.
    ///
    /// - Returns: Whether the active account has premium.
    ///
    func doesActiveAccountHavePremium() async throws -> Bool

    // MARK: Publishers

    /// Performs an API request to sync the user's send data. The publishers in the repository can
    /// be used to subscribe to the send data, which are updated as a result of the request.
    ///
    /// - Parameter isManualRefresh: Whether the sync is being performed as a manual refresh.
    ///
    func fetchSync(isManualRefresh: Bool) async throws

    // MARK: Publishers

    /// A publisher for all the sends in the user's account.
    ///
    /// - Returns: A publisher for the list of sends in the user's account.
    ///
    func sendListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListSection], Error>>
}

// MARK: - DefaultSendRepository

class DefaultSendRepository: SendRepository {
    // MARK: Properties

    /// The client used by the application to handle vault encryption and decryption tasks.
    let clientVault: ClientVaultService

    /// The service used to manage syncing and updates to the user's organizations.
    let organizationService: OrganizationService

    /// The service used to sync and store sends.
    let sendService: SendService

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The service used to handle syncing send data with the API.
    let syncService: SyncService

    // MARK: Initialization

    /// Initialize a `DefaultSendRepository`.
    ///
    /// - Parameters:
    ///   - clientVault: The client used by the application to handle vault encryption and decryption tasks.
    ///   - organizationService: The service used to manage syncing and updates to the user's organizations.
    ///   - sendService: The service used to sync and store sends.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///
    init(
        clientVault: ClientVaultService,
        organizationService: OrganizationService,
        sendService: SendService,
        stateService: StateService,
        syncService: SyncService
    ) {
        self.clientVault = clientVault
        self.organizationService = organizationService
        self.sendService = sendService
        self.stateService = stateService
        self.syncService = syncService
    }

    // MARK: Methods

    func doesActiveAccountHavePremium() async throws -> Bool {
        let account = try await stateService.getActiveAccount()
        let hasPremiumPersonally = account.profile.hasPremiumPersonally ?? false
        guard !hasPremiumPersonally else {
            return true
        }

        let organizations = try await organizationService
            .fetchAllOrganizations()
            .filter { $0.enabled && $0.usersGetPremium }
        return !organizations.isEmpty
    }

    // MARK: Data Methods

    func addSend(_ sendView: SendView) async throws {
        let send = try await clientVault.sends().encrypt(send: sendView)
        try await sendService.addSend(send)
    }

    // MARK: API Methods

    func fetchSync(isManualRefresh: Bool) async throws {
        let allowSyncOnRefresh = try await stateService.getAllowSyncOnRefresh()
        if !isManualRefresh || allowSyncOnRefresh {
            try await syncService.fetchSync()
        }
    }

    // MARK: Publishers

    func sendListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListSection], Error>> {
        try await sendService.sendsPublisher()
            .asyncTryMap { sends in
                try await self.sendListSections(from: sends)
            }
            .eraseToAnyPublisher()
            .values
    }

    // MARK: Private Methods

    /// Returns a list of the sections in the vault list from a sync response.
    ///
    /// - Parameter sends: The sends used to build the list of sections.
    /// - Returns: A list of the sections to display in the vault list.
    ///
    private func sendListSections(from sends: [Send]) async throws -> [SendListSection] {
        let sends = try await sends
            .asyncMap { try await clientVault.sends().decrypt(send: $0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let fileSendsCount = sends
            .filter { $0.type == .file }
            .count
        let textSendsCount = sends
            .filter { $0.type == .text }
            .count

        let types = [
            SendListItem(id: "Types.Text", itemType: .group(.text, textSendsCount)),
            SendListItem(id: "Types.File", itemType: .group(.file, fileSendsCount)),
        ]

        let allItems = sends.compactMap(SendListItem.init)

        return [
            SendListSection(
                id: "Types",
                isCountDisplayed: false,
                items: types,
                name: Localizations.types
            ),
            SendListSection(
                id: "AllSends",
                isCountDisplayed: true,
                items: allItems,
                name: Localizations.allSends
            ),
        ]
    }
}
