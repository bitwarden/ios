import XCTest

@testable import BitwardenShared

// MARK: - GuidedTourViewStateTests

class GuidedTourViewStateTests: BitwardenTestCase {
    // MARK: Properties

    var subject: GuidedTourViewState!

    override func setUp() {
        super.setUp()
        subject = GuidedTourViewState(
            currentIndex: 0,
            guidedTourStepStates: [
                .loginStep1,
                .loginStep2,
                .loginStep3,
            ],
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// Tests the `currentStepState` computed property.
    func test_currentStepState() {
        XCTAssertEqual(subject.currentStepState, .loginStep1)

        subject.currentIndex = 1
        XCTAssertEqual(subject.currentStepState, .loginStep2)

        subject.currentIndex = 2
        XCTAssertEqual(subject.currentStepState, .loginStep3)
    }

    /// Tests the `progressText` computed property.
    func test_progressText() {
        XCTAssertEqual(subject.progressText, "1 OF 3")

        subject.currentIndex = 1
        XCTAssertEqual(subject.progressText, "2 OF 3")

        subject.currentIndex = 2
        XCTAssertEqual(subject.progressText, "3 OF 3")
    }

    /// Tests the `step` computed property.
    func test_step() {
        XCTAssertEqual(subject.step, 1)

        subject.currentIndex = 1
        XCTAssertEqual(subject.step, 2)

        subject.currentIndex = 2
        XCTAssertEqual(subject.step, 3)
    }

    /// Tests the `totalSteps` computed property.
    func test_totalSteps() {
        XCTAssertEqual(subject.totalSteps, 3)
    }

    /// Tests the `updateStateForGuidedTourViewAction(_:)` method with `.backTapped` action.
    func test_updateStateForGuidedTourViewAction_backTapped() {
        subject.currentIndex = 1
        subject.updateStateForGuidedTourViewAction(.backTapped)
        XCTAssertEqual(subject.currentIndex, 0)
    }

    /// Tests the `updateStateForGuidedTourViewAction(_:)` method with `.didRenderViewToSpotlight` action.
    func test_updateStateForGuidedTourViewAction_didRenderViewToSpotlight() {
        let frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        subject.updateStateForGuidedTourViewAction(.didRenderViewToSpotlight(frame: frame, step: .step1))
        XCTAssertEqual(subject.guidedTourStepStates[0].spotlightRegion, frame)
    }

    /// Tests the `updateStateForGuidedTourViewAction(_:)` method with `.dismissTapped` action.
    func test_updateStateForGuidedTourViewAction_dismissTapped() {
        subject.showGuidedTour = true
        subject.updateStateForGuidedTourViewAction(.dismissTapped)
        XCTAssertFalse(subject.showGuidedTour)
    }

    /// Tests the `updateStateForGuidedTourViewAction(_:)` method with `.doneTapped` action.
    func test_updateStateForGuidedTourViewAction_doneTapped() {
        subject.showGuidedTour = true
        subject.updateStateForGuidedTourViewAction(.doneTapped)
        XCTAssertFalse(subject.showGuidedTour)
    }

    /// Tests the `updateStateForGuidedTourViewAction(_:)` method with `.nextTapped` action.
    func test_updateStateForGuidedTourViewAction_nextTapped() {
        subject.updateStateForGuidedTourViewAction(.nextTapped)
        XCTAssertEqual(subject.currentIndex, 1)
    }

    /// Tests the `updateStateForGuidedTourViewAction(_:)` method with `.toggleGuidedTourVisibilityChanged` action.
    func test_updateStateForGuidedTourViewAction_toggleGuidedTourVisibilityChanged() {
        subject.updateStateForGuidedTourViewAction(.toggleGuidedTourVisibilityChanged(true))
        XCTAssertTrue(subject.showGuidedTour)

        subject.updateStateForGuidedTourViewAction(.toggleGuidedTourVisibilityChanged(false))
        XCTAssertFalse(subject.showGuidedTour)
    }
}
