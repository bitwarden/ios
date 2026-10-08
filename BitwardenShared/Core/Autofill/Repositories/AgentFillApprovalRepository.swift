import BitwardenKit
import BitwardenSdk

// MARK: - AgentFillApprovalRepository

/// A protocol for a repository that manages agent fill approval requests: fetching and opening
/// sealed requests, finding the items the user can choose from, and sending sealed answers.
///
protocol AgentFillApprovalRepository { // sourcery: AutoMockable
    /// Sends the user's decision for an opened approval request.
    ///
    /// - Parameters:
    ///   - id: The ID of the approval request.
    ///   - opened: The opened request that is being answered.
    ///   - decision: The user's decision.
    /// - Returns: Whether the answer was recorded, or the request was already answered or expired.
    ///
    func answer(
        _ id: String,
        opened: OpenedApprovalRequest,
        decision: ApprovalDecision,
    ) async throws -> AgentFillApprovalAnswerResult

    /// Returns the ciphers the user can approve for an opened request. Logins are matched against
    /// the request's tab URL and cards are listed in full. Deleted, archived and master password
    /// re-prompt items are always left out.
    ///
    /// - Parameter request: The request to find ciphers for.
    /// - Returns: The ciphers that can be approved.
    ///
    func fetchApprovableCiphers(for request: ApprovalRequestView) async throws -> [CipherListView]

    /// Gets an approval record from the server.
    ///
    /// - Parameter id: The ID of the approval request.
    /// - Returns: The approval record.
    ///
    func get(_ id: String) async throws -> AgentFillApprovalRecord

    /// Gets an approval record and opens its sealed request with the active account's key.
    ///
    /// - Parameter id: The ID of the approval request.
    /// - Returns: The record and the opened request.
    ///
    func open(_ id: String) async throws -> (AgentFillApprovalRecord, OpenedApprovalRequest)
}

// MARK: - DefaultAgentFillApprovalRepository

/// The default implementation of `AgentFillApprovalRepository`.
///
class DefaultAgentFillApprovalRepository: AgentFillApprovalRepository {
    // MARK: Properties

    /// The API service used to make approval requests.
    private let apiService: AgentFillApprovalAPIService

    /// The factory used to create helpers that match logins against a URL.
    private let cipherMatchingHelperFactory: CipherMatchingHelperFactory

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service used by the application for recording temporary debug logs.
    private let flightRecorder: FlightRecorder

    // MARK: Initialization

    /// Initialize a `DefaultAgentFillApprovalRepository`.
    ///
    /// - Parameters:
    ///   - apiService: The API service used to make approval requests.
    ///   - cipherMatchingHelperFactory: The factory used to create helpers that match logins
    ///     against a URL.
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption
    ///     and decryption.
    ///   - flightRecorder: The service used by the application for recording temporary debug logs.
    ///
    init(
        apiService: AgentFillApprovalAPIService,
        cipherMatchingHelperFactory: CipherMatchingHelperFactory,
        cipherService: CipherService,
        clientService: ClientService,
        flightRecorder: FlightRecorder,
    ) {
        self.apiService = apiService
        self.cipherMatchingHelperFactory = cipherMatchingHelperFactory
        self.cipherService = cipherService
        self.clientService = clientService
        self.flightRecorder = flightRecorder
    }

    // MARK: AgentFillApprovalRepository

    func answer(
        _ id: String,
        opened: OpenedApprovalRequest,
        decision: ApprovalDecision,
    ) async throws -> AgentFillApprovalAnswerResult {
        let sealedResponse = try await clientService.agentFill().approvals().sealResponse(
            approvalRequestId: id,
            request: opened,
            decision: decision,
        )
        let result = try await apiService.answerAgentFillApproval(id, sealedResponse: sealedResponse)
        await flightRecorder.log("[AgentFill] Answered approval \(id): \(result)")
        return result
    }

    func fetchApprovableCiphers(for request: ApprovalRequestView) async throws -> [CipherListView] {
        let ciphers = try await cipherService.fetchAllCiphers()
        let decrypted = try await clientService.vault().ciphers()
            .decryptListWithFailures(ciphers: ciphers)
            .successes
            .filter { $0.deletedDate == nil && $0.archivedDate == nil && $0.reprompt == .none }

        let approvable: [CipherListView]
        switch request.cipherType {
        case .login:
            let matchingHelper = await cipherMatchingHelperFactory.make(uri: request.tabUrl)
            approvable = decrypted.filter { matchingHelper.doesCipherMatch(cipher: $0) != .none }
        case .card:
            approvable = decrypted.filter(\.type.isCard)
        }
        return approvable.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func get(_ id: String) async throws -> AgentFillApprovalRecord {
        try await apiService.getAgentFillApproval(id)
    }

    func open(_ id: String) async throws -> (AgentFillApprovalRecord, OpenedApprovalRequest) {
        let record = try await apiService.getAgentFillApproval(id)
        let opened = try await clientService.agentFill().approvals().openRequest(
            sealedRequest: record.sealedRequest,
        )
        await flightRecorder.log("[AgentFill] Opened approval \(id)")
        return (record, opened)
    }
}
