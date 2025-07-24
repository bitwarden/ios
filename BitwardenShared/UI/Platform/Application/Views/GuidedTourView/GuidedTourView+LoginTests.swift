// swiftlint:disable:this file_name
import BitwardenResources
import SnapshotTesting
import SwiftUI
import ViewInspector
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
            ])
        )
        let store = Store(processor: processor)
        subject = GuidedTourView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tap the `back` button should dispatch the `backTapped` action.
    @MainActor
    func test_backButton_tap() async throws {
        processor.state.currentIndex = 1
        let button = try subject.inspect().find(button: Localizations.back)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.backTapped])
    }

    /// Tapping the `done` button should dispatch the `doneTapped` action.
    @MainActor
    func test_doneButton_tap() async throws {
        processor.state.currentIndex = 2
        let button = try subject.inspect().find(button: Localizations.done)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.doneTapped])
    }

    /// Tapping the dismiss button dispatches the `.dismissTapped` action.
    @MainActor
    func test_dismissButton_tap() async throws {
        processor.state.currentIndex = 2
        let button = try subject.inspect().find(button: Localizations.dismiss)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.dismissTapped])
    }

    /// Tapping the `next` button should dispatch the `nextTapped` action.
    @MainActor
    func test_nextButton_tap() async throws {
        let button = try subject.inspect().find(button: Localizations.next)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.nextTapped])
    }

    // MARK: Snapshot tests

    /// Test the snapshot of the step 1 of the learn new login guided tour.
    @MainActor
    func test_snapshot_loginStep1() {
        processor.state.currentIndex = 0
        processor.state.guidedTourStepStates[0].spotlightRegion = CGRect(x: 320, y: 470, width: 40, height: 40)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark]
        )
    }

    /// Test the snapshot of the step 1 of the learn new login guided tour in landscape.
    @MainActor
    func test_snapshot_loginStep1_landscape() {
        processor.state.currentIndex = 0
        processor.state.guidedTourStepStates[0].spotlightRegion = CGRect(x: 650, y: 150, width: 40, height: 40)
        assertSnapshots(
            of: subject,
            as: [.defaultLandscape]
        )
    }

    /// Test the snapshot of the step 2 of the learn new login guided tour.
    @MainActor
    func test_snapshot_loginStep2() {
        processor.state.currentIndex = 1
        processor.state.guidedTourStepStates[1].spotlightRegion = CGRect(x: 40, y: 470, width: 320, height: 95)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark]
        )
    }

    /// Test the snapshot of the step 2 of the learn new login guided tour in landscape.
    @MainActor
    func test_snapshot_loginStep2_landscape() {
        processor.state.currentIndex = 1
        processor.state.guidedTourStepStates[1].spotlightRegion = CGRect(x: 40, y: 60, width: 460, height: 95)
        assertSnapshots(
            of: subject,
            as: [.defaultLandscape]
        )
    }

    /// Test the snapshot of the step 3 of the learn new login guided tour.
    @MainActor
    func test_snapshot_loginStep3() {
        processor.state.currentIndex = 2
        processor.state.guidedTourStepStates[2].spotlightRegion = CGRect(x: 40, y: 500, width: 320, height: 90)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark]
        )
    }

    /// Test the snapshot of the step 3 of the learn new login guided tour in landscape.
    @MainActor
    func test_snapshot_loginStep3_landscape() {
        processor.state.currentIndex = 2
        processor.state.guidedTourStepStates[2].spotlightRegion = CGRect(x: 40, y: 60, width: 460, height: 90)
        assertSnapshots(
            of: subject,
            as: [.defaultLandscape]
        )
    }
}
