import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - SendRepositoryTests

class SendRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var client: MockHTTPClient!
    var clientService: MockClientService!
    var environmentService: MockEnvironmentService!
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
        clientService = MockClientService()
        environmentService = MockEnvironmentService()
        organizationService = MockOrganizationService()
        clientService.mockVault.clientSends = clientSends
        sendService = MockSendService()
        stateService = MockStateService()
        syncService = MockSyncService()
        subject = DefaultSendRepository(
            clientService: clientService,
            environmentService: environmentService,
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
        clientService = nil
        organizationService = nil
        sendService = nil
        stateService = nil
        syncService = nil
        subject = nil
    }

    // MARK: Tests

    /// `addFileSend()` successfully encrypts the send view and uses the send service to add it.
    func test_addFileSend_success() async throws {
        let sendResult = Send.fixture(id: "SEND_ID")
        sendService.addFileSendResult = .success(sendResult)
        let sendView = SendView.fixture()
        let data = Data("example".utf8)

        let result = try await subject.addFileSend(sendView, data: data)

        XCTAssertEqual(result, SendView(send: sendResult))
        XCTAssertEqual(clientSends.encryptedSendViews, [sendView])
        XCTAssertEqual(sendService.addFileSendSend, Send(sendView: sendView))
    }

    /// `addFileSend()` rethrows any errors encountered.
    func test_addFileSend_failure() async {
        sendService.addFileSendResult = .failure(BitwardenTestError.example)
        let sendView = SendView.fixture()
        let data = Data("example".utf8)

        await assertAsyncThrows {
            _ = try await subject.addFileSend(sendView, data: data)
        }

        XCTAssertEqual(clientSends.encryptedSendViews, [sendView])
    }

    /// `addTextSend()` successfully encrypts the send view and uses the send service to add it.
    func test_addTextSend_success() async throws {
        let sendResult = Send.fixture(id: "SEND_ID")
        sendService.addTextSendResult = .success(sendResult)
        let sendView = SendView.fixture()
        let result = try await subject.addTextSend(sendView)

        XCTAssertEqual(result, SendView(send: sendResult))
        XCTAssertEqual(clientSends.encryptedSendViews, [sendView])
        XCTAssertEqual(sendService.addTextSendSend, Send(sendView: sendView))
    }

    /// `addTextSend()` rethrows any errors encountered.
    func test_addTextSend_failure() async {
        sendService.addTextSendResult = .failure(BitwardenTestError.example)
        let sendView = SendView.fixture()

        await assertAsyncThrows {
            _ = try await subject.addTextSend(sendView)
        }

        XCTAssertEqual(clientSends.encryptedSendViews, [sendView])
    }

    /// `deleteSend()` successfully encrypts the send view and uses the send service to delete it.
    func test_deleteSend_success() async throws {
        sendService.deleteSendResult = .success(())
        let sendView = SendView.fixture()
        try await subject.deleteSend(sendView)

        XCTAssertEqual(clientSends.encryptedSendViews, [sendView])
        XCTAssertEqual(sendService.deleteSendSend, Send(sendView: sendView))
    }

    /// `deleteSend()` rethrows any errors encountered.
    func test_deleteSend_failure() async {
        sendService.deleteSendResult = .failure(BitwardenTestError.example)
        let sendView = SendView.fixture()

        await assertAsyncThrows {
            try await subject.deleteSend(sendView)
        }

        XCTAssertEqual(clientSends.encryptedSendViews, [sendView])
    }

    /// `doesActiveAccountHavePremium()` with premium personally and no organizations returns true.
    func test_doesActiveAccountHavePremium_personalTrue_noOrganization() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(hasPremiumPersonally: true))
        let hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertTrue(hasPremium)
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

    /// `doesActiveAccountHaveVerifiedEmail()` with verified email returns true.
    func test_doesActiveAccountHaveVerifedEmail_true() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(emailVerified: true))
        let isVerified = try await subject.doesActiveAccountHaveVerifiedEmail()
        XCTAssertTrue(isVerified)
    }

    /// `doesActiveAccountHavePremium()` with unverified email returns false.
    func test_doesActiveAccountHaveVerifedEmail_false() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(emailVerified: false))
        let isVerified = try await subject.doesActiveAccountHaveVerifiedEmail()
        XCTAssertFalse(isVerified)
    }

    /// `doesActiveAccountHavePremium()` with nil verified email returns false.
    func test_doesActiveAccountHaveVerifedEmail_nil() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(emailVerified: nil))
        let isVerified = try await subject.doesActiveAccountHaveVerifiedEmail()
        XCTAssertFalse(isVerified)
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

    /// `removePassword(from:)` successfully encrypts the send view and uses the send service to
    /// remove the password from it.
    func test_removePassword_success() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        sendService.removePasswordFromSendResult = .success(.fixture(id: "SEND_ID"))

        let response = try await subject.removePassword(from: sendView)

        XCTAssertEqual(response.id, "SEND_ID")
        XCTAssertEqual(clientSends.encryptedSendViews, [sendView])
        XCTAssertEqual(clientSends.decryptedSends, [.fixture(id: "SEND_ID")])
        XCTAssertEqual(sendService.removePasswordFromSendSend, Send(sendView: sendView))
    }

    /// `removePassword(from:)` rethrows any errors encountered.
    func test_removePassword_failure() async {
        sendService.removePasswordFromSendResult = .failure(BitwardenTestError.example)
        let sendView = SendView.fixture()

        await assertAsyncThrows {
            _ = try await subject.removePassword(from: sendView)
        }

        XCTAssertEqual(clientSends.encryptedSendViews, [sendView])
        XCTAssertTrue(clientSends.decryptedSends.isEmpty)
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

    /// `shareURL()` successfully generates a share url for the send view.
    func test_shareURL() async throws {
        let sendView = SendView.fixture(accessId: "ACCESS_ID", key: "KEY")
        environmentService.webVaultURL = .example
        let url = try await subject.shareURL(for: sendView)

        XCTAssertEqual(url?.absoluteString, "https://example.com/#/send/ACCESS_ID/KEY")
    }

    /// `updateSend()` successfully encrypts the send view and uses the send service to update it.
    func test_updateSend() async throws {
        let sendResult = Send.fixture(id: "SEND_ID")
        sendService.updateSendResult = .success(sendResult)
        let sendView = SendView.fixture()
        let result = try await subject.updateSend(sendView)

        XCTAssertEqual(result, SendView(send: sendResult))
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
            result.append("Section: \(section.name ?? "--")\n")
            result.append(dumpSendListItems(section.items, indent: "  "))
            if section != sections.last {
                result.append("\n")
            }
        }
    }
} // swiftlint:disable:this file_length
