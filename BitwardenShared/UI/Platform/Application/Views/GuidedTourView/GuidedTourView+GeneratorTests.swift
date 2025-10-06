// swiftlint:disable:this file_name
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - GuidedTourView+GeneratorTests

class GuidedTourViewGeneratorTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<GuidedTourViewState, GuidedTourViewAction, Void>!
    var subject: GuidedTourView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(
            state: GuidedTourViewState(currentIndex: 0, guidedTourStepStates: [
                .generatorStep1,
                .generatorStep2,
                .generatorStep3,
                .generatorStep4,
                .generatorStep5,
                .generatorStep6,
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

    /// Test the snapshot of the step 1 of the learn generator guided tour.
    @MainActor
    func disabletest_snapshot_generatorStep1() {
        processor.state.currentIndex = 0
        processor.state.guidedTourStepStates[0].spotlightRegion = CGRect(x: 25, y: 80, width: 340, height: 40)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait],
        )
    }

    /// Test the snapshot of the step 2 of the learn generator guided tour.
    @MainActor
    func disabletest_snapshot_generatorStep2() {
        processor.state.currentIndex = 1
        processor.state.guidedTourStepStates[1].spotlightRegion = CGRect(x: 25, y: 80, width: 340, height: 40)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait],
        )
    }

    /// Test the snapshot of the step 3 of the learn generator guided tour.
    @MainActor
    func disabletest_snapshot_generatorStep3() {
        processor.state.currentIndex = 2
        processor.state.guidedTourStepStates[2].spotlightRegion = CGRect(x: 25, y: 80, width: 340, height: 40)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait],
        )
    }

    /// Test the snapshot of the step 4 of the learn generator guided tour.
    @MainActor
    func disabletest_snapshot_generatorStep4() {
        processor.state.currentIndex = 3
        processor.state.guidedTourStepStates[3].spotlightRegion = CGRect(x: 25, y: 300, width: 340, height: 400)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait],
        )
    }

    /// Test the snapshot of the step 5 of the learn generator guided tour.
    @MainActor
    func disabletest_snapshot_generatorStep5() {
        processor.state.currentIndex = 4
        processor.state.guidedTourStepStates[4].spotlightRegion = CGRect(x: 300, y: 160, width: 40, height: 40)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait],
        )
    }

    /// Test the snapshot of the step 6 of the learn generator guided tour.
    @MainActor
    func disabletest_snapshot_generatorStep6() {
        processor.state.currentIndex = 5
        processor.state.guidedTourStepStates[5].spotlightRegion = CGRect(x: 25, y: 160, width: 340, height: 60)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait],
        )
    }
}
