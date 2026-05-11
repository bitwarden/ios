// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - PremiumUpgradeCompleteViewSnapshotTests

class PremiumUpgradeCompleteViewSnapshotTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<Void, PremiumUpgradeCompleteAction, Void>!
    var subject: PremiumUpgradeCompleteView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: ())
        let store = Store(processor: processor)
        subject = PremiumUpgradeCompleteView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Check the snapshot for the default state.
    @MainActor
    func disabletest_snapshot_default() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
