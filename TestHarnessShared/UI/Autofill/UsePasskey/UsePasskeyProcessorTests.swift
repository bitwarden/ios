import AuthenticationServices
import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - UsePasskeyProcessorTests

/// Tests for `UsePasskeyProcessor`.
///
class UsePasskeyProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<RootRoute, Void>!
    var delegate: MockUsePasskeyProcessorDelegate!
    var subject: UsePasskeyProcessor!

    // MARK: Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        delegate = MockUsePasskeyProcessorDelegate()
        subject = UsePasskeyProcessor(coordinator: coordinator.asAnyCoordinator(), delegate: delegate)
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

    // MARK: Effect Tests

    /// `perform(.assertPasskey)` sets status to `.success` when assertion succeeds.
    @MainActor
    func test_perform_assertPasskey_success() async {
        subject.performAssertion = { _ in }
        await subject.perform(.assertPasskey)
        XCTAssertEqual(subject.state.status, .success)
    }

    /// `perform(.assertPasskey)` sets status to `.failure` when assertion throws.
    @MainActor
    func test_perform_assertPasskey_failure() async {
        let testError = BitwardenTestError.example
        subject.performAssertion = { _ in throw testError }
        await subject.perform(.assertPasskey)
        XCTAssertEqual(subject.state.status, .failure(testError.localizedDescription))
    }

    /// `perform(.assertPasskey)` passes the current RP ID to the assertion closure.
    @MainActor
    func test_perform_assertPasskey_passesRpId() async {
        subject.receive(.rpIdChanged("example.com"))

        var capturedRpId: String?
        subject.performAssertion = { rpId in
            capturedRpId = rpId
        }

        await subject.perform(.assertPasskey)

        XCTAssertEqual(capturedRpId, "example.com")
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
