import BitwardenSdk

// MARK: - SendService

/// A protocol for a `SendService` which manages syncing and updates to the user's sends.
///
protocol SendService {
    /// Replaces the persisted list of sends for the user.
    ///
    /// - Parameters:
    ///   - sends: The updated list of sends for the user.
    ///   - userId: The user ID associated with the sends.
    ///
    func replaceSends(_ sends: [SendResponseModel], userId: String) async throws
}

// MARK: - DefaultSendService

class DefaultSendService: SendService {
    // MARK: Properties

    /// The data store for managing the persisted sends for the user.
    let sendDataStore: SendDataStore

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultSendService`.
    ///
    /// - Parameters:
    ///   - sendDataStore: The data store for managing the persisted sends for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(sendDataStore: SendDataStore, stateService: StateService) {
        self.sendDataStore = sendDataStore
        self.stateService = stateService
    }
}

extension DefaultSendService {
    func replaceSends(_ sends: [SendResponseModel], userId: String) async throws {
        try await sendDataStore.replaceSends(sends.map(Send.init), userId: userId)
    }
}
