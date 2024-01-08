import BitwardenSdk
import Combine
import Foundation

// MARK: - SendRepository

/// A protocol for a `SendRepository` which manages access to the data needed by the UI layer.
///
protocol SendRepository: AnyObject {
    // MARK: Publishers

    func fetchSync() async throws

    /// A publisher for all the sends in the user's account.
    ///
    /// - Returns: A publisher for the list of sends in the user's account.
    ///
    func sendListPublisher() -> AsyncPublisher<AnyPublisher<[SendListSection], Never>>
}

// MARK: - DefaultSendRepository

class DefaultSendRepository: SendRepository {
    // MARK: Properties

    /// The client used by the application to handle vault encryption and decryption tasks.
    let clientVault: ClientVaultService

    /// The service used to handle syncing vault data with the API.
    let syncService: SyncService

    // MARK: Initialization

    /// Initialize a `DefaultSendRepository`.
    ///
    /// - Parameters:
    ///   - clientVault: The client used by the application to handle vault encryption and decryption tasks.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///
    init(
        clientVault: ClientVaultService,
        syncService: SyncService
    ) {
        self.clientVault = clientVault
        self.syncService = syncService
    }

    // MARK: API Methods

    func fetchSync() async throws {
        try await syncService.fetchSync()
    }

    // MARK: Publishers

    func sendListPublisher() -> AsyncPublisher<AnyPublisher<[SendListSection], Never>> {
        syncService.syncResponsePublisher()
            .asyncCompactMap { response in
                guard let response else { return nil }
                return try? await self.sendListSections(from: response)
            }
            .eraseToAnyPublisher()
            .values
    }

    // MARK: Private Methods

    /// Returns a list of the sections in the vault list from a sync response.
    ///
    /// - Parameter response: The sync response used to build the list of sections.
    /// - Returns: A list of the sections to display in the vault list.
    ///
    private func sendListSections(from response: SyncResponseModel) async throws -> [SendListSection] {
        let sends = try await response.sends
            .map(Send.init)
            .asyncMap { try await clientVault.sends().decrypt(send: $0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let fileSendsCount = sends
            .filter { $0.type == .file }
            .count
        let textSendsCount = sends
            .filter { $0.type == .text }
            .count

        let types = [
            SendListItem(id: "Types.File", itemType: .group(.file, fileSendsCount)),
            SendListItem(id: "Types.Text", itemType: .group(.text, textSendsCount)),
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
