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
        credentialStore.fetchAllResult = [older, newer]

        await subject.perform(.loadCredentials)

        XCTAssertEqual(subject.state.credentials, [newer, older])
    }

    /// `perform(.loadCredentials)` shows an error alert if fetching the stored credentials fails.
    @MainActor
    func test_perform_loadCredentials_error() async {
        credentialStore.fetchAllError = BitwardenTestError.example

        await subject.perform(.loadCredentials)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertTrue(subject.state.credentials.isEmpty)
    }

    /// `perform(.deleteCredential)` shows a confirmation alert and, once confirmed, deletes the
    /// credential and reloads the list.
    @MainActor
    func test_perform_deleteCredential() async throws {
        let remaining = StoredPasskeyCredential.fixture(rpId: "remaining.com")
        credentialStore.fetchAllResult = [remaining]

        await subject.perform(.deleteCredential(id: "deleteMe"))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.areYouSureDeleteThisPasskey)
        XCTAssertEqual(alert.message, Localizations.deletePasskeyDescriptionLong)

        try await alert.tapCancel()
        XCTAssertTrue(credentialStore.deletedIds.isEmpty)

        try await alert.tapAction(title: Localizations.delete)
        XCTAssertEqual(credentialStore.deletedIds, ["deleteMe"])
        XCTAssertEqual(subject.state.credentials, [remaining])
    }

    /// `perform(.deleteCredential)` shows an error alert if deleting the credential fails.
    @MainActor
    func test_perform_deleteCredential_error() async throws {
        credentialStore.deleteError = BitwardenTestError.example

        await subject.perform(.deleteCredential(id: "deleteMe"))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.delete)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
    }

    /// `perform(.deleteAll)` shows a confirmation alert and, once confirmed, deletes all
    /// credentials and reloads the list.
    @MainActor
    func test_perform_deleteAll() async throws {
        credentialStore.fetchAllResult = [.fixture()]

        await subject.perform(.deleteAll)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.areYouSureDeleteAllPasskeys)
        XCTAssertEqual(alert.message, Localizations.deletePasskeyDescriptionLong)

        try await alert.tapCancel()
        XCTAssertFalse(credentialStore.deleteAllCalled)

        credentialStore.fetchAllResult = []
        try await alert.tapAction(title: Localizations.delete)
        XCTAssertTrue(credentialStore.deleteAllCalled)
        XCTAssertTrue(subject.state.credentials.isEmpty)
    }

    /// `perform(.deleteAll)` shows an error alert if deleting all credentials fails.
    @MainActor
    func test_perform_deleteAll_error() async throws {
        credentialStore.deleteAllError = BitwardenTestError.example

        await subject.perform(.deleteAll)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.delete)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
    }
}
