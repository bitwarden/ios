import BitwardenSdk
import Combine
import Foundation

// MARK: - SendService

/// A protocol for a `SendService` which manages syncing and updates to the user's sends.
///
protocol SendService {
    /// Adds a new file Send for the current user in both the backend and in local storage.
    ///
    /// - Parameters
    ///   - send: The send to add.
    ///   - data: The data representation of the file.
    ///
    func addFileSend(_ send: Send, data: Data) async throws -> Send

    /// Adds a new text Send for the current user in both the backend and in local storage.
    ///
    /// - Parameter send: The send to add.
    ///
    func addTextSend(_ send: Send) async throws -> Send

    /// Deletes the send in both the backend and in local storage.
    ///
    /// - Parameter send: The send to be deleted.
    ///
    func deleteSend(_ send: Send) async throws

    /// Deletes the send in local storage.
    ///
    /// - Parameter id: The id of the send to be deleted.
    ///
    func deleteSendWithLocalStorage(id: String) async throws

    /// Retrieves a Send from local storage, if one can be found.
    ///
    /// - Parameter id: The id of the send to retrieve.
    ///
    func fetchSend(id: String) async throws -> Send?

    /// Removes the password from the provided send.
    ///
    /// - Parameter send: The send to remove the password from.
    ///
    func removePasswordFromSend(_ send: Send) async throws -> Send

    /// Attempts to synchronize a send with the server.
    ///
    /// This method fetches the updated send value from the server and updates the value in the
    /// local storage.
    ///
    /// - Parameter id: The id of the send to fetch.
    ///
    func syncSendWithServer(id: String) async throws

    /// Updates an existing Send for the current user in both the backend and in local storage.
    ///
    /// - Parameter send: The send to update.
    ///
    func updateSend(_ send: Send) async throws -> Send

    /// Replaces the persisted list of sends for the user.
    ///
    /// - Parameters:
    ///   - sends: The updated list of sends for the user.
    ///   - userId: The user ID associated with the sends.
    ///
    func replaceSends(_ sends: [SendResponseModel], userId: String) async throws

    // MARK: Publishers

    /// A publisher for a `Send`.
    ///
    /// - Parameter id: The ID of the `Send` to publish updates for.
    /// - Returns: A publisher containing the encrypted send.
    ///
    func sendPublisher(id: String) async throws -> AnyPublisher<Send?, Error>

    /// A publisher for the list of sends.
    ///
    /// - Returns: The list of encrypted sends.
    ///
    func sendsPublisher() async throws -> AnyPublisher<[Send], Error>
}

// MARK: - DefaultSendService

class DefaultSendService: SendService {
    // MARK: Properties

    /// The service used to make file related API requests.
    private let fileAPIService: FileAPIService

    /// The service used to make send related API requests.
    private let sendAPIService: SendAPIService

    /// The data store for managing the persisted sends for the user.
    private let sendDataStore: SendDataStore

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultSendService`.
    ///
    /// - Parameters:
    ///   - fileAPIService: The service used to make file related API requests.
    ///   - sendAPIService: The service used to make send related API requests.
    ///   - sendDataStore: The data store for managing the persisted sends for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        fileAPIService: FileAPIService,
        sendAPIService: SendAPIService,
        sendDataStore: SendDataStore,
        stateService: StateService
    ) {
        self.fileAPIService = fileAPIService
        self.sendAPIService = sendAPIService
        self.sendDataStore = sendDataStore
        self.stateService = stateService
    }
}

extension DefaultSendService {
    func addFileSend(_ send: Send, data: Data) async throws -> Send {
        let userId = try await stateService.getActiveAccountId()

        let response = try await sendAPIService.addFileSend(send, fileLength: data.count)

        do {
            try await fileAPIService.uploadSendFile(
                data: data,
                type: response.fileUploadType,
                fileId: response.sendResponse.file?.id ?? "",
                fileName: send.file?.fileName ?? "",
                sendId: response.sendResponse.id,
                url: response.url
            )
        } catch {
            // If the file upload fails for any reason, bail out on saving this send by deleting it
            // on the server.
            try await sendAPIService.deleteSend(with: response.sendResponse.id)
            throw error
        }

        let newSend = Send(sendResponseModel: response.sendResponse)
        try await sendDataStore.upsertSend(newSend, userId: userId)
        return newSend
    }

    func addTextSend(_ send: Send) async throws -> Send {
        let userId = try await stateService.getActiveAccountId()

        let response = try await sendAPIService.addTextSend(send)

        let newSend = Send(sendResponseModel: response)
        try await sendDataStore.upsertSend(newSend, userId: userId)
        return newSend
    }

    func deleteSend(_ send: Send) async throws {
        guard let id = send.id else { return }
        let userId = try await stateService.getActiveAccountId()

        try await sendAPIService.deleteSend(with: id)
        try await sendDataStore.deleteSend(id: id, userId: userId)
    }

    func deleteSendWithLocalStorage(id: String) async throws {
        let userId = try await stateService.getActiveAccountId()
        try await sendDataStore.deleteSend(id: id, userId: userId)
    }

    func fetchSend(id: String) async throws -> Send? {
        let userId = try await stateService.getActiveAccountId()
        return try await sendDataStore.fetchSend(id: id, userId: userId)
    }

    func removePasswordFromSend(_ send: Send) async throws -> Send {
        guard let id = send.id else {
            throw BitwardenError.dataError("Send missing id.")
        }
        let userId = try await stateService.getActiveAccountId()

        let response = try await sendAPIService.removePasswordFromSend(with: id)

        let newSend = Send(sendResponseModel: response)
        try await sendDataStore.upsertSend(newSend, userId: userId)
        return newSend
    }

    func syncSendWithServer(id: String) async throws {
        let userId = try await stateService.getActiveAccountId()

        let response = try await sendAPIService.getSend(with: id)
        let send = Send(sendResponseModel: response)
        try await sendDataStore.upsertSend(send, userId: userId)
    }

    func updateSend(_ send: Send) async throws -> Send {
        let userId = try await stateService.getActiveAccountId()
        let response = try await sendAPIService.updateSend(send)

        let newSend = Send(sendResponseModel: response)
        try await sendDataStore.upsertSend(newSend, userId: userId)
        return newSend
    }

    func replaceSends(_ sends: [SendResponseModel], userId: String) async throws {
        try await sendDataStore.replaceSends(sends.map(Send.init), userId: userId)
    }

    func sendPublisher(id: String) async throws -> AnyPublisher<Send?, Error> {
        let userId = try await stateService.getActiveAccountId()
        return sendDataStore.sendPublisher(id: id, userId: userId)
    }

    func sendsPublisher() async throws -> AnyPublisher<[Send], Error> {
        let userId = try await stateService.getActiveAccountId()
        return sendDataStore.sendsPublisher(userId: userId)
    }
}
