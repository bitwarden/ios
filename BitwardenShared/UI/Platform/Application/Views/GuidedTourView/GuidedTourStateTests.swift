import XCTest

@testable import BitwardenShared

// MARK: - GuidedTourStateTests

class GuidedTourStateTests: BitwardenTestCase {
    // MARK: Tests

    /// Tests the `progressText` computed property.
    func test_progressText() {
        var subject = GuidedTourState(
            arrowHorizontalPosition: .center,
            step: 1,
            spotlightRegion: .zero,
            spotlightShape: .circle,
            spotlightCornerRadius: 8,
            totalStep: 3,
            title: ""
        )
        XCTAssertEqual(subject.progressText, "1 OF 3")

        subject.step = 2
        XCTAssertEqual(subject.progressText, "2 OF 3")

        subject.step = 3
        XCTAssertEqual(subject.progressText, "3 OF 3")
    }
}
