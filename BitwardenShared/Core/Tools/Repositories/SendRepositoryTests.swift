import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - SendRepositoryTests

class SendRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var clientVaultService: MockClientVaultService!
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
        clientVaultService.clientSends = clientSends
        sendService = MockSendService()
        stateService = MockStateService()
        syncService = MockSyncService()
        subject = DefaultSendRepository(
            clientVault: clientVaultService,
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
        sendService = nil
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

    /// `addSend()` rethrows any errors encountered.
    func test_addSend_failure() async {
        sendService.addSendResult = .failure(BitwardenTestError.example)
        let sendView = SendView.fixture()

        await assertAsyncThrows {
            try await subject.addSend(sendView)
        }

        XCTAssertEqual(clientSends.encryptedSendViews, [sendView])
    }

    func test_fetchSync_manualRefreshAllowed_success() async throws {
        await stateService.addAccount(.fixture())
        stateService.allowSyncOnRefresh = ["1": true]
        syncService.fetchSyncResult = .success(())

        try await subject.fetchSync(isManualRefresh: true)

        XCTAssertTrue(syncService.didFetchSync)
    }

    func test_fetchSync_manualRefreshNotAllowed_success() async throws {
        await stateService.addAccount(.fixture())
        stateService.allowSyncOnRefresh = [:]
        syncService.fetchSyncResult = .success(())

        try await subject.fetchSync(isManualRefresh: true)

        XCTAssertFalse(syncService.didFetchSync)
    }

    func test_fetchSync_failure() async throws {
        await stateService.addAccount(.fixture())
        stateService.allowSyncOnRefresh = ["1": true]
        syncService.fetchSyncResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows {
            try await subject.fetchSync(isManualRefresh: true)
        }
        XCTAssertTrue(syncService.didFetchSync)
    }

    /// `sendListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the sends tab.
    func test_sendListPublisher_withValues() async throws {
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithSends.data
        ))

        var iterator = subject.sendListPublisher().makeAsyncIterator()
        let sections = await iterator.next()

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
