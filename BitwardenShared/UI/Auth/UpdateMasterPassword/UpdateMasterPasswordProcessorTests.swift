import XCTest

@testable import BitwardenShared

// MARK: - UpdateMasterPasswordProcessorTests

class UpdateMasterPasswordProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var httpClient: MockHTTPClient!
    var coordinator: MockCoordinator<VaultRoute, Void>!
    var subject: UpdateMasterPasswordProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        httpClient = MockHTTPClient()
        let services = ServiceContainer.withMocks(httpClient: httpClient)
        let state = UpdateMasterPasswordState()
        subject = UpdateMasterPasswordProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: state
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        httpClient = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform()` with `.submitPressed` submits the request for updating the master password.
    func test_perform_submitPressed_success() async throws {
        // TODO: BIT-789
    }

    /// `receive(_:)` with `.currentMasterPasswordChanged` updates the state to reflect the changes.
    func test_receive_currentMasterPasswordChanged() {
        subject.state.currentMasterPassword = ""

        subject.receive(.currentMasterPasswordChanged("password"))
        XCTAssertEqual(subject.state.currentMasterPassword, "password")
    }

    /// `receive(_:)` with `.masterPasswordChanged` updates the state to reflect the changes.
    func test_receive_masterPasswordChanged() {
        subject.state.masterPassword = ""

        subject.receive(.masterPasswordChanged("password"))
        XCTAssertEqual(subject.state.masterPassword, "password")
    }

    /// `receive(_:)` with `.masterPasswordRetypeChanged` updates the state to reflect the changes.
    func test_receive_masterPasswordRetypeChanged() {
        subject.state.masterPasswordRetype = ""

        subject.receive(.masterPasswordRetypeChanged("password"))
        XCTAssertEqual(subject.state.masterPasswordRetype, "password")
    }

    /// `receive()` with `.masterPasswordHintChanged` and a value updates the state to reflect the
    /// changes.
    func test_receive_masterPasswordHintChanged() {
        subject.state.masterPasswordHint = ""
        subject.receive(.masterPasswordHintChanged("this is password hint"))

        XCTAssertEqual(subject.state.masterPasswordHint, "this is password hint")
    }

    /// `receive(_:)` with `.revealCurrentMasterPasswordFieldPressed` updates the state to reflect the changes.
    func test_receive_revealCurrentMasterPasswordFieldPressed() {
        subject.state.isCurrentMasterPasswordRevealed = false
        subject.receive(.revealCurrentMasterPasswordFieldPressed(true))
        XCTAssertTrue(subject.state.isCurrentMasterPasswordRevealed)

        subject.receive(.revealCurrentMasterPasswordFieldPressed(false))
        XCTAssertFalse(subject.state.isCurrentMasterPasswordRevealed)
    }

    /// `receive(_:)` with `.revealMasterPasswordFieldPressed` updates the state to reflect the changes.
    func test_receive_revealMasterPasswordFieldPressed() {
        subject.state.isMasterPasswordRevealed = false
        subject.receive(.revealMasterPasswordFieldPressed(true))
        XCTAssertTrue(subject.state.isMasterPasswordRevealed)

        subject.receive(.revealMasterPasswordFieldPressed(false))
        XCTAssertFalse(subject.state.isMasterPasswordRevealed)
    }

    /// `receive(_:)` with `.revealMasterPasswordRetypeFieldPressed` updates the state to reflect the changes.
    func test_receive_revealMasterPasswordRetypeFieldPressed() {
        subject.state.isMasterPasswordRetypeRevealed = false
        subject.receive(.revealMasterPasswordRetypeFieldPressed(true))
        XCTAssertTrue(subject.state.isMasterPasswordRetypeRevealed)

        subject.receive(.revealMasterPasswordRetypeFieldPressed(false))
        XCTAssertFalse(subject.state.isMasterPasswordRetypeRevealed)
    }
}
