import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - SendRepositoryTests

class SendRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var client: MockHTTPClient!
    var clientVaultService: MockClientVaultService!
    var organizationService: MockOrganizationService!
    var clientSends: MockClientSends!
    var sendService: MockSendService!
    var stateService: MockStateService!
    var syncService: MockSyncService!
    var subject: DefaultSendRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        client = MockHTTPClient()
        clientSends = MockClientSends()
        clientVaultService = MockClientVaultService()
        organizationService = MockOrganizationService()
        clientVaultService.clientSends = clientSends
        sendService = MockSendService()
        stateService = MockStateService()
        syncService = MockSyncService()
        subject = DefaultSendRepository(
            clientVault: clientVaultService,
            organizationService: organizationService,
            sendService: sendService,
            stateService: stateService,
            syncService: syncService
        )
    }

    override func tearDown() {
        super.tearDown()
        client = nil
        clientSends = nil
        clientVaultService = nil
        organizationService = nil
        sendService = nil
        stateService = nil
        syncService = nil
        subject = nil
    }

    // MARK: Tests

    /// `addSend()` successfully encrypts the send view and uses the send service to add it.
    func test_addSend_success() async throws {
        sendService.addSendResult = .success(())
        let sendView = SendView.fixture()
        try await subject.addSend(sendView)

        XCTAssertEqual(clientSends.encryptedSendViews, [sendView])
        XCTAssertEqual(sendService.addSendSend, Send(sendView: sendView))
    }

    /// `doesActiveAccountHavePremium()` with premium personally and no organizations returns true.
    func test_doesActiveAccountHavePremium_personalTrue_noOrganization() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(hasPremiumPersonally: true))
        let hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertTrue(hasPremium)
    }

    /// `addSend()` rethrows any errors encountered.
    func test_addSend_failure() async {
        sendService.addSendResult = .failure(BitwardenTestError.example)
        let sendView = SendView.fixture()

        await assertAsyncThrows {
            try await subject.addSend(sendView)
        }

        XCTAssertEqual(clientSends.encryptedSendViews, [sendView])
    }

    /// `doesActiveAccountHavePremium()` with no premium personally and no organizations returns
    /// false.
    func test_doesActiveAccountHavePremium_personalFalse_noOrganization() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(hasPremiumPersonally: false))
        let hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertFalse(hasPremium)
    }

    /// `doesActiveAccountHavePremium()` with nil premium personally and no organizations returns
    /// false.
    func test_doesActiveAccountHavePremium_personalNil_noOrganization() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(hasPremiumPersonally: nil))
        let hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertFalse(hasPremium)
    }

    /// `doesActiveAccountHavePremium()` with premium personally and an organization without premium
    /// returns true.
    func test_doesActiveAccountHavePremium_personalTrue_organizationFalse() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(hasPremiumPersonally: true))
        organizationService.fetchAllOrganizationsResult = .success([.fixture(usersGetPremium: false)])
        let hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertTrue(hasPremium)
    }

    /// `doesActiveAccountHavePremium()` with no premium personally and an organization with premium
    /// returns true.
    func test_doesActiveAccountHavePremium_personalFalse_organizationTrue() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(hasPremiumPersonally: false))
        organizationService.fetchAllOrganizationsResult = .success([.fixture(usersGetPremium: true)])
        let hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertTrue(hasPremium)
    }

    /// `doesActiveAccountHavePremium()` with premium personally and an organization with premium
    /// returns true.
    func test_doesActiveAccountHavePremium_personalTrue_organizationTrue() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(hasPremiumPersonally: true))
        organizationService.fetchAllOrganizationsResult = .success([.fixture(usersGetPremium: true)])
        let hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertTrue(hasPremium)
    }

    /// `doesActiveAccountHavePremium()` with premium personally and an organization with premium
    /// but disabled returns true.
    func test_doesActiveAccountHavePremium_personalTrue_organizationTrueDisabled() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(hasPremiumPersonally: true))
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(enabled: false, usersGetPremium: true),
        ])
        let hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertTrue(hasPremium)
    }

    /// `doesActiveAccountHavePremium()` with no premium personally and an organization with premium
    /// but disabled returns false.
    func test_doesActiveAccountHavePremium_personalFalse_organizationTrueDisabled() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(hasPremiumPersonally: false))
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(enabled: false, usersGetPremium: true),
        ])
        let hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertFalse(hasPremium)
    }

    /// `fetchSync(isManualRefresh:)` while manual refresh is allowed does perform a sync.
    func test_fetchSync_manualRefreshAllowed_success() async throws {
        await stateService.addAccount(.fixture())
        stateService.allowSyncOnRefresh = ["1": true]
        syncService.fetchSyncResult = .success(())

        try await subject.fetchSync(isManualRefresh: true)

        XCTAssertTrue(syncService.didFetchSync)
    }

    /// `fetchSync(isManualRefresh:)` while manual refresh is not allowed does not perform a sync.
    func test_fetchSync_manualRefreshNotAllowed_success() async throws {
        await stateService.addAccount(.fixture())
        stateService.allowSyncOnRefresh = [:]
        syncService.fetchSyncResult = .success(())

        try await subject.fetchSync(isManualRefresh: true)

        XCTAssertFalse(syncService.didFetchSync)
    }

    /// `fetchSync(isManualRefresh:)` and a failure performs a sync and throws the error.
    func test_fetchSync_failure() async throws {
        await stateService.addAccount(.fixture())
        stateService.allowSyncOnRefresh = ["1": true]
        syncService.fetchSyncResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows {
            try await subject.fetchSync(isManualRefresh: true)
        }
        XCTAssertTrue(syncService.didFetchSync)
    }

    /// `searchSendPublisher(searchText:)` returns search matching send name.
    func test_searchSendPublisher_searchText_name() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        sendService.sendsSubject.value = [
            .fixture(
                id: "1",
                name: "Shakespeare quote",
                text: .fixture(text: "To be or not to be?")
            ),
            .fixture(id: "2", name: "Cactus"),
            .fixture(
                file: .fixture(fileName: "grumpy_cat.png"),
                id: "3",
                name: "A picture of a cute cát"
            ),
        ]
        let sendView = SendView(send: sendService.sendsSubject.value[2])
        let expectedSearchResult = try [XCTUnwrap(SendListItem(sendView: sendView))]
        var iterator = try await subject
            .searchSendPublisher(searchText: "cat")
            .makeAsyncIterator()
        let sends = try await iterator.next()
        XCTAssertEqual(sends, expectedSearchResult)
    }

    /// `searchSendPublisher(searchText:)` returns search matching text send's value.
    func test_searchSendPublisher_searchText_text() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        sendService.sendsSubject.value = [
            .fixture(
                id: "1",
                name: "Shakespeare quote",
                text: .fixture(text: "To be or not to be?")
            ),
            .fixture(id: "2", name: "Cactus"),
            .fixture(
                file: .fixture(fileName: "grumpy_cat.png"),
                id: "3",
                name: "A picture of a cute cat"
            ),
        ]
        let sendView = SendView(send: sendService.sendsSubject.value[0])
        let expectedSearchResult = try [XCTUnwrap(SendListItem(sendView: sendView))]
        var iterator = try await subject
            .searchSendPublisher(searchText: "or not")
            .makeAsyncIterator()
        let sends = try await iterator.next()
        XCTAssertEqual(sends, expectedSearchResult)
    }

    /// `searchSendPublisher(searchText:)` returns search matching text send's value.
    func test_searchSendPublisher_searchText_fileName() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        sendService.sendsSubject.value = [
            .fixture(
                id: "1",
                name: "Shakespeare quote",
                text: .fixture(text: "To be or not to be?")
            ),
            .fixture(id: "2", name: "Cactus"),
            .fixture(
                file: .fixture(fileName: "grumpy_cat.png"),
                id: "3",
                name: "A picture of a cute cat"
            ),
        ]
        let sendView = SendView(send: sendService.sendsSubject.value[2])
        let expectedSearchResult = try [XCTUnwrap(SendListItem(sendView: sendView))]
        var iterator = try await subject
            .searchSendPublisher(searchText: "grumpy")
            .makeAsyncIterator()
        let sends = try await iterator.next()
        XCTAssertEqual(sends, expectedSearchResult)
    }

    /// `sendListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the sends tab.
    func test_sendListPublisher_withoutValues() async throws {
        sendService.sendsSubject.send([])

        var iterator = try await subject.sendListPublisher().makeAsyncIterator()
        let sections = try await iterator.next()

        try assertInlineSnapshot(of: dumpSendListSections(XCTUnwrap(sections)), as: .lines) {
            """
            """
        }
    }

    /// `sendListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the sends tab.
    func test_sendListPublisher_withValues() async throws {
        sendService.sendsSubject.send([
            .fixture(
                name: "encrypted name",
                text: .init(hidden: false, text: "encrypted text"),
                type: .text
            ),
            .fixture(
                file: .init(fileName: "test.txt", id: "1", size: "123", sizeName: "123 KB"),
                name: "encrypted name",
                type: .file
            ),
        ])

        var iterator = try await subject.sendListPublisher().makeAsyncIterator()
        let sections = try await iterator.next()

        try assertInlineSnapshot(of: dumpSendListSections(XCTUnwrap(sections)), as: .lines) {
            """
            Section: Types
              - Group: Text (1)
              - Group: File (1)
            Section: All Sends
              - Send: encrypted name
              - Send: encrypted name
            """
        }
    }

    /// `updateSend()` successfully encrypts the send view and uses the send service to update it.
    func test_updateSend() async throws {
        let sendView = SendView.fixture()
        try await subject.updateSend(sendView)

        XCTAssertEqual(clientSends.encryptedSendViews, [sendView])
        XCTAssertEqual(sendService.updateSendSend, Send(sendView: sendView))
    }

    // MARK: Private Methods

    /// Returns a string containing a description of the send list items.
    private func dumpSendListItems(_ items: [SendListItem], indent: String = "") -> String {
        guard !items.isEmpty else { return indent + "(empty)" }
        return items.reduce(into: "") { result, item in
            switch item.itemType {
            case let .send(sendView):
                result.append(indent + "- Send: \(sendView.name)")
            case let .group(group, count):
                result.append(indent + "- Group: \(group.localizedName) (\(count))")
            }
            if item != items.last {
                result.append("\n")
            }
        }
    }

    /// Returns a string containing a description of the send list sections.
    private func dumpSendListSections(_ sections: [SendListSection]) -> String {
        sections.reduce(into: "") { result, section in
            result.append("Section: \(section.name)\n")
            result.append(dumpSendListItems(section.items, indent: "  "))
            if section != sections.last {
                result.append("\n")
            }
        }
    }
}
