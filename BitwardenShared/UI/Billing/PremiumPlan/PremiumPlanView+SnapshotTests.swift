// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - PremiumPlanViewSnapshotTests

class PremiumPlanViewSnapshotTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PremiumPlanState, PremiumPlanAction, PremiumPlanEffect>!
    var subject: PremiumPlanView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: PremiumPlanState())
        let store = Store(processor: processor)
        subject = PremiumPlanView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Check the snapshot for the active state with additional storage.
    @MainActor
    func disabletest_snapshot_activeWithStorage() {
        processor.state.loadingState = .data(.fixture(
            estimatedTax: 4.55,
            nextCharge: Date(timeIntervalSince1970: 1_775_304_000),
            storageCost: 4,
        ))
        processor.state.planStatus = .active
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the active state with no additional storage.
    @MainActor
    func disabletest_snapshot_activeNoStorage() {
        processor.state.loadingState = .data(.fixture(
            estimatedTax: 4.55,
            nextCharge: Date(timeIntervalSince1970: 1_775_304_000),
        ))
        processor.state.planStatus = .active
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the active state.
    @MainActor
    func disabletest_snapshot_active() {
        processor.state.loadingState = .data(.fixture())
        processor.state.planStatus = .active
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the canceled state.
    @MainActor
    func disabletest_snapshot_canceled() {
        processor.state.loadingState = .data(.fixture(canceled: Date(), status: .canceled))
        processor.state.planStatus = .canceled
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the past due state.
    @MainActor
    func disabletest_snapshot_pastDue() {
        processor.state.loadingState = .data(.fixture(status: .pastDue))
        processor.state.planStatus = .pastDue
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the unpaid state.
    @MainActor
    func disabletest_snapshot_unpaid() {
        processor.state.planStatus = .unpaid
        processor.state.loadingState = .data(.fixture(
            discount: 2.10,
            estimatedTax: 3.85,
            status: .unpaid,
            suspension: Date(timeIntervalSince1970: 1_748_822_400),
        ))
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the update payment state.
    @MainActor
    func disabletest_snapshot_updatePayment() {
        processor.state.loadingState = .data(.fixture(status: .updatePayment))
        processor.state.planStatus = .updatePayment
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
