// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class DeleteAccountViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<DeleteAccountState, DeleteAccountAction, DeleteAccountEffect>!
    var subject: DeleteAccountView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: DeleteAccountState())

        let store = Store(processor: processor)
        subject = DeleteAccountView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// The view renders correctly.
    func disabletest_snapshot() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly.
    @MainActor
    func disabletest_preventUserFromDeletingAccount() {
        processor.state.shouldPreventUserFromDeletingAccount = true
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
