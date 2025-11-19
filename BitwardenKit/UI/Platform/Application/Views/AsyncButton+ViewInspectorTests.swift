// swiftlint:disable:this file_name
import BitwardenKit
import ViewInspector
import XCTest

// MARK: - AsyncButtonTests

class AsyncButtonTests: BitwardenTestCase {
    // MARK: Tests

    func test_button_tap() throws {
        var didTap = false
        let subject = AsyncButton("Test") {
            didTap = true
        }

        let button = try subject.inspect().find(button: "Test")
        try button.tap()

        waitFor(didTap)
        XCTAssertTrue(didTap)
    }
}
