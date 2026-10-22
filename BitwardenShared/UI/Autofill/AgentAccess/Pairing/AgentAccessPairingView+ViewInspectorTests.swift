// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - AgentAccessPairingViewTests

class AgentAccessPairingViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AgentAccessPairingState, AgentAccessPairingAction, AgentAccessPairingEffect>!
    var subject: AgentAccessPairingView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AgentAccessPairingState())
        subject = AgentAccessPairingView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Updating the name field dispatches the `.connectionNameChanged` action.
    @MainActor
    func test_connectionNameField_updated() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.agentAccessPairingName)
        try textField.inputBinding().wrappedValue = "Claude"
        XCTAssertEqual(processor.dispatchedActions.last, .connectionNameChanged("Claude"))
    }

    /// Picking the code segment dispatches the `.modeChanged` action.
    @MainActor
    func test_modeSegment_tap() throws {
        guard #unavailable(iOS 26) else {
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }
        let button = try subject.inspect().find(button: Localizations.agentAccessCode)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .modeChanged(.code))
    }

    /// Tapping the start button performs the `.startPairing` effect.
    @MainActor
    func test_startButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.agentAccessStartPairing)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .startPairing)
    }

    /// The start button is disabled when the name is empty.
    @MainActor
    func test_startButton_disabledWithoutName() throws {
        processor.state.connectionName = ""
        let button = try subject.inspect().find(asyncButton: Localizations.agentAccessStartPairing)
        XCTAssertTrue(button.isDisabled())
    }

    /// The token, the example command and the waiting message are shown for a token pairing.
    @MainActor
    func test_token() throws {
        processor.state.pairing = AgentAccessUIFixtures.pairing(kind: .psk, token: "abc")
        processor.state.phase = .waiting

        XCTAssertNoThrow(try subject.inspect().find(text: "abc"))
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessTokenInstructions))
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessWaitingForAgent))
        XCTAssertNoThrow(try subject.inspect().find(text: "aac connect --token abc --domain example.com"))
    }

    /// Tapping the copy button dispatches the `.copyToken` action.
    @MainActor
    func test_copyButton_tap() throws {
        processor.state.pairing = AgentAccessUIFixtures.pairing(kind: .psk, token: "abc")
        processor.state.phase = .waiting

        let button = try subject.inspect().find(button: Localizations.agentAccessCopyToken)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyToken)
    }

    /// Tapping the share button dispatches the `.shareToken` action.
    @MainActor
    func test_shareButton_tap() throws {
        processor.state.pairing = AgentAccessUIFixtures.pairing(kind: .psk, token: "abc")
        processor.state.phase = .waiting

        let button = try subject.inspect().find(button: Localizations.agentAccessShareToken)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .shareToken)
    }

    /// The code and its instructions are shown for a code pairing.
    @MainActor
    func test_code() throws {
        processor.state.mode = .code
        processor.state.pairing = AgentAccessUIFixtures.pairing(kind: .rendezvous, token: "ABC-DEF-GHI")
        processor.state.phase = .waiting

        XCTAssertNoThrow(try subject.inspect().find(text: "ABC-DEF-GHI"))
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessCodeInstructions))
        XCTAssertThrowsError(try subject.inspect().find(button: Localizations.agentAccessCopyToken))
    }

    /// The code to compare is shown with buttons to confirm or reject it.
    @MainActor
    func test_verifying() throws {
        processor.state.phase = .verifying(AgentAccessFingerprintVerification(
            id: "verification-1",
            code: "a1b2c3",
            remoteFingerprint: AgentAccessUIFixtures.fingerprint,
        ))

        XCTAssertNoThrow(try subject.inspect().find(text: "a1b2c3"))
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessCompareFingerprint))

        try subject.inspect().find(button: Localizations.agentAccessConfirm).tap()
        XCTAssertEqual(processor.dispatchedActions.last, .confirmFingerprint)

        try subject.inspect().find(button: Localizations.agentAccessReject).tap()
        XCTAssertEqual(processor.dispatchedActions.last, .rejectFingerprint)
    }

    /// The success message is shown after pairing.
    @MainActor
    func test_paired() throws {
        processor.state.phase = .paired(AgentAccessUIFixtures.connection())

        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessPairedSuccess))
    }

    /// The rejected message is shown with a try again button.
    @MainActor
    func test_rejected() throws {
        processor.state.phase = .rejected

        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessPairingRejected))
        try subject.inspect().find(button: Localizations.tryAgain).tap()
        XCTAssertEqual(processor.dispatchedActions.last, .tryAgain)
    }

    /// The failed message is shown with its detail and a try again button.
    @MainActor
    func test_failed() throws {
        processor.state.phase = .failed(message: "Timed out")

        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessPairingFailed))
        XCTAssertNoThrow(try subject.inspect().find(text: "Timed out"))
        try subject.inspect().find(button: Localizations.tryAgain).tap()
        XCTAssertEqual(processor.dispatchedActions.last, .tryAgain)
    }
}
