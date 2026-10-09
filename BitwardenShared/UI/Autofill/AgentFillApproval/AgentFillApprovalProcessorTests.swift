import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AgentFillApprovalProcessorTests

@MainActor
struct AgentFillApprovalProcessorTests {
    // MARK: Properties

    let agentFillApprovalRepository: MockAgentFillApprovalRepository
    let authRepository: MockAuthRepository
    let biometricsService: MockBiometricsService
    let coordinator: MockCoordinator<AgentFillApprovalRoute, Void>
    let delegate: MockAgentFillApprovalDelegate
    let errorReporter: MockErrorReporter
    let subject: AgentFillApprovalProcessor

    // MARK: Initialization

    init() {
        agentFillApprovalRepository = MockAgentFillApprovalRepository()
        authRepository = MockAuthRepository()
        biometricsService = MockBiometricsService()
        coordinator = MockCoordinator()
        delegate = MockAgentFillApprovalDelegate()
        errorReporter = MockErrorReporter()

        biometricsService.getBiometricAuthStatusReturnValue = .authorized(.faceID)

        subject = AgentFillApprovalProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                agentFillApprovalRepository: agentFillApprovalRepository,
                authRepository: authRepository,
                biometricsService: biometricsService,
                errorReporter: errorReporter,
            ),
            state: AgentFillApprovalState(approvalId: "approval-1"),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.approve` verifies the user with biometrics only and approves the item.
    @Test
    func perform_approve_biometrics() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.evaluateBiometricPolicyReasonReturnValue = true
        agentFillApprovalRepository.answerReturnValue = .answered

        await subject.perform(.approve)

        #expect(
            biometricsService.evaluateBiometricPolicyReasonReceivedReason == Localizations.aiAgentFillBiometricPrompt,
        )
        #expect(agentFillApprovalRepository.answerReceivedArguments?.id == "approval-1")
        #expect(agentFillApprovalRepository.answerReceivedArguments?.decision == .approved(cipherId: "cipher-1"))
        #expect(authRepository.validatePasswordPasswords.isEmpty)
        #expect(coordinator.alertShown.isEmpty)
        #expect(!coordinator.isLoadingOverlayShowing)
        guard case let .dismiss(action) = coordinator.routes.last else {
            Issue.record("The view wasn't dismissed.")
            return
        }
        action?.action()
        #expect(delegate.answeredApproved == true)
    }

    /// `perform(_:)` with `.approve` offers the master password when the biometric prompt is cancelled.
    @Test
    func perform_approve_biometricsCancelled_masterPassword() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.evaluateBiometricPolicyReasonThrowableError = BitwardenTestError.example
        authRepository.validatePasswordResult = .success(true)
        agentFillApprovalRepository.answerReturnValue = .answered

        await subject.perform(.approve)

        #expect(!agentFillApprovalRepository.answerCalled)
        let alert = try #require(coordinator.alertShown.last)
        #expect(alert == .masterPasswordPrompt { _ in })

        let submitAction = try #require(alert.alertActions.first { $0.title == Localizations.submit })
        await submitAction.handler?(submitAction, [AlertTextField(id: "password", text: "password")])

        #expect(authRepository.validatePasswordPasswords == ["password"])
        #expect(agentFillApprovalRepository.answerReceivedArguments?.decision == .approved(cipherId: "cipher-1"))
    }

    /// `perform(_:)` with `.approve` goes straight to the master password when the device has no
    /// biometrics enrolled.
    @Test
    func perform_approve_noBiometrics_masterPassword() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.getBiometricAuthStatusReturnValue = .notDetermined

        await subject.perform(.approve)

        #expect(!biometricsService.evaluateBiometricPolicyReasonCalled)
        #expect(coordinator.alertShown.last == .masterPasswordPrompt { _ in })
        #expect(!agentFillApprovalRepository.answerCalled)
    }

    /// `perform(_:)` with `.approve` shows an alert and doesn't answer if the master password is wrong.
    @Test
    func perform_approve_invalidMasterPassword() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.getBiometricAuthStatusReturnValue = .notDetermined
        authRepository.validatePasswordResult = .success(false)

        await subject.perform(.approve)
        let alert = try #require(coordinator.alertShown.last)
        let submitAction = try #require(alert.alertActions.first { $0.title == Localizations.submit })
        await submitAction.handler?(submitAction, [AlertTextField(id: "password", text: "wrong")])

        #expect(coordinator.alertShown.last == .defaultAlert(title: Localizations.invalidMasterPassword))
        #expect(!agentFillApprovalRepository.answerCalled)
    }

    /// `perform(_:)` with `.approve` doesn't do anything if no item is selected.
    @Test
    func perform_approve_noSelection() async throws {
        try await loadPendingRequest(selecting: nil)

        await subject.perform(.approve)

        #expect(!biometricsService.evaluateBiometricPolicyReasonCalled)
        #expect(coordinator.alertShown.isEmpty)
        #expect(!agentFillApprovalRepository.answerCalled)
    }

    /// `perform(_:)` with `.approve` shows the handled state if the server reports a conflict.
    @Test
    func perform_approve_alreadyAnswered() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.evaluateBiometricPolicyReasonReturnValue = true
        agentFillApprovalRepository.answerReturnValue = .alreadyAnswered

        await subject.perform(.approve)

        #expect(subject.state.status == .handled)
        #expect(coordinator.routes.isEmpty)
    }

    /// `perform(_:)` with `.approve` shows the expired state if the server reports the request expired.
    @Test
    func perform_approve_expired() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.evaluateBiometricPolicyReasonReturnValue = true
        agentFillApprovalRepository.answerReturnValue = .expired

        await subject.perform(.approve)

        #expect(subject.state.status == .expired)
    }

    /// `perform(_:)` with `.approve` shows an error alert if answering fails.
    @Test
    func perform_approve_error() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.evaluateBiometricPolicyReasonReturnValue = true
        agentFillApprovalRepository.answerThrowableError = BitwardenTestError.example

        await subject.perform(.approve)

        #expect(coordinator.errorAlertsShown.last as? BitwardenTestError == .example)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(!coordinator.isLoadingOverlayShowing)
    }

    /// `perform(_:)` with `.deny` sends a denial without a reason.
    @Test
    func perform_deny_noReason() async throws {
        try await loadPendingRequest(selecting: nil)
        agentFillApprovalRepository.answerReturnValue = .answered

        await subject.perform(.deny(reason: nil))

        #expect(agentFillApprovalRepository.answerReceivedArguments?.decision == .denied(reason: nil))
        #expect(!biometricsService.evaluateBiometricPolicyReasonCalled)
        guard case let .dismiss(action) = coordinator.routes.last else {
            Issue.record("The view wasn't dismissed.")
            return
        }
        action?.action()
        #expect(delegate.answeredApproved == false)
    }

    /// `perform(_:)` with `.deny` sends a denial for the wrong account.
    @Test
    func perform_deny_wrongAccount() async throws {
        try await loadPendingRequest(selecting: nil)
        agentFillApprovalRepository.answerReturnValue = .answered

        await subject.perform(.deny(reason: .wrongAccount))

        #expect(agentFillApprovalRepository.answerReceivedArguments?.decision == .denied(reason: .wrongAccount))
    }

    /// `perform(_:)` with `.deny` sends a denial for a request the user didn't ask for.
    @Test
    func perform_deny_notRequested() async throws {
        try await loadPendingRequest(selecting: nil)
        agentFillApprovalRepository.answerReturnValue = .answered

        await subject.perform(.deny(reason: .notRequested))

        #expect(agentFillApprovalRepository.answerReceivedArguments?.decision == .denied(reason: .notRequested))
    }

    /// `perform(_:)` with `.deny` shows the handled state if the server reports a conflict.
    @Test
    func perform_deny_alreadyAnswered() async throws {
        try await loadPendingRequest(selecting: nil)
        agentFillApprovalRepository.answerReturnValue = .alreadyAnswered

        await subject.perform(.deny(reason: nil))

        #expect(subject.state.status == .handled)
    }

    /// `perform(_:)` with `.loadData` opens the request and shows the matching items.
    @Test
    func perform_loadData() async {
        agentFillApprovalRepository.openReturnValue = (.fixture(), .fixture())
        agentFillApprovalRepository.fetchApprovableCiphersReturnValue = [
            .fixture(id: "cipher-1", name: "Delta", subtitle: "user@example.com"),
            .fixture(id: "cipher-2", name: "Delta work", subtitle: "work@example.com"),
        ]

        await subject.perform(.loadData)

        #expect(subject.state.status == .pending)
        #expect(subject.state.cipherType == .login)
        #expect(subject.state.connectionName == "Claude Desktop")
        #expect(subject.state.domain == "delta.com")
        #expect(subject.state.browserName == "Chrome")
        #expect(subject.state.items == [
            AgentFillApprovalItem(id: "cipher-1", name: "Delta", subtitle: "user@example.com"),
            AgentFillApprovalItem(id: "cipher-2", name: "Delta work", subtitle: "work@example.com"),
        ])
        #expect(subject.state.selectedItemId == nil)
        #expect(agentFillApprovalRepository.openReceivedId == "approval-1")
        #expect(agentFillApprovalRepository.fetchApprovableCiphersReceivedRequest == .fixture())
    }

    /// `perform(_:)` with `.loadData` selects the only item automatically.
    @Test
    func perform_loadData_singleItem() async {
        agentFillApprovalRepository.openReturnValue = (.fixture(), .fixture())
        agentFillApprovalRepository.fetchApprovableCiphersReturnValue = [.fixture(id: "cipher-1")]

        await subject.perform(.loadData)

        #expect(subject.state.selectedItemId == "cipher-1")
        #expect(subject.state.canApprove)
    }

    /// `perform(_:)` with `.loadData` lists the cards for a card request.
    @Test
    func perform_loadData_card() async {
        let opened = OpenedApprovalRequest.fixture(view: .fixture(cipherType: .card))
        agentFillApprovalRepository.openReturnValue = (.fixture(), opened)
        agentFillApprovalRepository.fetchApprovableCiphersReturnValue = []

        await subject.perform(.loadData)

        #expect(subject.state.cipherType == .card)
        #expect(subject.state.items.isEmpty)
        #expect(!subject.state.canApprove)
    }

    /// `perform(_:)` with `.loadData` shows the handled state for a request that already has a response.
    @Test
    func perform_loadData_answered() async {
        agentFillApprovalRepository.openReturnValue = (.fixture(sealedResponse: "sealed-response"), .fixture())

        await subject.perform(.loadData)

        #expect(subject.state.status == .handled)
        #expect(!agentFillApprovalRepository.fetchApprovableCiphersCalled)
        #expect(!subject.state.canApprove)
    }

    /// `perform(_:)` with `.loadData` shows the expired state for a request past its expiration date.
    @Test
    func perform_loadData_expired() async {
        agentFillApprovalRepository.openReturnValue = (
            .fixture(expirationDate: Date(year: 2020, month: 1, day: 1)),
            .fixture(),
        )

        await subject.perform(.loadData)

        #expect(subject.state.status == .expired)
        #expect(!agentFillApprovalRepository.fetchApprovableCiphersCalled)
    }

    /// `perform(_:)` with `.loadData` shows an error and offers no approval if the request can't be opened.
    @Test
    func perform_loadData_openError() async {
        agentFillApprovalRepository.openThrowableError = BitwardenTestError.example

        await subject.perform(.loadData)

        #expect(subject.state.status == .failed)
        #expect(!subject.state.canApprove)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(!agentFillApprovalRepository.fetchApprovableCiphersCalled)
    }

    /// `perform(_:)` with `.deny` doesn't send anything if the request was never opened.
    @Test
    func perform_deny_notOpened() async {
        await subject.perform(.deny(reason: nil))

        #expect(!agentFillApprovalRepository.answerCalled)
    }

    /// `receive(_:)` with `.dismiss` dismisses the screen.
    @Test
    func receive_dismiss() {
        subject.receive(.dismiss)

        #expect(coordinator.routes.last == .dismiss())
    }

    /// `receive(_:)` with `.itemSelected` selects the item.
    @Test
    func receive_itemSelected() {
        subject.receive(.itemSelected("cipher-2"))

        #expect(subject.state.selectedItemId == "cipher-2")
    }

    // MARK: Private

    /// Loads a pending request with two items and selects one.
    ///
    /// - Parameter selectedItemId: The ID of the item to select, if any.
    ///
    private func loadPendingRequest(selecting selectedItemId: String?) async throws {
        agentFillApprovalRepository.openReturnValue = (.fixture(), .fixture())
        agentFillApprovalRepository.fetchApprovableCiphersReturnValue = [
            .fixture(id: "cipher-1", name: "Delta"),
            .fixture(id: "cipher-2", name: "Delta work"),
        ]
        await subject.perform(.loadData)
        try #require(subject.state.status == .pending)
        if let selectedItemId {
            subject.receive(.itemSelected(selectedItemId))
        }
    }
}

// MARK: - MockAgentFillApprovalDelegate

class MockAgentFillApprovalDelegate: AgentFillApprovalDelegate {
    var answeredApproved: Bool?

    func agentFillApprovalAnswered(approved: Bool) {
        answeredApproved = approved
    }
}
