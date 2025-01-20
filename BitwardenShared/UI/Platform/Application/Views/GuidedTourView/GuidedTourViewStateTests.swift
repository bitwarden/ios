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
            ]
        )
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
}
