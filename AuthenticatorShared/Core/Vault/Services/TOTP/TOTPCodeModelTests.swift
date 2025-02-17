import Foundation
import XCTest

@testable import AuthenticatorShared

final class TOTPCodeModelTests: AuthenticatorTestCase {
    // MARK: Tests

    /// `displayCode` groups digits correctly
    func test_displayCode_spaces() {
        XCTAssertEqual(model(for: "12345").displayCode, "123 45")
        XCTAssertEqual(model(for: "123456").displayCode, "123 456")
        XCTAssertEqual(model(for: "1234567").displayCode, "123 456 7")
        XCTAssertEqual(model(for: "12345678").displayCode, "123 456 78")
        XCTAssertEqual(model(for: "123456789").displayCode, "123 456 789")
        XCTAssertEqual(model(for: "1234567890").displayCode, "123 456 789 0")
    }

    // MARK: Private Methods

    func model(for code: String) -> TOTPCodeModel {
        TOTPCodeModel(code: code, codeGenerationDate: Date(), period: 30)
    }
}
