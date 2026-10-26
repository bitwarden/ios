import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Combine
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AgentAccessPairingProcessorTests

@MainActor
struct AgentAccessPairingProcessorTests {
    // MARK: Properties

    let agentAccessRepository: MockAgentAccessRepository
    let coordinator: MockCoordinator<AgentAccessRoute, Void>
    let errorReporter: MockErrorReporter
    let pasteboardService: MockPasteboardService
    let subject: AgentAccessPairingProcessor

    // MARK: Initialization

    init() {
        agentAccessRepository = MockAgentAccessRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()

        subject = AgentAccessPairingProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            pairedDismissDelay: 0,
            services: ServiceContainer.withMocks(
                agentAccessRepository: agentAccessRepository,
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
            ),
            state: AgentAccessPairingState(),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.startPairing` creates a token with the trimmed name.
    @Test
    func perform_startPairing_token() async {
        subject.state.connectionName = "  Codex  "
        agentAccessRepository.createPairingReturnValue = AgentAccessUIFixtures.pairing(kind: .psk, token: "abc")

        await subject.perform(.startPairing)

        #expect(agentAccessRepository.createPairingReceivedArguments?.kind == .psk)
        #expect(agentAccessRepository.createPairingReceivedArguments?.name == "Codex")
        #expect(subject.state.pairing?.token == "abc")
        #expect(subject.state.phase == .waiting)
        #expect(!coordinator.isLoadingOverlayShowing)
    }

    /// `perform(_:)` with `.startPairing` creates a code when the code mode is selected.
    @Test
    func perform_startPairing_code() async {
        subject.state.mode = .code
        agentAccessRepository.createPairingReturnValue = AgentAccessUIFixtures.pairing(
            kind: .rendezvous,
            token: "ABC-DEF-GHI",
        )

        await subject.perform(.startPairing)

        #expect(agentAccessRepository.createPairingReceivedArguments?.kind == .rendezvous)
        #expect(subject.state.pairing?.token == "ABC-DEF-GHI")
        #expect(subject.state.exampleCommand == nil)
    }

    /// `perform(_:)` with `.startPairing` does nothing when the name is empty.
    @Test
    func perform_startPairing_emptyName() async {
        subject.state.connectionName = "   "

        await subject.perform(.startPairing)

        #expect(!agentAccessRepository.createPairingCalled)
        #expect(subject.state.phase == .form)
    }

    /// `perform(_:)` with `.startPairing` shows the failed state if the pairing can't be created.
    @Test
    func perform_startPairing_error() async {
        agentAccessRepository.createPairingThrowableError = BitwardenTestError.example

        await subject.perform(.startPairing)

        #expect(subject.state.phase == .failed(message: ""))
        #expect(subject.state.pairing == nil)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `perform(_:)` with `.streamEvents` does nothing before a pairing exists.
    @Test
    func perform_streamEvents_noPairing() async {
        await subject.perform(.streamEvents)

        #expect(!agentAccessRepository.pairingEventsPublisherCalled)
    }

    /// `perform(_:)` with `.streamEvents` follows the events of a rendezvous pairing to the end.
    @Test
    func perform_streamEvents_paired() async {
        let connection = AgentAccessUIFixtures.connection()
        let verification = AgentAccessFingerprintVerification(
            id: "verification-1",
            code: "a1b2c3",
            remoteFingerprint: AgentAccessUIFixtures.fingerprint,
        )
        subject.state.pairing = AgentAccessUIFixtures.pairing(kind: .rendezvous, token: "ABC-DEF-GHI")
        agentAccessRepository.pairingEventsPublisherReturnValue = [
            AgentAccessPairingEvent.waitingForAgent,
            .verifyFingerprint(verification),
            .paired(connection),
        ].publisher.eraseToAnyPublisher()

        await subject.perform(.streamEvents)

        #expect(subject.state.phase == .paired(connection))
        #expect(coordinator.routes.last == .back)
    }

    /// `perform(_:)` with `.streamEvents` shows the verification step.
    @Test
    func perform_streamEvents_verifyFingerprint() async {
        let verification = AgentAccessFingerprintVerification(
            id: "verification-1",
            code: "a1b2c3",
            remoteFingerprint: AgentAccessUIFixtures.fingerprint,
        )
        subject.state.pairing = AgentAccessUIFixtures.pairing(kind: .rendezvous, token: "ABC-DEF-GHI")
        agentAccessRepository.pairingEventsPublisherReturnValue = Just(
            AgentAccessPairingEvent.verifyFingerprint(verification),
        )
        .eraseToAnyPublisher()

        await subject.perform(.streamEvents)

        #expect(subject.state.phase == .verifying(verification))
    }

    /// `perform(_:)` with `.streamEvents` shows the rejected state.
    @Test
    func perform_streamEvents_rejected() async {
        subject.state.pairing = AgentAccessUIFixtures.pairing()
        agentAccessRepository.pairingEventsPublisherReturnValue = Just(AgentAccessPairingEvent.rejected)
            .eraseToAnyPublisher()

        await subject.perform(.streamEvents)

        #expect(subject.state.phase == .rejected)
    }

    /// `perform(_:)` with `.streamEvents` shows the failed state with the message.
    @Test
    func perform_streamEvents_failed() async {
        subject.state.pairing = AgentAccessUIFixtures.pairing()
        agentAccessRepository.pairingEventsPublisherReturnValue = Just(
            AgentAccessPairingEvent.failed(message: "Timed out"),
        )
        .eraseToAnyPublisher()

        await subject.perform(.streamEvents)

        #expect(subject.state.phase == .failed(message: "Timed out"))
    }

    /// `receive(_:)` with `.confirmFingerprint` tells the repository the codes match.
    @Test
    func receive_confirmFingerprint() {
        let verification = AgentAccessFingerprintVerification(
            id: "verification-1",
            code: "a1b2c3",
            remoteFingerprint: AgentAccessUIFixtures.fingerprint,
        )
        subject.state.phase = .verifying(verification)

        subject.receive(.confirmFingerprint)

        #expect(agentAccessRepository.answerFingerprintVerificationReceivedArguments?.id == "verification-1")
        #expect(agentAccessRepository.answerFingerprintVerificationReceivedArguments?.approved == true)
        #expect(subject.state.phase == .waiting)
    }

    /// `receive(_:)` with `.confirmFingerprint` does nothing when no comparison is pending.
    @Test
    func receive_confirmFingerprint_notVerifying() {
        subject.receive(.confirmFingerprint)

        #expect(!agentAccessRepository.answerFingerprintVerificationCalled)
    }

    /// `receive(_:)` with `.connectionNameChanged` updates the name.
    @Test
    func receive_connectionNameChanged() {
        subject.receive(.connectionNameChanged("Claude"))

        #expect(subject.state.connectionName == "Claude")
    }

    /// `receive(_:)` with `.copyToken` copies the token and shows a toast.
    @Test
    func receive_copyToken() {
        subject.state.pairing = AgentAccessUIFixtures.pairing(token: "abc")

        subject.receive(.copyToken)

        #expect(pasteboardService.copiedString == "abc")
        #expect(subject.state.toast == Toast(title: Localizations.valueHasBeenCopied(Localizations.agentAccessToken)))
    }

    /// `receive(_:)` with `.modeChanged` updates the mode.
    @Test
    func receive_modeChanged() {
        subject.receive(.modeChanged(.code))

        #expect(subject.state.mode == .code)
        #expect(subject.state.mode.kind == .rendezvous)
    }

    /// `receive(_:)` with `.rejectFingerprint` tells the repository the codes don't match.
    @Test
    func receive_rejectFingerprint() {
        let verification = AgentAccessFingerprintVerification(
            id: "verification-1",
            code: "a1b2c3",
            remoteFingerprint: AgentAccessUIFixtures.fingerprint,
        )
        subject.state.phase = .verifying(verification)

        subject.receive(.rejectFingerprint)

        #expect(agentAccessRepository.answerFingerprintVerificationReceivedArguments?.approved == false)
    }

    /// `receive(_:)` with `.shareToken` navigates to the share sheet with the token.
    @Test
    func receive_shareToken() {
        subject.state.pairing = AgentAccessUIFixtures.pairing(token: "abc")

        subject.receive(.shareToken)

        #expect(coordinator.routes.last == .share(text: "abc"))
    }

    /// `receive(_:)` with `.toastShown` updates the toast.
    @Test
    func receive_toastShown() {
        let toast = Toast(title: "Toast")

        subject.receive(.toastShown(toast))
        #expect(subject.state.toast == toast)

        subject.receive(.toastShown(nil))
        #expect(subject.state.toast == nil)
    }

    /// `receive(_:)` with `.tryAgain` returns to the form.
    @Test
    func receive_tryAgain() {
        subject.state.pairing = AgentAccessUIFixtures.pairing()
        subject.state.phase = .rejected

        subject.receive(.tryAgain)

        #expect(subject.state.pairing == nil)
        #expect(subject.state.phase == .form)
    }

    /// `AgentAccessPairingState.exampleCommand` shows the token in a command for a token pairing.
    @Test
    func state_exampleCommand() {
        var state = AgentAccessPairingState()
        #expect(state.exampleCommand == nil)

        state.pairing = AgentAccessUIFixtures.pairing(kind: .psk, token: "abc")
        #expect(state.exampleCommand == "aac connect --token abc --domain example.com")
    }
}
