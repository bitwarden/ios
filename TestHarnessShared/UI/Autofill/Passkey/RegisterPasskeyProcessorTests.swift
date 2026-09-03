import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - RegisterPasskeyProcessorTests

/// Tests for `RegisterPasskeyProcessor`.
///
class RegisterPasskeyProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<RootRoute, Void>!
    var passkeyService: MockPasskeyService!
    var subject: RegisterPasskeyProcessor!

    // MARK: Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        passkeyService = MockPasskeyService()
        subject = RegisterPasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            passkeyService: passkeyService,
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        passkeyService = nil
        subject = nil
    }

    // MARK: Action Tests

    /// `receive(.displayNameChanged)` updates the display name in state.
    @MainActor
    func test_receive_displayNameChanged() {
        subject.receive(.displayNameChanged("Test User"))
        XCTAssertEqual(subject.state.displayName, "Test User")
    }

    /// `receive(.rpIdChanged)` updates the RP ID in state.
    @MainActor
    func test_receive_rpIdChanged() {
        subject.receive(.rpIdChanged("bitwarden.com"))
        XCTAssertEqual(subject.state.rpId, "bitwarden.com")
    }

    /// `receive(.userNameChanged)` updates the username in state.
    @MainActor
    func test_receive_userNameChanged() {
        subject.receive(.userNameChanged("testuser"))
        XCTAssertEqual(subject.state.userName, "testuser")
    }

    // MARK: Effect Tests

    /// `perform(.registerPasskey)` passes the current state values to the SDK passkey service.
    @MainActor
    func test_perform_registerPasskey_passesStateValues() async {
        subject.receive(.rpIdChanged("example.com"))
        subject.receive(.userNameChanged("alice"))
        subject.receive(.displayNameChanged("Alice Smith"))
        passkeyService.registerPasskeyReturnValue = .fixture()

        await subject.perform(.registerPasskey)

        XCTAssertEqual(
            passkeyService.registerPasskeyReceivedArguments?.rpId,
            "example.com",
        )
        XCTAssertEqual(
            passkeyService.registerPasskeyReceivedArguments?.userName,
            "alice",
        )
        XCTAssertEqual(
            passkeyService.registerPasskeyReceivedArguments?.displayName,
            "Alice Smith",
        )
    }

    /// `perform(.registerPasskey)` sets status to `.failure` when registration throws.
    @MainActor
    func test_perform_registerPasskey_failure() async {
        passkeyService.registerPasskeyThrowableError = BitwardenTestError.example

        await subject.perform(.registerPasskey)

        XCTAssertEqual(subject.state.status, .failure(BitwardenTestError.example.localizedDescription))
    }

    /// `perform(.registerPasskey)` sets status to `.success` with the resulting credential ID
    /// when registration succeeds.
    @MainActor
    func test_perform_registerPasskey_success() async {
        passkeyService.registerPasskeyReturnValue = .fixture(credentialId: Data([0x01, 0x02, 0x03]))

        await subject.perform(.registerPasskey)

        XCTAssertEqual(subject.state.status, .success(credentialId: Data([0x01, 0x02, 0x03]).base64EncodedString()))
    }
}
