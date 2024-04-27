import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import AuthenticatorShared

// MARK: - VaultUnlockViewTests

class VaultUnlockViewTests: AuthenticatorTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultUnlockState, VaultUnlockAction, VaultUnlockEffect>!
    var subject: VaultUnlockView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let state = VaultUnlockState()
        processor = MockProcessor(state: state)
        subject = VaultUnlockView(
            store: Store(processor: processor)
        )
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Test a snapshot of the ItemListView previews.
    func test_snapshot_VaultUnlockView_previews() {
        for preview in VaultUnlockView_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [
                    .defaultPortrait,
                    .defaultPortraitDark,
                    .defaultPortraitAX5,
                    .defaultLandscape,
                    .defaultLandscapeAX5,
                ]
            )
        }
    }
}
