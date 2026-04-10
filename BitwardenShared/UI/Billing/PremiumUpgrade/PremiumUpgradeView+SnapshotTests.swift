// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - PremiumUpgradeViewSnapshotTests

class PremiumUpgradeViewSnapshotTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PremiumUpgradeState, PremiumUpgradeAction, PremiumUpgradeEffect>!
    var subject: PremiumUpgradeView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: PremiumUpgradeState())
        let store = Store(processor: processor)
        subject = PremiumUpgradeView(store: store)
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

    /// Check the snapshot when the view is in a loading state.
    @MainActor
    func disabletest_snapshot_loading() {
        processor.state.isLoading = true
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
