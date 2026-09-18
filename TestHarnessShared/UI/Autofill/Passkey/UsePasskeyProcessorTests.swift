import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - UsePasskeyProcessorTests

/// Tests for `UsePasskeyProcessor`.
///
class UsePasskeyProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<RootRoute, Void>!
    var passkeyService: MockPasskeyService!
    var subject: UsePasskeyProcessor!

    // MARK: Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        passkeyService = MockPasskeyService()
        subject = UsePasskeyProcessor(
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

    // MARK: Effect Tests

    /// The initial state marks credentials as still loading.
    @MainActor
    func test_state_isLoadingCredentials_initiallyTrue() {
        XCTAssertTrue(subject.state.isLoadingCredentials)
    }

    /// `perform(.loadRegisteredCredentials)` populates the registered credentials list and clears
    /// the loading flag.
    @MainActor
    func test_perform_loadRegisteredCredentials_success() async {
        passkeyService.registeredCredentialsReturnValue = [.fixture(rpId: "bitwarden.com")]

        await subject.perform(.loadRegisteredCredentials)

        XCTAssertEqual(subject.state.registeredCredentials, [.fixture(rpId: "bitwarden.com")])
        XCTAssertFalse(subject.state.isLoadingCredentials)
    }

    /// `perform(.loadRegisteredCredentials)` sets status to `.failure` when loading throws, and
    /// clears the loading flag.
    @MainActor
    func test_perform_loadRegisteredCredentials_failure() async {
        passkeyService.registeredCredentialsThrowableError = BitwardenTestError.example

        await subject.perform(.loadRegisteredCredentials)

        XCTAssertEqual(subject.state.status, .failure(BitwardenTestError.example.localizedDescription))
        XCTAssertFalse(subject.state.isLoadingCredentials)
    }

    /// `perform(.selectCredential)` asserts using the selected credential's specific credential
    /// ID and RP ID.
    @MainActor
    func test_perform_selectCredential_passesCredentialIdAndRpId() async {
        let credential = Fido2CredentialAutofillView.fixture(credentialId: Data([0x09]), rpId: "example.com")
        passkeyService.assertPasskeyReturnValue = .fixture()

        await subject.perform(.selectCredential(credential))

        XCTAssertEqual(passkeyService.assertPasskeyReceivedArguments?.credentialId, Data([0x09]))
        XCTAssertEqual(passkeyService.assertPasskeyReceivedArguments?.rpId, "example.com")
    }

    /// `perform(.selectCredential)` sets status to `.success` with the matched credential's RP ID
    /// and username when assertion succeeds.
    @MainActor
    func test_perform_selectCredential_success() async {
        let credential = Fido2CredentialAutofillView.fixture(credentialId: Data([0x09]), rpId: "example.com")
        passkeyService.assertPasskeyReturnValue = .fixture(
            credentialId: Data([0x01, 0x02, 0x03]),
            selectedCredential: SelectedCredential(cipher: .fixture(), credential: .fixture(userName: "alice")),
        )

        await subject.perform(.selectCredential(credential))

        XCTAssertEqual(
            subject.state.status,
            .success(
                credentialId: Data([0x01, 0x02, 0x03]).base64EncodedString(),
                rpId: "example.com",
                userName: "alice",
            ),
        )
    }

    /// `perform(.selectCredential)` sets status to `.failure` when assertion throws.
    @MainActor
    func test_perform_selectCredential_failure() async {
        let credential = Fido2CredentialAutofillView.fixture(credentialId: Data([0x09]), rpId: "example.com")
        passkeyService.assertPasskeyThrowableError = BitwardenTestError.example

        await subject.perform(.selectCredential(credential))

        XCTAssertEqual(subject.state.status, .failure(BitwardenTestError.example.localizedDescription))
    }
}
