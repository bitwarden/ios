import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - SDKUsePasskeyProcessorTests

/// Tests for `SDKUsePasskeyProcessor`.
///
class SDKUsePasskeyProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<RootRoute, Void>!
    var sdkPasskeyService: MockSDKPasskeyService!
    var subject: SDKUsePasskeyProcessor!

    // MARK: Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        sdkPasskeyService = MockSDKPasskeyService()
        subject = SDKUsePasskeyProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            sdkPasskeyService: sdkPasskeyService,
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        sdkPasskeyService = nil
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

    /// `perform(.assertPasskey)` passes the current RP ID to the SDK passkey service.
    @MainActor
    func test_perform_assertPasskey_passesStateValues() async {
        subject.receive(.rpIdChanged("example.com"))
        sdkPasskeyService.assertPasskeyReturnValue = .fixture()

        await subject.perform(.assertPasskey)

        XCTAssertEqual(sdkPasskeyService.assertPasskeyReceivedRpId, "example.com")
    }

    /// `perform(.assertPasskey)` sets status to `.failure` when assertion throws.
    @MainActor
    func test_perform_assertPasskey_failure() async {
        sdkPasskeyService.assertPasskeyThrowableError = BitwardenTestError.example

        await subject.perform(.assertPasskey)

        XCTAssertEqual(subject.state.status, .failure(BitwardenTestError.example.localizedDescription))
    }

    /// `perform(.assertPasskey)` sets status to `.success` with the matched credential's
    /// username when assertion succeeds.
    @MainActor
    func test_perform_assertPasskey_success() async {
        sdkPasskeyService.assertPasskeyReturnValue = .fixture(
            credentialId: Data([0x01, 0x02, 0x03]),
            selectedCredential: SelectedCredential(cipher: .fixture(), credential: .fixture(userName: "alice")),
        )

        await subject.perform(.assertPasskey)

        XCTAssertEqual(
            subject.state.status,
            .success(credentialId: Data([0x01, 0x02, 0x03]).base64EncodedString(), userName: "alice"),
        )
    }
}
