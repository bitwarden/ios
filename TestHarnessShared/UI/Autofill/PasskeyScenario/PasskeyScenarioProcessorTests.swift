import AuthenticationServices
import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - PasskeyScenarioProcessorTests

/// Tests for `PasskeyScenarioProcessor`.
///
class PasskeyScenarioProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<RootRoute, Void>!
    var delegate: MockPasskeyScenarioProcessorDelegate!
    var mockRegistry: MockPasskeyRegistryService!
    var subject: PasskeyScenarioProcessor!

    // MARK: Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        delegate = MockPasskeyScenarioProcessorDelegate()
        mockRegistry = MockPasskeyRegistryService()
        subject = PasskeyScenarioProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            passkeyRegistryService: mockRegistry,
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        delegate = nil
        mockRegistry = nil
        subject = nil
    }

    // MARK: Action Tests

    /// `receive(.displayNameChanged)` updates the display name and resets registration status.
    @MainActor
    func test_receive_displayNameChanged() {
        subject.receive(.displayNameChanged("Alice Smith"))
        XCTAssertEqual(subject.state.displayName, "Alice Smith")
        XCTAssertEqual(subject.state.registrationStatus, .idle)
    }

    /// `receive(.modeChanged)` updates the active tab.
    @MainActor
    func test_receive_modeChanged() {
        subject.receive(.modeChanged(.authenticate))
        XCTAssertEqual(subject.state.mode, .authenticate)
        subject.receive(.modeChanged(.manage))
        XCTAssertEqual(subject.state.mode, .manage)
    }

    /// `receive(.rpIdChanged)` updates the RP ID and resets both statuses.
    @MainActor
    func test_receive_rpIdChanged() {
        subject.receive(.rpIdChanged("example.com"))
        XCTAssertEqual(subject.state.rpId, "example.com")
        XCTAssertEqual(subject.state.assertionStatus, .idle)
        XCTAssertEqual(subject.state.registrationStatus, .idle)
    }

    /// `receive(.userNameChanged)` updates the username and resets registration status.
    @MainActor
    func test_receive_userNameChanged() {
        subject.receive(.userNameChanged("alice"))
        XCTAssertEqual(subject.state.userName, "alice")
        XCTAssertEqual(subject.state.registrationStatus, .idle)
    }

    // MARK: Registration Effect Tests

    /// `perform(.registerPasskey)` sets status to `.success` and saves the entry when registration succeeds.
    @MainActor
    func test_perform_registerPasskey_success() async {
        subject.performRegistration = { _, _, _ in }
        await subject.perform(.registerPasskey)
        XCTAssertEqual(subject.state.registrationStatus, .success)
        XCTAssertEqual(mockRegistry.savedPasskeys.count, 1)
    }

    /// `perform(.registerPasskey)` sets status to `.failure` when registration throws.
    @MainActor
    func test_perform_registerPasskey_failure() async {
        let testError = BitwardenTestError.example
        subject.performRegistration = { _, _, _ in throw testError }
        await subject.perform(.registerPasskey)
        XCTAssertEqual(subject.state.registrationStatus, .failure(testError.localizedDescription))
    }

    /// `perform(.registerPasskey)` resets status to `.idle` when the user cancels.
    @MainActor
    func test_perform_registerPasskey_canceled() async {
        subject.performRegistration = { _, _, _ in throw ASAuthorizationError(.canceled) }
        await subject.perform(.registerPasskey)
        XCTAssertEqual(subject.state.registrationStatus, .idle)
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

    // MARK: Assertion Effect Tests

    /// `perform(.assertPasskey)` sets status to `.success` when assertion succeeds.
    @MainActor
    func test_perform_assertPasskey_success() async {
        subject.performAssertion = { _ in }
        await subject.perform(.assertPasskey)
        XCTAssertEqual(subject.state.assertionStatus, .success)
    }

    /// `perform(.assertPasskey)` sets status to `.failure` when assertion throws.
    @MainActor
    func test_perform_assertPasskey_failure() async {
        let testError = BitwardenTestError.example
        subject.performAssertion = { _ in throw testError }
        await subject.perform(.assertPasskey)
        XCTAssertEqual(subject.state.assertionStatus, .failure(testError.localizedDescription))
    }

    /// `perform(.assertPasskey)` resets status to `.idle` when the user cancels.
    @MainActor
    func test_perform_assertPasskey_canceled() async {
        subject.performAssertion = { _ in throw ASAuthorizationError(.canceled) }
        await subject.perform(.assertPasskey)
        XCTAssertEqual(subject.state.assertionStatus, .idle)
    }

    /// `perform(.assertPasskey)` passes the current RP ID to the assertion closure.
    @MainActor
    func test_perform_assertPasskey_passesRpId() async {
        subject.receive(.rpIdChanged("example.com"))
        var capturedRpId: String?
        subject.performAssertion = { rpId in capturedRpId = rpId }
        await subject.perform(.assertPasskey)
        XCTAssertEqual(capturedRpId, "example.com")
    }

    // MARK: Manage Effect Tests

    /// `perform(.clearAll)` empties the registry and clears state.
    @MainActor
    func test_perform_clearAll() async {
        mockRegistry.passkeys = [
            PasskeyEntry(id: UUID(), rpId: "a.com", userName: "u", displayName: "U", createdAt: Date()),
        ]
        await subject.perform(.loadPasskeys)
        XCTAssertFalse(subject.state.passkeys.isEmpty)

        await subject.perform(.clearAll)
        XCTAssertTrue(subject.state.passkeys.isEmpty)
    }

    /// `perform(.deletePasskey)` removes only the target entry from state.
    @MainActor
    func test_perform_deletePasskey() async {
        let entry = PasskeyEntry(id: UUID(), rpId: "a.com", userName: "u", displayName: "U", createdAt: Date())
        mockRegistry.passkeys = [entry]
        await subject.perform(.loadPasskeys)
        XCTAssertEqual(subject.state.passkeys.count, 1)

        await subject.perform(.deletePasskey(entry))
        XCTAssertTrue(subject.state.passkeys.isEmpty)
    }

    /// `perform(.loadPasskeys)` populates state from the registry.
    @MainActor
    func test_perform_loadPasskeys() async {
        mockRegistry.passkeys = [
            PasskeyEntry(id: UUID(), rpId: "a.com", userName: "u1", displayName: "U1", createdAt: Date()),
            PasskeyEntry(id: UUID(), rpId: "b.com", userName: "u2", displayName: "U2", createdAt: Date()),
        ]
        await subject.perform(.loadPasskeys)
        XCTAssertEqual(subject.state.passkeys.count, 2)
    }
}

// MARK: - MockPasskeyRegistryService

class MockPasskeyRegistryService: PasskeyRegistryService {
    var savedPasskeys: [PasskeyEntry] = []
    var passkeys: [PasskeyEntry] = []

    func savePasskey(_ entry: PasskeyEntry) async { savedPasskeys.append(entry) }
    func loadPasskeys() async -> [PasskeyEntry] { passkeys }
    func deletePasskey(_ entry: PasskeyEntry) async { passkeys.removeAll { $0.id == entry.id } }
    func clearAll() async { passkeys = [] }
}

// MARK: - MockPasskeyScenarioProcessorDelegate

class MockPasskeyScenarioProcessorDelegate: PasskeyScenarioProcessorDelegate {
    var presentationAnchorResult: ASPresentationAnchor = UIWindow()

    func presentationAnchorForPasskeyAssertion() async -> ASPresentationAnchor { presentationAnchorResult }
    func presentationAnchorForPasskeyRegistration() async -> ASPresentationAnchor { presentationAnchorResult }
}
