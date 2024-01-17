import BitwardenSdk

// MARK: - SendService

/// A protocol for a `SendService` which manages syncing and updates to the user's sends.
///
protocol SendService {
    /// Adds a new Send for the current user in both the backend and in local storage.
    ///
    /// - Parameter send: The send to add.
    ///
    func addSend(_ send: Send) async throws

    /// Updates an existing Send for the current user in both the backend and in local storage.
    ///
    /// - Parameter send: The send to update.
    ///
    func updateSend(_ send: Send) async throws

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

    /// The service used to make cipher related API requests.
    let sendAPIService: SendAPIService

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
    init(
        sendAPIService: SendAPIService,
        sendDataStore: SendDataStore,
        stateService: StateService
    ) {
        self.sendAPIService = sendAPIService
        self.sendDataStore = sendDataStore
        self.stateService = stateService
    }
}

extension DefaultSendService {
    func addSend(_ send: Send) async throws {
        let userId = try await stateService.getActiveAccountId()
        let response = try await sendAPIService.addSend(send)

        let newSend = Send(sendResponseModel: response)
        try await sendDataStore.upsertSend(newSend, userId: userId)
    }

    func updateSend(_ send: Send) async throws {
        let userId = try await stateService.getActiveAccountId()
        let response = try await sendAPIService.updateSend(send)

        let newSend = Send(sendResponseModel: response)
        try await sendDataStore.upsertSend(newSend, userId: userId)
    }

    func replaceSends(_ sends: [SendResponseModel], userId: String) async throws {
        try await sendDataStore.replaceSends(sends.map(Send.init), userId: userId)
    }
}
