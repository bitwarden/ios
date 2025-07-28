import BitwardenResources
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - GuidedTourView+LoginTests

class GuidedTourViewTests: BitwardenTestCase {
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
}
