// MARK: - SettingsService

/// A protocol for a `SettingsService` which manages syncing and updates to the user's settings.
///
protocol SettingsService: AnyObject {
    /// Fetches the list of equivalent domains for the current user.
    ///
    /// - Returns: The list of equivalent domains.
    ///
    func fetchEquivalentDomains() async throws -> [[String]]

    /// Replaces the list of domains for the user.
    ///
    /// - Parameters:
    ///   - domains: The list of domains.
    ///   - userId: The user ID associated with the domains.
    ///
    func replaceEquivalentDomains(_ domains: DomainsResponseModel?, userId: String) async throws
}

// MARK: - DefaultSettingsService

/// A default implementation of a `SettingsService` which manages syncing and updates to the user's
/// settings.
///
class DefaultSettingsService: SettingsService {
    // MARK: Properties

    /// The data store for managing the persisted settings for the user.
    let settingsDataStore: SettingsDataStore

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultSettingsService`.
    ///
    /// - Parameters:
    ///   - settingsDataStore: The data store for managing the persisted settings for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(settingsDataStore: SettingsDataStore, stateService: StateService) {
        self.settingsDataStore = settingsDataStore
        self.stateService = stateService
    }
}

extension DefaultSettingsService {
    func fetchEquivalentDomains() async throws -> [[String]] {
        let userId = try await stateService.getActiveAccountId()
        guard let domains = try await settingsDataStore.fetchEquivalentDomains(userId: userId) else {
            return []
        }
        let equivalentDomains = domains.equivalentDomains ?? []
        let globalEquivalentDomains = domains.globalEquivalentDomains?.compactMap(\.domains) ?? []
        return equivalentDomains + globalEquivalentDomains
    }

    func replaceEquivalentDomains(_ domains: DomainsResponseModel?, userId: String) async throws {
        guard let domains else {
            try await settingsDataStore.deleteEquivalentDomains(userId: userId)
            return
        }
        try await settingsDataStore.replaceEquivalentDomains(domains, userId: userId)
    }
}
