import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - SendRepositoryTests

class SendRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var clientVaultService: MockClientVaultService!
    var syncService: MockSyncService!
    var subject: DefaultSendRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        clientVaultService = MockClientVaultService()
        syncService = MockSyncService()
        subject = DefaultSendRepository(
            clientVault: clientVaultService,
            syncService: syncService
        )
    }

    override func tearDown() {
        super.tearDown()
        clientVaultService = nil
        syncService = nil
        subject = nil
    }

    // MARK: Tests

    func test_fetchSync_success() async throws {
        syncService.fetchSyncResult = .success(())
        try await subject.fetchSync()
        XCTAssertTrue(syncService.didFetchSync)
    }

    func test_fetchSync_failure() async throws {
        syncService.fetchSyncResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows {
            try await subject.fetchSync()
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
