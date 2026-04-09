// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class RemoveMasterPasswordViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<RemoveMasterPasswordState, RemoveMasterPasswordAction, RemoveMasterPasswordEffect>!
    var subject: RemoveMasterPasswordView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: RemoveMasterPasswordState(
            masterPassword: "password",
            organizationName: "Example Org",
            organizationId: "ORG_ID",
            keyConnectorUrl: "https://example.com",
        ))

        subject = RemoveMasterPasswordView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The remove master password view renders correctly.
    @MainActor
    func disabletest_snapshot_removeMasterPassword() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 1.5)],
        )
    }
}
