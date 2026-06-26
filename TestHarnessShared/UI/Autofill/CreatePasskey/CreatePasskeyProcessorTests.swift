import AuthenticationServices
import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - CreatePasskeyProcessorTests

/// Tests for `CreatePasskeyProcessor`.
///
class CreatePasskeyProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<RootRoute, Void>!
    var delegate: MockCreatePasskeyProcessorDelegate!
    var subject: CreatePasskeyProcessor!

    // MARK: Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        delegate = MockCreatePasskeyProcessorDelegate()
        subject = CreatePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            passkeyRegistryService: DefaultPasskeyRegistryService(),
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        delegate = nil
        subject = nil
    }

    // MARK: Action Tests

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

    /// `receive(.displayNameChanged)` updates the display name in state.
    @MainActor
    func test_receive_displayNameChanged() {
        subject.receive(.displayNameChanged("Test User"))
        XCTAssertEqual(subject.state.displayName, "Test User")
    }

    // MARK: Effect Tests

    /// `perform(.registerPasskey)` sets status to `.success` when registration succeeds.
    @MainActor
    func test_perform_registerPasskey_success() async {
        subject.performRegistration = { _, _, _ in }
        await subject.perform(.registerPasskey)
        XCTAssertEqual(subject.state.status, .success)
    }

    /// `perform(.registerPasskey)` sets status to `.failure` when registration throws.
    @MainActor
    func test_perform_registerPasskey_failure() async {
        let testError = BitwardenTestError.example
        subject.performRegistration = { _, _, _ in throw testError }
        await subject.perform(.registerPasskey)
        XCTAssertEqual(subject.state.status, .failure(testError.localizedDescription))
    }

    /// `perform(.registerPasskey)` passes the current state values to the registration closure.
    @MainActor
    func test_perform_registerPasskey_passesStateValues() async {
        subject.receive(.rpIdChanged("example.com"))
        subject.receive(.userNameChanged("alice"))
        subject.receive(.displayNameChanged("Alice Smith"))

        var capturedRpId: String?
        var capturedUserName: String?
        var capturedDisplayName: String?
        subject.performRegistration = { rpId, userName, displayName in
            capturedRpId = rpId
            capturedUserName = userName
            capturedDisplayName = displayName
        }

        await subject.perform(.registerPasskey)

        XCTAssertEqual(capturedRpId, "example.com")
        XCTAssertEqual(capturedUserName, "alice")
        XCTAssertEqual(capturedDisplayName, "Alice Smith")
    }
}

// MARK: - MockCreatePasskeyProcessorDelegate

class MockCreatePasskeyProcessorDelegate: CreatePasskeyProcessorDelegate {
    var presentationAnchorCalled = false
    var presentationAnchorResult: ASPresentationAnchor = UIWindow()

    func presentationAnchorForPasskeyRegistration() async -> ASPresentationAnchor {
        presentationAnchorCalled = true
        return presentationAnchorResult
    }
}
