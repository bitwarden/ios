import BitwardenKit
import BitwardenResources
import BitwardenSdk
import Combine
import Foundation

// MARK: - SendRepository

/// A protocol for a `SendRepository` which manages access to the data needed by the UI layer.
///
public protocol SendRepository: AnyObject {
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

    /// Validates the user's active account has access to premium features.
    ///
    /// - Returns: Whether the active account has premium.
    ///
    func doesActiveAccountHavePremium() async -> Bool

    /// Validates the user's active account has a verified email.
    ///
    /// - Returns: Whether the active account has a verified email.
    ///
    func doesActiveAccountHaveVerifiedEmail() async throws -> Bool

    /// Performs an API request to sync the user's send data. The publishers in the repository can
    /// be used to subscribe to the send data, which are updated as a result of the request.
    ///
    /// - Parameters:
    ///   - forceSync: Whether the sync should be forced.
    ///   - isPeriodic: Whether the sync is periodic to take into account the minimum interval.
    func fetchSync(forceSync: Bool, isPeriodic: Bool) async throws

    /// Performs an API request to remove the password on the provided send.
    ///
    /// - Parameter sendView: The send to remove the password from.
    ///
    func removePassword(from sendView: SendView) async throws -> SendView

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

    // MARK: Publishers

    /// A publisher for a user's send objects based on the specified search text.
    ///
    /// - Parameters:
    ///   - searchText: The search text to filter the send list.
    ///   - type: An optional `SendType` to use to filter the search results.
    /// - Returns: A publisher for the user's sends.
    ///
    func searchSendPublisher(
        searchText: String,
        type: SendType?
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListItem], Error>>

    /// A publisher for all the sends in the user's account.
    ///
    /// - Returns: A publisher for the list of sends in the user's account.
    ///
    func sendListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListSection], Error>>

    /// A publisher for a send.
    ///
    /// - Parameter id: The ID of the send that is being subscribed to.
    /// - Returns: A publisher for a send with a specified identifier.
    ///
    func sendPublisher(id: String) async throws -> AsyncThrowingPublisher<AnyPublisher<SendView?, Error>>

    /// A publisher for all the sends in the user's account.
    ///
    /// - Parameter: The `SendType` to use to filter the sends.
    /// - Returns: A publisher for the list of sends in the user's account.
    ///
    func sendTypeListPublisher(
        type: SendType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListItem], Error>>
}

extension SendRepository {
    /// A publisher for a user's send objects based on the specified search text.
    ///
    /// - Parameter searchText:  The search text to filter the send list.
    /// - Returns: A publisher for the user's sends.
    ///
    func searchSendPublisher(
        searchText: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListItem], Error>> {
        try await searchSendPublisher(searchText: searchText, type: nil)
    }
}

// MARK: - DefaultSendRepository

class DefaultSendRepository: SendRepository {
    // MARK: Properties

    /// The service that handles common client functionality such as encryption and decryption.
    let clientService: ClientService

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
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - environmentService: The service used to retrieve urls for the active account's environment.
    ///   - organizationService: The service used to manage syncing and updates to the user's organizations.
    ///   - sendService: The service used to sync and store sends.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///
    init(
        clientService: ClientService,
        environmentService: EnvironmentService,
        organizationService: OrganizationService,
        sendService: SendService,
        stateService: StateService,
        syncService: SyncService
    ) {
        self.clientService = clientService
        self.environmentService = environmentService
        self.organizationService = organizationService
        self.sendService = sendService
        self.stateService = stateService
        self.syncService = syncService
    }

    // MARK: Methods

    func doesActiveAccountHavePremium() async -> Bool {
        await stateService.doesActiveAccountHavePremium()
    }

    func doesActiveAccountHaveVerifiedEmail() async throws -> Bool {
        let account = try await stateService.getActiveAccount()
        return account.profile.emailVerified ?? false
    }

    // MARK: Data Methods

