import XCTest

@testable import BitwardenShared

// MARK: - LandingStateTests

class LandingStateTests: BitwardenTestCase {
    // MARK: Tests

    func test_isContinueButtonEnabled_emailEmpty() {
        let subject = LandingState(email: "")
        XCTAssertFalse(subject.isContinueButtonEnabled)
    }

    func test_isContinueButtonEnabled_emailOneCharacter() {
        let subject = LandingState(email: "e")
        XCTAssertTrue(subject.isContinueButtonEnabled)
    }

    func test_isContinueButtonEnabled_emailValue() {
        let subject = LandingState(email: "email@example.com")
        XCTAssertTrue(subject.isContinueButtonEnabled)
    }
}
