// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

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
        processor.state.planStatus = .active
        processor.state.subscription = PremiumSubscription(
            cadence: .annually,
            cancelAt: nil,
            canceled: nil,
            discount: 0,
            estimatedTax: 4.55,
            gracePeriod: nil,
            nextCharge: Date(timeIntervalSince1970: 1_775_304_000),
            seatsCost: 19.8,
            status: .active,
            storageCost: 4,
            suspension: nil,
        )
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the active state with no additional storage.
    @MainActor
    func disabletest_snapshot_activeNoStorage() {
        processor.state.planStatus = .active
        processor.state.subscription = PremiumSubscription(
            cadence: .annually,
            cancelAt: nil,
            canceled: nil,
            discount: 0,
            estimatedTax: 4.55,
            gracePeriod: nil,
            nextCharge: Date(timeIntervalSince1970: 1_775_304_000),
            seatsCost: 19.8,
            status: .active,
            storageCost: 0,
            suspension: nil,
        )
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the active state.
    @MainActor
    func disabletest_snapshot_active() {
        processor.state.planStatus = .active
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the canceled state.
    @MainActor
    func disabletest_snapshot_canceled() {
        processor.state.planStatus = .canceled
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the past due state.
    @MainActor
    func disabletest_snapshot_pastDue() {
        processor.state.planStatus = .pastDue
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the update payment state.
    @MainActor
    func disabletest_snapshot_updatePayment() {
        processor.state.planStatus = .updatePayment
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
