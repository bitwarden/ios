import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - ManagePasskeysProcessorTests

/// Tests for `ManagePasskeysProcessor`.
///
class ManagePasskeysProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<RootRoute, Void>!
    var credentialStore: MockPasskeyCredentialStore!
    var subject: ManagePasskeysProcessor!

    // MARK: Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        credentialStore = MockPasskeyCredentialStore()
        subject = ManagePasskeysProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            credentialStore: credentialStore,
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        credentialStore = nil
        subject = nil
    }

    // MARK: Effect Tests

    /// `perform(.loadCredentials)` populates state with the stored credentials, most recently
    /// created first.
    @MainActor
    func test_perform_loadCredentials() async {
        let older = StoredPasskeyCredential.fixture(rpId: "older.com", createdAt: Date(timeIntervalSince1970: 0))
        let newer = StoredPasskeyCredential.fixture(rpId: "newer.com", createdAt: Date(timeIntervalSince1970: 100))
        credentialStore.fetchAllReturnValue = [older, newer]

        await subject.perform(.loadCredentials)

        XCTAssertEqual(subject.state.credentials, [newer, older])
    }

    /// `perform(.loadCredentials)` shows an error alert if fetching the stored credentials fails.
    @MainActor
    func test_perform_loadCredentials_error() async {
        credentialStore.fetchAllThrowableError = BitwardenTestError.example

        await subject.perform(.loadCredentials)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertTrue(subject.state.credentials.isEmpty)
    }

    /// `perform(.deleteCredential)` deletes the credential and reloads the list.
    @MainActor
    func test_perform_deleteCredential() async {
        let remaining = StoredPasskeyCredential.fixture(rpId: "remaining.com")
        credentialStore.fetchAllReturnValue = [remaining]

        await subject.perform(.deleteCredential(id: "deleteMe"))

        XCTAssertEqual(credentialStore.deleteReceivedId, "deleteMe")
        XCTAssertEqual(subject.state.credentials, [remaining])
        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }

    /// `perform(.deleteCredential)` shows an error alert if deleting the credential fails.
    @MainActor
    func test_perform_deleteCredential_error() async {
        credentialStore.deleteThrowableError = BitwardenTestError.example

        await subject.perform(.deleteCredential(id: "deleteMe"))

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
    }

    /// `perform(.deleteAll)` deletes all credentials and reloads the list.
    @MainActor
    func test_perform_deleteAll() async {
        credentialStore.fetchAllReturnValue = []

        await subject.perform(.deleteAll)

        XCTAssertTrue(credentialStore.deleteAllCalled)
        XCTAssertTrue(subject.state.credentials.isEmpty)
        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }

    /// `perform(.deleteAll)` shows an error alert if deleting all credentials fails.
    @MainActor
    func test_perform_deleteAll_error() async {
        credentialStore.deleteAllThrowableError = BitwardenTestError.example

        await subject.perform(.deleteAll)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
    }
}
