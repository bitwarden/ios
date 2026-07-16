import AuthenticationServices
import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - UsePasskeyProcessorTests

/// Tests for `UsePasskeyProcessor`.
///
@available(iOS 17, *)
class UsePasskeyProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<RootRoute, Void>!
    var credentialStore: MockPasskeyCredentialStore!
    var delegate: MockUsePasskeyProcessorDelegate!
    var subject: UsePasskeyProcessor!

    // MARK: Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        credentialStore = MockPasskeyCredentialStore()
        delegate = MockUsePasskeyProcessorDelegate()
        subject = UsePasskeyProcessor(
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

    /// `receive(.helpSheetPresentedChanged)` updates whether the help sheet is presented in state.
    @MainActor
    func test_receive_helpSheetPresentedChanged() {
        subject.receive(.helpSheetPresentedChanged(true))
        XCTAssertTrue(subject.state.isHelpSheetPresented)

        subject.receive(.helpSheetPresentedChanged(false))
        XCTAssertFalse(subject.state.isHelpSheetPresented)
    }

    /// `receive(.rpIdChanged)` updates the RP ID in state.
    @MainActor
    func test_receive_rpIdChanged() {
        subject.receive(.rpIdChanged("bitwarden.com"))
        XCTAssertEqual(subject.state.rpId, "bitwarden.com")
    }

    // MARK: Effect Tests

    /// `perform(.assertPasskey)` sets status to `.success` with the verified credential when
    /// assertion succeeds.
    @MainActor
    func test_perform_assertPasskey_success() async {
        let subject = UsePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            performAssertion: { _, _, _ in .fixture() },
            credentialStore: credentialStore,
        )
        await subject.perform(.assertPasskey)
        XCTAssertEqual(subject.state.status, .success(credential: .fixture()))
    }

    /// `perform(.assertPasskey)` sets status to `.failure` when assertion throws.
    @MainActor
    func test_perform_assertPasskey_failure() async {
        let testError = BitwardenTestError.example
        let subject = UsePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            performAssertion: { _, _, _ in throw testError },
            credentialStore: credentialStore,
        )
        await subject.perform(.assertPasskey)
        XCTAssertEqual(subject.state.status, .failure(testError.localizedDescription))
    }

    /// `perform(.assertPasskey)` resets status to `.idle` when the user cancels.
    @MainActor
    func test_perform_assertPasskey_canceledResetsToIdle() async {
        let subject = UsePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            performAssertion: { _, _, _ in throw ASAuthorizationError(.canceled) },
            credentialStore: credentialStore,
        )
        await subject.perform(.assertPasskey)
        XCTAssertEqual(subject.state.status, .idle)
    }

    /// `perform(.assertPasskey)` sets status to `.verificationFailure` when the authenticator
    /// returns an assertion but it fails local verification, rather than reporting the whole
    /// operation as `.failure`.
    @MainActor
    func test_perform_assertPasskey_verificationFailureSetsVerificationFailureStatus() async {
        let subject = UsePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            performAssertion: { _, _, _ in throw PasskeyAssertionVerifier.VerificationError.signatureInvalid },
            credentialStore: credentialStore,
        )
        await subject.perform(.assertPasskey)
        XCTAssertEqual(
            subject.state.status,
            .verificationFailure(PasskeyAssertionVerifier.VerificationError.signatureInvalid.localizedDescription),
        )
    }

    /// `perform(.assertPasskey)` passes the current RP ID to the assertion closure.
    @MainActor
    func test_perform_assertPasskey_passesRpId() async {
        var capturedRpId: String?
        let subject = UsePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            performAssertion: { rpId, _, _ in
                capturedRpId = rpId
                return .fixture(rpId: rpId)
            },
            credentialStore: credentialStore,
        )

        subject.receive(.rpIdChanged("example.com"))
        await subject.perform(.assertPasskey)

        XCTAssertEqual(capturedRpId, "example.com")
    }

    /// `perform(.assertPasskey)` passes only the stored credentials matching the current RP ID to
    /// the assertion closure.
    @MainActor
    func test_perform_assertPasskey_filtersStoredCredentialsByRpId() async {
        let matching = StoredPasskeyCredential.fixture(rpId: "example.com")
        let nonMatching = StoredPasskeyCredential.fixture(rpId: "other.com")
        credentialStore.fetchAllResult = [matching, nonMatching]

        var capturedCredentials: [StoredPasskeyCredential]?
        let subject = UsePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            performAssertion: { _, allowedCredentials, _ in
                capturedCredentials = allowedCredentials
                return matching
            },
            credentialStore: credentialStore,
        )

        subject.receive(.rpIdChanged("example.com"))
        await subject.perform(.assertPasskey)

        XCTAssertEqual(capturedCredentials, [matching])
    }
}

// MARK: - MockUsePasskeyProcessorDelegate

class MockUsePasskeyProcessorDelegate: UsePasskeyProcessorDelegate {
    var presentationAnchorCalled = false
    var presentationAnchorResult: ASPresentationAnchor = UIWindow()

    func presentationAnchorForPasskeyAssertion() async -> ASPresentationAnchor {
        presentationAnchorCalled = true
        return presentationAnchorResult
    }
}

// MARK: - StoredPasskeyCredential+Fixtures

private extension StoredPasskeyCredential {
    static func fixture(
        rpId: String = "bitwarden.com",
        userName: String = "user",
        displayName: String = "User",
        credentialId: Data = Data([0x01, 0x02, 0x03]),
        publicKeyX963: Data = Data(repeating: 0x04, count: 65),
        createdAt: Date = Date(timeIntervalSince1970: 0),
    ) -> StoredPasskeyCredential {
        StoredPasskeyCredential(
            createdAt: createdAt,
            credentialId: credentialId,
            displayName: displayName,
            publicKeyX963: publicKeyX963,
            rpId: rpId,
            userName: userName,
        )
    }
}
