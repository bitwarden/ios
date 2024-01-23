import BitwardenSdk
import Combine
import Foundation

// MARK: - SendRepository

/// A protocol for a `SendRepository` which manages access to the data needed by the UI layer.
///
protocol SendRepository: AnyObject {
    // MARK: Methods

    /// Adds a new file Send to the repository.
    ///
    /// - Parameters:
    ///   - sendView: The send to add to the repository.
    ///   - data: The data representation of the file for this send.
    ///
    func addFileSend(_ sendView: SendView, data: Data) async throws -> SendView

    /// Adds a new text Send to the repository.
    ///
    /// - Parameter sendView: The send to add to the repository.
    ///
    func addTextSend(_ sendView: SendView) async throws -> SendView

    /// Deletes a Send from the repository.
    ///
    /// - Parameter sendView: The send to delete from the repository.
    ///
    func deleteSend(_ sendView: SendView) async throws

    /// Creates the share URL for a given `SendView`, if one can be created.
    ///
    /// - Parameter sendView: The send to create the share url for.
    ///
    func shareURL(for sendView: SendView) async throws -> URL?

    /// Updates an existing Send in the repository.
    ///
    /// - Parameter sendView: The send to update in the repository.
    ///
    func updateSend(_ sendView: SendView) async throws -> SendView

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

    /// A publisher for a user's send objects based on the specified search text.
    ///
    /// - Parameter searchText:  The search text to filter the send list.
    /// - Returns: A publisher for the user's sends.
    ///
    func searchSendPublisher(
        searchText: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListItem], Error>>

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

    /// The service used to retrieve urls for the active account's environment.
    let environmentService: EnvironmentService

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
    ///   - environmentService: The service used to retrieve urls for the active account's environment.
    ///   - organizationService: The service used to manage syncing and updates to the user's organizations.
    ///   - sendService: The service used to sync and store sends.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///
    init(
        clientVault: ClientVaultService,
        environmentService: EnvironmentService,
        organizationService: OrganizationService,
        sendService: SendService,
        stateService: StateService,
        syncService: SyncService
    ) {
        self.clientVault = clientVault
        self.environmentService = environmentService
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

    func addFileSend(_ sendView: SendView, data: Data) async throws -> SendView {
        let send = try await clientVault.sends().encrypt(send: sendView)
        let file = try await clientVault.sends().encryptBuffer(send: send, buffer: data)
        let newSend = try await sendService.addFileSend(send, data: file)
        return try await clientVault.sends().decrypt(send: newSend)
    }

    func addTextSend(_ sendView: SendView) async throws -> SendView {
        let send = try await clientVault.sends().encrypt(send: sendView)
        let newSend = try await sendService.addTextSend(send)
        return try await clientVault.sends().decrypt(send: newSend)
    }

    func deleteSend(_ sendView: SendView) async throws {
        let send = try await clientVault.sends().encrypt(send: sendView)
        try await sendService.deleteSend(send)
    }

    func shareURL(for sendView: SendView) async throws -> URL? {
        let send = try await clientVault.sends().encrypt(send: sendView)

        guard let accessId = send.accessId else { return nil }
        let encodedKey = Data(send.key.utf8).base64EncodedString().urlEncoded()
        let sharePath = "/#/send/\(accessId)/\(encodedKey)"
        let url = URL(string: environmentService.webVaultURL.absoluteString.appending(sharePath))
        return url
    }

    func updateSend(_ sendView: SendView) async throws -> SendView {
        let send = try await clientVault.sends().encrypt(send: sendView)
        let newSend = try await sendService.updateSend(send)
        return try await clientVault.sends().decrypt(send: newSend)
    }

    // MARK: API Methods

    func fetchSync(isManualRefresh: Bool) async throws {
        let allowSyncOnRefresh = try await stateService.getAllowSyncOnRefresh()
        if !isManualRefresh || allowSyncOnRefresh {
            try await syncService.fetchSync()
        }
    }

    // MARK: Publishers

    func searchSendPublisher(
        searchText: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListItem], Error>> {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        return try await sendService.sendsPublisher().asyncTryMap { sends -> [SendListItem] in
            // Convert the Sends to SendViews and filter appropriately.
            let activeSends = try await sends.asyncMap { send in
                try await self.clientVault.sends().decrypt(send: send)
            }

            var matchedSends: [SendView] = []
            var lowPriorityMatchedSends: [SendView] = []

            // Search the sends.
            activeSends.forEach { sendView in
                if sendView.name.lowercased()
                    .folding(options: .diacriticInsensitive, locale: nil).contains(query) {
                    matchedSends.append(sendView)
                } else if sendView.text?.text?.lowercased()
                    .folding(options: .diacriticInsensitive, locale: nil).contains(query) == true {
                    lowPriorityMatchedSends.append(sendView)
                } else if sendView.file?.fileName.lowercased()
                    .folding(options: .diacriticInsensitive, locale: nil).contains(query) == true {
                    lowPriorityMatchedSends.append(sendView)
                }
            }

            // Return the result.
            let result = matchedSends.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending } +
                lowPriorityMatchedSends
            return result.compactMap { SendListItem(sendView: $0) }
        }.eraseToAnyPublisher().values
    }

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

        guard !sends.isEmpty else {
            return []
        }

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
