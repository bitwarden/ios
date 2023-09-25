import XCTest

@testable import BitwardenShared

class AlertErrorTests: BitwardenTestCase {
    /// `defaultAlert(title:message:)` constructs an `Alert` with the title, message, and an OK button.
    func test_defaultAlert() {
        let subject = Alert.defaultAlert(title: "title", message: "message")

        XCTAssertEqual(subject.title, "title")
        XCTAssertEqual(subject.message, "message")
        XCTAssertEqual(subject.alertActions, [AlertAction(title: "Ok", style: .cancel)])
    }
}
