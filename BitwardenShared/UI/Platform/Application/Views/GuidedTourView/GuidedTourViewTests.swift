import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - GuidedTourViewTests

class GuidedTourViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<GuidedTourState, GuidedTourViewAction, Void>!
    var subject: GuidedTourView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(
            state: .loginStep1
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

    /// Tap the `back` button should dispatch the `backPressed` action.
    @MainActor
    func test_backButton_tap() async throws {
        processor.state = .loginStep2
        let button = try subject.inspect().find(button: Localizations.back)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.backPressed])
    }

    /// Tapping the `done` button should dispatch the `donePressed` action.
    @MainActor
    func test_doneButton_tap() async throws {
        processor.state = .loginStep3
        let button = try subject.inspect().find(button: Localizations.done)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.donePressed])
    }

    /// Tapping the dismiss button dispatches the `.dismissPressed` action.
    @MainActor
    func test_dismissButton_tap() async throws {
        processor.state = .loginStep3
        let button = try subject.inspect().find(button: Localizations.dismiss)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.dismissPressed])
    }

    /// Tapping the `next` button should dispatch the `nextPressed` action.
    @MainActor
    func test_nextButton_tap() async throws {
        let button = try subject.inspect().find(button: Localizations.next)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.nextPressed])
    }

    /// Test the snapshot of the step 1 of the learn new login guided tour.
    @MainActor
    func test_snapshot_loginStep1() {
        processor.state.spotlightRegion = CGRect(x: 320, y: 470, width: 40, height: 40)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark]
        )
    }

    /// Test the snapshot of the step 1 of the learn new login guided tour in landscape.
    @MainActor
    func test_snapshot_loginStep1_landscape() {
        processor.state.spotlightRegion = CGRect(x: 650, y: 150, width: 40, height: 40)
        assertSnapshots(
            of: subject,
            as: [.defaultLandscape]
        )
    }

    /// Test the snapshot of the step 2 of the learn new login guided tour.
    @MainActor
    func test_snapshot_loginStep2() {
        processor.state = .loginStep2
        processor.state.spotlightRegion = CGRect(x: 40, y: 470, width: 320, height: 95)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark]
        )
    }

    /// Test the snapshot of the step 2 of the learn new login guided tour in landscape.
    @MainActor
    func test_snapshot_loginStep2_landscape() {
        processor.state = .loginStep2
        processor.state.spotlightRegion = CGRect(x: 40, y: 60, width: 460, height: 95)
        assertSnapshots(
            of: subject,
            as: [.defaultLandscape]
        )
    }

    /// Test the snapshot of the step 3 of the learn new login guided tour.
    @MainActor
    func test_snapshot_loginStep3() {
        processor.state = .loginStep3
        processor.state.spotlightRegion = CGRect(x: 40, y: 500, width: 320, height: 90)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark]
        )
    }

    /// Test the snapshot of the step 3 of the learn new login guided tour in landscape.
    @MainActor
    func test_snapshot_loginStep3_landscape() {
        processor.state = .loginStep3
        processor.state.spotlightRegion = CGRect(x: 40, y: 60, width: 460, height: 90)
        assertSnapshots(
            of: subject,
            as: [.defaultLandscape]
        )
    }
}
