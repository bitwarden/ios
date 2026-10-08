import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import BitwardenSdkMocks
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AgentFillApprovalRepositoryTests

@MainActor
struct AgentFillApprovalRepositoryTests {
    // MARK: Properties

    let apiService: MockAgentFillApprovalAPIService
    let cipherMatchingHelper: MockCipherMatchingHelper
    let cipherMatchingHelperFactory: MockCipherMatchingHelperFactory
    let cipherService: MockCipherService
    let clientService: MockClientService
    let flightRecorder: MockFlightRecorder
    let subject: DefaultAgentFillApprovalRepository

    // MARK: Initialization

    init() {
        apiService = MockAgentFillApprovalAPIService()
        cipherMatchingHelper = MockCipherMatchingHelper()
        cipherMatchingHelperFactory = MockCipherMatchingHelperFactory()
        cipherMatchingHelperFactory.makeReturnValue = cipherMatchingHelper
        cipherService = MockCipherService()
        clientService = MockClientService()
        flightRecorder = MockFlightRecorder()

        subject = DefaultAgentFillApprovalRepository(
            apiService: apiService,
            cipherMatchingHelperFactory: cipherMatchingHelperFactory,
            cipherService: cipherService,
            clientService: clientService,
            flightRecorder: flightRecorder,
        )
    }

    // MARK: Tests

    /// `answer(_:opened:decision:)` seals the decision, sends it and returns the result.
    @Test
    func answer() async throws {
        let opened = OpenedApprovalRequest.fixture()
        clientService.mockAgentFill.clientApprovals.sealResponseReturnValue = "sealed-response"
        apiService.answerAgentFillApprovalReturnValue = .answered

        let result = try await subject.answer(
            "approval-1",
            opened: opened,
            decision: .approved(cipherId: "cipher-1"),
        )

        #expect(result == .answered)
        let sealArguments = try #require(clientService.mockAgentFill.clientApprovals.sealResponseReceivedArguments)
        #expect(sealArguments.approvalRequestId == "approval-1")
        #expect(sealArguments.request == opened)
        #expect(sealArguments.decision == .approved(cipherId: "cipher-1"))
        #expect(apiService.answerAgentFillApprovalReceivedArguments?.id == "approval-1")
        #expect(apiService.answerAgentFillApprovalReceivedArguments?.sealedResponse == "sealed-response")
        #expect(flightRecorder.logMessages == ["[AgentFill] Answered approval approval-1: answered"])
    }

    /// `answer(_:opened:decision:)` returns `alreadyAnswered` when the server reports a conflict.
    @Test
    func answer_alreadyAnswered() async throws {
        clientService.mockAgentFill.clientApprovals.sealResponseReturnValue = "sealed-response"
        apiService.answerAgentFillApprovalReturnValue = .alreadyAnswered

        let result = try await subject.answer(
            "approval-1",
            opened: .fixture(),
            decision: .denied(reason: nil),
        )

        #expect(result == .alreadyAnswered)
    }

    /// `answer(_:opened:decision:)` doesn't send anything if the decision can't be sealed.
    @Test
    func answer_sealError() async {
        clientService.mockAgentFill.clientApprovals.sealResponseThrowableError = BitwardenTestError.example

        await #expect(throws: BitwardenTestError.example) {
            try await subject.answer("approval-1", opened: .fixture(), decision: .denied(reason: nil))
        }
        #expect(!apiService.answerAgentFillApprovalCalled)
    }

    /// `fetchApprovableCiphers(for:)` returns the logins that match the tab URL, leaving out
    /// deleted, archived and re-prompt items.
    @Test
    func fetchApprovableCiphers_login() async throws {
        let matching = CipherListView.fixture(id: "matching", name: "Matching")
        let notMatching = CipherListView.fixture(id: "not-matching", name: "Not matching")
        cipherService.fetchAllCiphersResult = .success([
            .fixture(id: "matching"),
            .fixture(id: "not-matching"),
            .fixture(id: "deleted"),
            .fixture(id: "archived"),
            .fixture(id: "reprompt"),
        ])
        clientService.mockVault.clientCiphers.decryptListWithFailuresClosure = { _ in
            DecryptCipherListResult(
                successes: [
                    notMatching,
                    matching,
                    .fixture(id: "deleted", deletedDate: .now),
                    .fixture(id: "archived", archivedDate: .now),
                    .fixture(id: "reprompt", reprompt: .password),
                ],
                failures: [],
            )
        }
        cipherMatchingHelper.doesCipherMatchClosure = { $0.id == "matching" ? .exact : .none }

        let ciphers = try await subject.fetchApprovableCiphers(
            for: ApprovalRequestView.fixture(cipherType: .login, tabUrl: "https://delta.com/login"),
        )

        #expect(ciphers == [matching])
        #expect(cipherMatchingHelperFactory.makeReceivedUri == "https://delta.com/login")
    }

    /// `fetchApprovableCiphers(for:)` lists the cards, leaving out deleted, archived and re-prompt items.
    @Test
    func fetchApprovableCiphers_card() async throws {
        let visa = CipherListView.fixture(id: "visa", name: "Visa", type: .card(CardListView(brand: "Visa")))
        let amex = CipherListView.fixture(id: "amex", name: "Amex", type: .card(CardListView(brand: "Amex")))
        clientService.mockVault.clientCiphers.decryptListWithFailuresClosure = { _ in
            DecryptCipherListResult(
                successes: [
                    visa,
                    .fixture(id: "login", name: "A login"),
                    .fixture(id: "deleted", type: .card(CardListView(brand: nil)), deletedDate: .now),
                    .fixture(id: "archived", type: .card(CardListView(brand: nil)), archivedDate: .now),
                    .fixture(id: "reprompt", type: .card(CardListView(brand: nil)), reprompt: .password),
                    amex,
                ],
                failures: [],
            )
        }

        let ciphers = try await subject.fetchApprovableCiphers(for: .fixture(cipherType: .card))

        #expect(ciphers == [amex, visa])
        #expect(!cipherMatchingHelperFactory.makeCalled)
    }

    /// `get(_:)` returns the record from the server.
    @Test
    func get() async throws {
        apiService.getAgentFillApprovalReturnValue = .fixture()

        let record = try await subject.get("approval-1")

        #expect(record == .fixture())
        #expect(apiService.getAgentFillApprovalReceivedId == "approval-1")
    }

    /// `open(_:)` fetches the record and opens its sealed request.
    @Test
    func open() async throws {
        let opened = OpenedApprovalRequest.fixture()
        apiService.getAgentFillApprovalReturnValue = .fixture(sealedRequest: "sealed-request")
        clientService.mockAgentFill.clientApprovals.openRequestReturnValue = opened

        let (record, openedRequest) = try await subject.open("approval-1")

        #expect(record == .fixture(sealedRequest: "sealed-request"))
        #expect(openedRequest == opened)
        #expect(clientService.mockAgentFill.clientApprovals.openRequestReceivedSealedRequest == "sealed-request")
        #expect(flightRecorder.logMessages == ["[AgentFill] Opened approval approval-1"])
    }

    /// `open(_:)` throws if the sealed request can't be opened.
    @Test
    func open_unsealError() async {
        apiService.getAgentFillApprovalReturnValue = .fixture()
        clientService.mockAgentFill.clientApprovals.openRequestThrowableError = BitwardenTestError.example

        await #expect(throws: BitwardenTestError.example) {
            _ = try await subject.open("approval-1")
        }
        #expect(flightRecorder.logMessages.isEmpty)
    }
}
