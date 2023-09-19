import XCTest

@testable import BitwardenShared

// MARK: - AlertTests

class AlertTests: XCTestCase {
    // MARK: Properties

    var subject: Alert!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        subject = Alert(title: "🍎", message: "🥝", preferredStyle: .alert)
            .add(AlertAction(title: "Cancel", style: .cancel))
            .addPreferred(AlertAction(title: "OK", style: .default))
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `createAlertController` returns a `UIAlertController` based on the alert details.
    @MainActor
    func test_createAlertController() {
        let alertController = subject.createAlertController()

        XCTAssertEqual(alertController.title, "🍎")
        XCTAssertEqual(alertController.message, "🥝")
        XCTAssertEqual(alertController.preferredStyle, .alert)
        XCTAssertEqual(alertController.actions.count, 2)
        XCTAssertEqual(alertController.actions[0].title, "Cancel")
        XCTAssertEqual(alertController.actions[0].style, .cancel)
        XCTAssertEqual(alertController.actions[1].title, "OK")
        XCTAssertEqual(alertController.actions[1].style, .default)
        XCTAssertEqual(alertController.preferredAction?.title, "OK")
    }

    /// `debugDescription` contains the alert's properties
    func test_debugDescription() {
        XCTAssertEqual(
            subject!.debugDescription,
            "Alert(title: 🍎, message: 🥝, alertActions: [BitwardenShared.AlertAction, BitwardenShared.AlertAction])"
        )
    }

    /// Alert conforms to `Equatable`.
    func test_equatable() {
        XCTAssertEqual(subject, Alert(title: "🍎", message: "🥝", preferredStyle: .alert)
            .add(AlertAction(title: "Cancel", style: .cancel))
            .addPreferred(AlertAction(title: "OK", style: .default)))
        XCTAssertNotEqual(subject, Alert(title: "🍎", message: "🥝", preferredStyle: .alert)
            .add(AlertAction(title: "Cancel", style: .destructive))
            .addPreferred(AlertAction(title: "OK", style: .default)))
        XCTAssertNotEqual(subject, Alert(title: "🍎", message: "🥝", preferredStyle: .alert))
        XCTAssertNotEqual(subject, Alert(title: "🍎", message: "🥝", preferredStyle: .alert)
            .add(AlertAction(title: "Cancel", style: .cancel))
            .addPreferred(AlertAction(title: "OK", style: .default) { _ in }))
    }
}
