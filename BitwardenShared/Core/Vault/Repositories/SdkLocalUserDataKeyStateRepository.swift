import BitwardenSdk

/// `LocalUserDataKeyStateRepository` implementation to be used on SDK client-managed state.
/// Stores the wrapped user key in `AppSettingsStore` (UserDefaults) per user, keyed by the
/// SDK-assigned id. Never stores unencrypted key material.
actor SdkLocalUserDataKeyStateRepository: BitwardenSdk.LocalUserDataKeyStateRepository {
    // MARK: Properties

    /// The service for managing account state.
    private let stateService: LocalUserDataStateService

    /// The user ID of the SDK instance this repository belongs to.
    nonisolated let userId: String

    // MARK: Initialization

    /// Initializes a `SdkLocalUserDataKeyStateRepository`.
    /// - Parameters:
    ///   - stateService: The service for managing account state.
    ///   - userId: The user ID of the SDK instance this repository belongs to.
    init(stateService: LocalUserDataStateService, userId: String) {
        self.stateService = stateService
        self.userId = userId
    }

    // MARK: LocalUserDataKeyStateRepository

    func get(id: String) async throws -> LocalUserDataKeyState? {
        try await stateService.getLocalUserDataKeyStates(userId: userId)?[id]
            .map { LocalUserDataKeyState($0) }
    }

    func has(id: String) async throws -> Bool {
        try await stateService.getLocalUserDataKeyStates(userId: userId)?[id] != nil
    }

    func list() async throws -> [LocalUserDataKeyState] {
        try await (stateService.getLocalUserDataKeyStates(userId: userId) ?? [:])
            .values.map { LocalUserDataKeyState($0) }
    }

    func remove(id: String) async throws {
        try await stateService.removeLocalUserDataKeyState(id: id, userId: userId)
    }

    func removeBulk(keys: [String]) async throws {
        try await stateService.removeBulkLocalUserDataKeyStates(keys: keys, userId: userId)
    }

    func removeAll() async throws {
        try await stateService.removeAllLocalUserDataKeyStates(userId: userId)
    }

    func set(id: String, value: LocalUserDataKeyState) async throws {
        try await stateService.setLocalUserDataKeyState(
            id: id,
            value: UserKeyData(localUserDataKeyState: value),
            userId: userId,
        )
    }

    func setBulk(values: [String: LocalUserDataKeyState]) async throws {
        try await stateService.setBulkLocalUserDataKeyStates(
            values.mapValues { UserKeyData(localUserDataKeyState: $0) },
            userId: userId,
        )
    }
}