    func addFileSend(_ sendView: SendView, data: Data) async throws -> SendView {
        let send = try await clientService.sends().encrypt(send: sendView)
        let file = try await clientService.sends().encryptBuffer(send: send, buffer: data)
        let newSend = try await sendService.addFileSend(send, data: file)
        return try await clientService.sends().decrypt(send: newSend)
    }

    func addTextSend(_ sendView: SendView) async throws -> SendView {
        let send = try await clientService.sends().encrypt(send: sendView)
        let newSend = try await sendService.addTextSend(send)
        return try await clientService.sends().decrypt(send: newSend)
    }

    func deleteSend(_ sendView: SendView) async throws {
        let send = try await clientService.sends().encrypt(send: sendView)
        try await sendService.deleteSend(send)
    }

    func removePassword(from sendView: SendView) async throws -> SendView {
        let send = try await clientService.sends().encrypt(send: sendView)
        let newSend = try await sendService.removePasswordFromSend(send)
        return try await clientService.sends().decrypt(send: newSend)
    }

    func shareURL(for sendView: SendView) async throws -> URL? {
        guard let accessId = sendView.accessId, let key = sendView.key else { return nil }
        let sharePath = "\(accessId)/\(key)"
        var sendShareUrlString = environmentService.sendShareURL.absoluteString
        if !sendShareUrlString.hasSuffix("#") {
            sendShareUrlString = sendShareUrlString.appending("/")
        }
        let url = URL(string: sendShareUrlString.appending(sharePath))
        return url
    }

    func updateSend(_ sendView: SendView) async throws -> SendView {
        let send = try await clientService.sends().encrypt(send: sendView)
        let newSend = try await sendService.updateSend(send)
        return try await clientService.sends().decrypt(send: newSend)
    }

    // MARK: API Methods

    func fetchSync(forceSync: Bool, isPeriodic: Bool) async throws {
        let allowSyncOnRefresh = try await stateService.getAllowSyncOnRefresh()
        if !forceSync || allowSyncOnRefresh {
            try await syncService.fetchSync(forceSync: forceSync, isPeriodic: isPeriodic)
        }
    }

    // MARK: Publishers

    func searchSendPublisher(
        searchText: String,
        type: SendType?
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListItem], Error>> {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        return try await sendService.sendsPublisher().asyncTryMap { sends -> [SendListItem] in
            // Convert the Sends to SendViews and filter appropriately.
            var activeSends = try await sends.asyncMap { send in
                try await self.clientService.sends().decrypt(send: send)
            }

            if let type {
                let sendType = BitwardenSdk.SendType(type: type)
                activeSends = activeSends.filter { $0.type == sendType }
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

    func sendTypeListPublisher(
        type: SendType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListItem], Error>> {
        try await sendService.sendsPublisher()
            .asyncTryMap { sends in
                try await self.sendListItems(type: type, from: sends)
            }
            .eraseToAnyPublisher()
            .values
    }

    func sendPublisher(id: String) async throws -> AsyncThrowingPublisher<AnyPublisher<SendView?, Error>> {
        try await sendService.sendPublisher(id: id)
            .asyncTryMap { send in
                guard let send else { return nil }
                return try await self.clientService.sends().decrypt(send: send)
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
            .asyncMap { try await clientService.sends().decrypt(send: $0) }
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
                items: types,
                name: Localizations.types
            ),
            SendListSection(
                id: "AllSends",
                items: allItems,
                name: Localizations.allSends
            ),
        ]
    }

    /// Returns a list of items that are grouped together in the send list from a list of encrypted
    /// sends.
    ///
    /// - Parameters:
    ///   - type: The type of sends to get.
    ///   - ciphers: The ciphers to build the list of items.
    /// - Returns: A list of items for the group in the vault list.
    ///
    private func sendListItems(
        type: SendType,
        from sends: [Send]
    ) async throws -> [SendListItem] {
        let sendType = BitwardenSdk.SendType(type: type)
        let sends = try await sends.asyncMap { send in
            try await self.clientService.sends().decrypt(send: send)
        }
        .filter { $0.type == sendType }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        .compactMap(SendListItem.init)

        return sends
    }
}
