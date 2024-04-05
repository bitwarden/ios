import ViewInspector
import XCTest

@testable import AuthenticatorShared

// MARK: - AsyncButtonTests

class AsyncButtonTests: AuthenticatorTestCase {
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
