// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - GuidedTourView+LoginTests

class GuidedTourViewLoginTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<GuidedTourViewState, GuidedTourViewAction, Void>!
    var subject: GuidedTourView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(
            state: GuidedTourViewState(currentIndex: 0, guidedTourStepStates: [
                .loginStep1,
                .loginStep2,
                .loginStep3,
            ]),
        )
        let store = Store(processor: processor)
        subject = GuidedTourView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshot tests

    /// Test the snapshot of the step 1 of the learn new login guided tour.
    @MainActor
    func disabletest_snapshot_loginStep1() {
        processor.state.currentIndex = 0
        processor.state.guidedTourStepStates[0].spotlightRegion = CGRect(x: 320, y: 470, width: 40, height: 40)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }

    /// Test the snapshot of the step 1 of the learn new login guided tour in landscape.
    @MainActor
    func disabletest_snapshot_loginStep1_landscape() {
        processor.state.currentIndex = 0
        processor.state.guidedTourStepStates[0].spotlightRegion = CGRect(x: 650, y: 150, width: 40, height: 40)
        assertSnapshots(
            of: subject,
            as: [.defaultLandscape],
        )
    }

    /// Test the snapshot of the step 2 of the learn new login guided tour.
    @MainActor
    func disabletest_snapshot_loginStep2() {
        processor.state.currentIndex = 1
        processor.state.guidedTourStepStates[1].spotlightRegion = CGRect(x: 40, y: 470, width: 320, height: 95)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }

    /// Test the snapshot of the step 2 of the learn new login guided tour in landscape.
    @MainActor
    func disabletest_snapshot_loginStep2_landscape() {
        processor.state.currentIndex = 1
        processor.state.guidedTourStepStates[1].spotlightRegion = CGRect(x: 40, y: 60, width: 460, height: 95)
        assertSnapshots(
            of: subject,
            as: [.defaultLandscape],
        )
    }

    /// Test the snapshot of the step 3 of the learn new login guided tour.
    @MainActor
    func disabletest_snapshot_loginStep3() {
        processor.state.currentIndex = 2
        processor.state.guidedTourStepStates[2].spotlightRegion = CGRect(x: 40, y: 500, width: 320, height: 90)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }

    /// Test the snapshot of the step 3 of the learn new login guided tour in landscape.
    @MainActor
    func disabletest_snapshot_loginStep3_landscape() {
        processor.state.currentIndex = 2
        processor.state.guidedTourStepStates[2].spotlightRegion = CGRect(x: 40, y: 60, width: 460, height: 90)
        assertSnapshots(
            of: subject,
            as: [.defaultLandscape],
        )
    }
}
