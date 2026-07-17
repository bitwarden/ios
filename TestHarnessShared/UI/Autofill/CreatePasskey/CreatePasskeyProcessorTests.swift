import AuthenticationServices
import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - CreatePasskeyProcessorTests

/// Tests for `CreatePasskeyProcessor`.
///
@available(iOS 17, *)
class CreatePasskeyProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<RootRoute, Void>!
    var credentialStore: MockPasskeyCredentialStore!
    var delegate: MockCreatePasskeyProcessorDelegate!
    var subject: CreatePasskeyProcessor!

    // MARK: Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        credentialStore = MockPasskeyCredentialStore()
        delegate = MockCreatePasskeyProcessorDelegate()
        subject = CreatePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            credentialStore: credentialStore,
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        credentialStore = nil
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

    /// `perform(.registerPasskey)` sets status to `.success` and persists the credential when
    /// registration succeeds.
    @MainActor
    func test_perform_registerPasskey_success() async {
        let subject = CreatePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            performRegistration: { _, _, _, _ in .fixture() },
            credentialStore: credentialStore,
        )
        await subject.perform(.registerPasskey)
        XCTAssertEqual(subject.state.status, .success)
        XCTAssertEqual(credentialStore.saveReceivedCredential, .fixture())
    }

    /// `perform(.registerPasskey)` sets status to `.failure` and does not persist a credential
    /// when registration throws.
    @MainActor
    func test_perform_registerPasskey_failure() async {
        let testError = BitwardenTestError.example
        let subject = CreatePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            performRegistration: { _, _, _, _ in throw testError },
            credentialStore: credentialStore,
        )
        await subject.perform(.registerPasskey)
        XCTAssertEqual(subject.state.status, .failure(testError.localizedDescription))
        XCTAssertFalse(credentialStore.saveCalled)
    }

    /// `perform(.registerPasskey)` sets status to `.persistenceFailure` when the credential was
    /// registered but persisting it throws, rather than reporting the whole operation as failed.
    @MainActor
    func test_perform_registerPasskey_credentialStoreSaveThrows() async {
        let testError = BitwardenTestError.example
        credentialStore.saveThrowableError = testError
        let subject = CreatePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            performRegistration: { _, _, _, _ in .fixture() },
            credentialStore: credentialStore,
        )
        await subject.perform(.registerPasskey)
        XCTAssertEqual(
            subject.state.status,
            .persistenceFailure(credential: .fixture(), message: testError.localizedDescription),
        )
    }

    /// `perform(.registerPasskey)` passes the current state values to the registration closure.
    @MainActor
    func test_perform_registerPasskey_passesStateValues() async {
        var capturedRpId: String?
        var capturedUserName: String?
        var capturedDisplayName: String?
        let subject = CreatePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            performRegistration: { rpId, userName, displayName, _ in
                capturedRpId = rpId
                capturedUserName = userName
                capturedDisplayName = displayName
                return .fixture(rpId: rpId, userName: userName, displayName: displayName)
            },
            credentialStore: credentialStore,
        )

        subject.receive(.rpIdChanged("example.com"))
        subject.receive(.userNameChanged("alice"))
        subject.receive(.displayNameChanged("Alice Smith"))

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
