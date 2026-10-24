// swiftlint:disable file_length

import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AgentAccessApprovalProcessorTests

@MainActor
struct AgentAccessApprovalProcessorTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let agentAccessRepository: MockAgentAccessRepository
    let authRepository: MockAuthRepository
    let biometricsService: MockBiometricsService
    let coordinator: MockCoordinator<AgentAccessRoute, Void>
    let delegate: MockAgentAccessApprovalDelegate
    let errorReporter: MockErrorReporter
    let subject: AgentAccessApprovalProcessor
    let userVerificationHelper: MockUserVerificationHelper
    let userVerificationHelperFactory: MockUserVerificationHelperFactory

    // MARK: Initialization

    init() {
        agentAccessRepository = MockAgentAccessRepository()
        authRepository = MockAuthRepository()
        biometricsService = MockBiometricsService()
        coordinator = MockCoordinator()
        delegate = MockAgentAccessApprovalDelegate()
        errorReporter = MockErrorReporter()
        userVerificationHelper = MockUserVerificationHelper()
        userVerificationHelperFactory = MockUserVerificationHelperFactory()
        userVerificationHelperFactory.createResult = userVerificationHelper

        biometricsService.getBiometricAuthStatusReturnValue = .authorized(.faceID)

        subject = AgentAccessApprovalProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                agentAccessRepository: agentAccessRepository,
                authRepository: authRepository,
                biometricsService: biometricsService,
                errorReporter: errorReporter,
                userVerificationHelperFactory: userVerificationHelperFactory,
            ),
            state: AgentAccessApprovalState(requestId: "request-1"),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.approve` verifies the user with biometrics and approves the login.
    @Test
    func perform_approve_biometrics() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.evaluateBiometricPolicyReasonReturnValue = true

        await subject.perform(.approve)

        #expect(
            biometricsService.evaluateBiometricPolicyReasonReceivedReason
                == Localizations.agentAccessBiometricPrompt,
        )
        #expect(agentAccessRepository.answerReceivedArguments?.requestId == "request-1")
        #expect(
            agentAccessRepository.answerReceivedArguments?.decision
                == .approve(cipherId: "cipher-1", autoApproveMinutes: nil),
        )
        #expect(authRepository.validatePasswordPasswords.isEmpty)
        #expect(coordinator.alertShown.isEmpty)
        #expect(!coordinator.isLoadingOverlayShowing)
        guard case let .dismiss(action) = coordinator.routes.last else {
            Issue.record("The view wasn't dismissed.")
            return
        }
        action?.action()
        #expect(delegate.answeredApproved == true)
        #expect(delegate.dismissedCount == 1)
    }

    /// `perform(_:)` with `.approve` verifies an account without a master password with the device
    /// passcode or biometrics and approves the login.
    @Test
    func perform_approve_noMasterPassword() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        authRepository.canVerifyMasterPasswordResult = .success(false)
        userVerificationHelper.verifyDeviceLocalAuthResult = .success(.verified)

        await subject.perform(.approve)

        #expect(userVerificationHelper.verifyDeviceLocalAuthCalled)
        #expect(userVerificationHelper.verifyDeviceLocalAuthBecauseValue == Localizations.agentAccessBiometricPrompt)
        #expect(!biometricsService.evaluateBiometricPolicyReasonCalled)
        #expect(
            agentAccessRepository.answerReceivedArguments?.decision
                == .approve(cipherId: "cipher-1", autoApproveMinutes: nil),
        )
        #expect(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.approve` doesn't approve when the device verification fails.
    @Test
    func perform_approve_noMasterPassword_notVerified() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        authRepository.canVerifyMasterPasswordResult = .success(false)
        userVerificationHelper.verifyDeviceLocalAuthResult = .success(.notVerified)

        await subject.perform(.approve)

        #expect(!agentAccessRepository.answerCalled)
        #expect(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.approve` doesn't approve when the user cancels the device verification.
    @Test
    func perform_approve_noMasterPassword_cancelled() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        authRepository.canVerifyMasterPasswordResult = .success(false)
        userVerificationHelper.verifyDeviceLocalAuthResult = .failure(UserVerificationError.cancelled)

        await subject.perform(.approve)

        #expect(!agentAccessRepository.answerCalled)
        #expect(coordinator.alertShown.isEmpty)
        #expect(coordinator.errorAlertsShown.isEmpty)
    }

    /// `perform(_:)` with `.approve` explains when the device has no passcode to verify with.
    @Test
    func perform_approve_noMasterPassword_unableToPerform() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        authRepository.canVerifyMasterPasswordResult = .success(false)
        userVerificationHelper.verifyDeviceLocalAuthResult = .success(.unableToPerform)

        await subject.perform(.approve)

        #expect(!agentAccessRepository.answerCalled)
        #expect(coordinator.alertShown.last == .defaultAlert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.agentAccessVerificationUnavailable,
        ))
    }

    /// `perform(_:)` with `.approve` shows an error when the device verification throws.
    @Test
    func perform_approve_noMasterPassword_error() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        authRepository.canVerifyMasterPasswordResult = .success(false)
        userVerificationHelper.verifyDeviceLocalAuthResult = .failure(BitwardenTestError.example)

        await subject.perform(.approve)

        #expect(!agentAccessRepository.answerCalled)
        #expect(coordinator.errorAlertsShown.last as? BitwardenTestError == .example)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `perform(_:)` with `.approve` still tries biometrics when the master password check fails.
    @Test
    func perform_approve_canVerifyMasterPasswordThrows() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        authRepository.canVerifyMasterPasswordResult = .failure(BitwardenTestError.example)
        biometricsService.evaluateBiometricPolicyReasonReturnValue = true

        await subject.perform(.approve)

        #expect(!userVerificationHelper.verifyDeviceLocalAuthCalled)
        #expect(agentAccessRepository.answerCalled)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `perform(_:)` with `.approve` remembers the approval for the chosen time.
    @Test
    func perform_approve_autoApprove() async throws {
        try await loadPendingRequest(selecting: "cipher-2")
        biometricsService.evaluateBiometricPolicyReasonReturnValue = true
        subject.receive(.autoApproveToggled(true))
        subject.receive(.autoApproveMinutesChanged(30))

        await subject.perform(.approve)

        #expect(
            agentAccessRepository.answerReceivedArguments?.decision
                == .approve(cipherId: "cipher-2", autoApproveMinutes: 30),
        )
    }

    /// `perform(_:)` with `.approve` doesn't remember the approval when the toggle is off.
    @Test
    func perform_approve_autoApproveOff() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.evaluateBiometricPolicyReasonReturnValue = true
        subject.receive(.autoApproveMinutesChanged(30))

        await subject.perform(.approve)

        #expect(
            agentAccessRepository.answerReceivedArguments?.decision
                == .approve(cipherId: "cipher-1", autoApproveMinutes: nil),
        )
    }

    /// `perform(_:)` with `.approve` offers the master password when the biometric prompt throws.
    @Test
    func perform_approve_biometricsThrows_masterPassword() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.evaluateBiometricPolicyReasonThrowableError = BitwardenTestError.example

        await subject.perform(.approve)

        #expect(!agentAccessRepository.answerCalled)
        let alert = try #require(coordinator.alertShown.last)
        #expect(alert == .masterPasswordPrompt { _ in })
    }

    /// `perform(_:)` with `.approve` offers the master password when biometrics fail.
    @Test
    func perform_approve_biometricsFailed_masterPassword() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.evaluateBiometricPolicyReasonReturnValue = false
        authRepository.validatePasswordResult = .success(true)

        await subject.perform(.approve)

        #expect(!agentAccessRepository.answerCalled)
        let alert = try #require(coordinator.alertShown.last)
        #expect(alert == .masterPasswordPrompt { _ in })

        let submitAction = try #require(alert.alertActions.first { $0.title == Localizations.submit })
        await submitAction.handler?(submitAction, [AlertTextField(id: "password", text: "password")])

        #expect(authRepository.validatePasswordPasswords == ["password"])
        #expect(
            agentAccessRepository.answerReceivedArguments?.decision
                == .approve(cipherId: "cipher-1", autoApproveMinutes: nil),
        )
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
        #expect(!agentAccessRepository.answerCalled)
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
        #expect(!agentAccessRepository.answerCalled)
    }

    /// `perform(_:)` with `.approve` doesn't do anything if no login is selected.
    @Test
    func perform_approve_noSelection() async throws {
        try await loadPendingRequest(selecting: nil)

        await subject.perform(.approve)

        #expect(!biometricsService.evaluateBiometricPolicyReasonCalled)
        #expect(coordinator.alertShown.isEmpty)
        #expect(!agentAccessRepository.answerCalled)
    }

    /// `perform(_:)` with `.approve` shows the expired state if the request ran out of time.
    @Test
    func perform_approve_expired() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.evaluateBiometricPolicyReasonReturnValue = true
        agentAccessRepository.answerThrowableError = AgentAccessError.requestExpired

        await subject.perform(.approve)

        #expect(subject.state.status == .expired)
        #expect(!subject.state.canApprove)
        #expect(!coordinator.isLoadingOverlayShowing)
        #expect(coordinator.routes.isEmpty)
    }

    /// `perform(_:)` with `.approve` shows an error alert if answering fails.
    @Test
    func perform_approve_error() async throws {
        try await loadPendingRequest(selecting: "cipher-1")
        biometricsService.evaluateBiometricPolicyReasonReturnValue = true
        agentAccessRepository.answerThrowableError = AgentAccessError.cipherNotFound

        await subject.perform(.approve)

        #expect(coordinator.errorAlertsShown.last as? AgentAccessError == .cipherNotFound)
        #expect(errorReporter.errors.last as? AgentAccessError == .cipherNotFound)
        #expect(subject.state.status == .pending)
        #expect(!coordinator.isLoadingOverlayShowing)
    }

    /// `perform(_:)` with `.deny` denies the request without verifying the user.
    @Test
    func perform_deny() async throws {
        try await loadPendingRequest(selecting: nil)

        await subject.perform(.deny)

        #expect(agentAccessRepository.answerReceivedArguments?.requestId == "request-1")
        #expect(agentAccessRepository.answerReceivedArguments?.decision == .deny)
        #expect(!biometricsService.evaluateBiometricPolicyReasonCalled)
        guard case let .dismiss(action) = coordinator.routes.last else {
            Issue.record("The view wasn't dismissed.")
            return
        }
        action?.action()
        #expect(delegate.answeredApproved == false)
        #expect(delegate.dismissedCount == 1)
    }

    /// `perform(_:)` with `.loadData` shows the request and the logins to choose from.
    @Test
    func perform_loadData() async {
        agentAccessRepository.pendingRequestReturnValue = AgentAccessUIFixtures.approvalRequest(
            connectionName: "Codex",
            query: .domain("example.com"),
        )
        agentAccessRepository.candidatesReturnValue = [
            AgentAccessUIFixtures.candidate(id: "cipher-1"),
            AgentAccessUIFixtures.candidate(id: "cipher-2", name: "Example work"),
        ]

        await subject.perform(.loadData)

        #expect(agentAccessRepository.pendingRequestReceivedId == "request-1")
        #expect(agentAccessRepository.candidatesReceivedRequestId == "request-1")
        #expect(subject.state.status == .pending)
        #expect(subject.state.connectionName == "Codex")
        #expect(subject.state.connectionFingerprint == AgentAccessUIFixtures.fingerprint)
        #expect(subject.state.fingerprintPrefix == "abababab")
        #expect(subject.state.query == .domain("example.com"))
        #expect(subject.state.candidates.count == 2)
        #expect(subject.state.selectedCipherId == nil)
        #expect(!subject.state.canApprove)
        #expect(subject.state.descriptionText == Localizations.agentAccessApproveDescription("Codex", "example.com"))
    }

    /// `perform(_:)` with `.loadData` preselects the only login.
    @Test
    func perform_loadData_singleCandidate() async {
        agentAccessRepository.pendingRequestReturnValue = AgentAccessUIFixtures.approvalRequest()
        agentAccessRepository.candidatesReturnValue = [AgentAccessUIFixtures.candidate(id: "cipher-1")]

        await subject.perform(.loadData)

        #expect(subject.state.selectedCipherId == "cipher-1")
        #expect(subject.state.canApprove)
    }

    /// `perform(_:)` with `.loadData` stays pending without logins so the user can deny.
    @Test
    func perform_loadData_noCandidates() async {
        agentAccessRepository.pendingRequestReturnValue = AgentAccessUIFixtures.approvalRequest()
        agentAccessRepository.candidatesReturnValue = []

        await subject.perform(.loadData)

        #expect(subject.state.status == .pending)
        #expect(subject.state.candidates.isEmpty)
        #expect(!subject.state.canApprove)
    }

    /// `perform(_:)` with `.loadData` shows the expired state when the request is gone.
    @Test
    func perform_loadData_requestNotFound() async {
        agentAccessRepository.pendingRequestReturnValue = nil

        await subject.perform(.loadData)

        #expect(subject.state.status == .expired)
        #expect(!agentAccessRepository.candidatesCalled)
    }

    /// `perform(_:)` with `.loadData` shows the expired state for a request past its expiration.
    @Test
    func perform_loadData_expired() async {
        agentAccessRepository.pendingRequestReturnValue = AgentAccessUIFixtures.approvalRequest(
            expiresAt: Date.now.addingTimeInterval(-1),
        )

        await subject.perform(.loadData)

        #expect(subject.state.status == .expired)
        #expect(!agentAccessRepository.candidatesCalled)
    }

    /// `perform(_:)` with `.loadData` shows an error and offers no approval if the logins can't be loaded.
    @Test
    func perform_loadData_candidatesError() async {
        agentAccessRepository.pendingRequestReturnValue = AgentAccessUIFixtures.approvalRequest()
        agentAccessRepository.candidatesThrowableError = BitwardenTestError.example

        await subject.perform(.loadData)

        #expect(subject.state.status == .failed)
        #expect(!subject.state.canApprove)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `perform(_:)` with `.streamCountdown` shows the expired state once the time is up.
    @Test
    func perform_streamCountdown_expires() async {
        subject.state.status = .pending
        subject.state.expiresAt = Date.now.addingTimeInterval(-1)

        await subject.perform(.streamCountdown)

        #expect(subject.state.secondsRemaining == 0)
        #expect(subject.state.status == .expired)
    }

    /// `perform(_:)` with `.streamCountdown` publishes the seconds left while the request is pending.
    @Test
    func perform_streamCountdown_secondsRemaining() async {
        subject.state.status = .pending
        subject.state.expiresAt = Date.now.addingTimeInterval(60)

        let task = Task { await subject.perform(.streamCountdown) }
        while subject.state.secondsRemaining == nil {
            await Task.yield()
        }
        task.cancel()
        await task.value

        let seconds = subject.state.secondsRemaining ?? 0
        #expect(seconds > 0 && seconds <= 60)
        #expect(subject.state.status == .pending)
    }

    /// `perform(_:)` with `.streamCountdown` does nothing when the request isn't pending.
    @Test
    func perform_streamCountdown_notPending() async {
        subject.state.status = .loading
        subject.state.expiresAt = Date.now.addingTimeInterval(60)

        await subject.perform(.streamCountdown)

        #expect(subject.state.secondsRemaining == nil)
    }

    /// `receive(_:)` with `.autoApproveMinutesChanged` updates the duration.
    @Test
    func receive_autoApproveMinutesChanged() {
        subject.receive(.autoApproveMinutesChanged(60))

        #expect(subject.state.autoApproveMinutes == 60)
    }

    /// `receive(_:)` with `.autoApproveToggled` updates the toggle.
    @Test
    func receive_autoApproveToggled() {
        #expect(!subject.state.isAutoApproveOn)
        #expect(subject.state.autoApproveMinutes == AgentAccessConstants.defaultAutoApproveMinutes)

        subject.receive(.autoApproveToggled(true))

        #expect(subject.state.isAutoApproveOn)
    }

    /// `receive(_:)` with `.dismiss` denies a pending request before closing the screen.
    @Test
    func receive_dismiss_pending() async throws {
        try await loadPendingRequest(selecting: nil)

        subject.receive(.dismiss)
        while !agentAccessRepository.answerCalled {
            await Task.yield()
        }

        #expect(agentAccessRepository.answerReceivedArguments?.decision == .deny)
    }

    /// `receive(_:)` with `.dismiss` closes the screen and notifies the delegate when nothing is pending.
    @Test
    func receive_dismiss_notPending() {
        subject.state.status = .expired

        subject.receive(.dismiss)

        guard case let .dismiss(action) = coordinator.routes.last else {
            Issue.record("The view wasn't dismissed.")
            return
        }
        action?.action()
        #expect(delegate.dismissedCount == 1)
        #expect(!agentAccessRepository.answerCalled)
    }

    /// `receive(_:)` with `.itemSelected` selects the login.
    @Test
    func receive_itemSelected() {
        subject.receive(.itemSelected("cipher-2"))

        #expect(subject.state.selectedCipherId == "cipher-2")
    }

    /// The remember durations come from the contract constants.
    @Test
    func autoApproveDuration_all() {
        #expect(AgentAccessAutoApproveDuration.all.map(\.minutes) == AgentAccessConstants.autoApproveDurationsMinutes)
        #expect(
            AgentAccessAutoApproveDuration(minutes: 5).localizedName == Localizations.agentAccessAutoApproveMinutes(5),
        )
    }

    // MARK: Private

    /// Loads a pending request with two logins and selects one.
    ///
    /// - Parameter selectedCipherId: The ID of the login to select, if any.
    ///
    private func loadPendingRequest(selecting selectedCipherId: String?) async throws {
        agentAccessRepository.pendingRequestReturnValue = AgentAccessUIFixtures.approvalRequest()
        agentAccessRepository.candidatesReturnValue = [
            AgentAccessUIFixtures.candidate(id: "cipher-1"),
            AgentAccessUIFixtures.candidate(id: "cipher-2", name: "Example work"),
        ]
        await subject.perform(.loadData)
        try #require(subject.state.status == .pending)
        if let selectedCipherId {
            subject.receive(.itemSelected(selectedCipherId))
        }
    }
}

// MARK: - MockAgentAccessApprovalDelegate

class MockAgentAccessApprovalDelegate: AgentAccessApprovalDelegate {
    var answeredApproved: Bool?
    var dismissedCount = 0

    func agentAccessApprovalAnswered(approved: Bool) {
        answeredApproved = approved
    }

    func agentAccessApprovalDismissed() {
        dismissedCount += 1
    }
}
