import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - SendAuthTypeTests

class SendAuthTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(authType:)` correctly initializes from SDK `AuthType`.
    func test_init_authType() {
        XCTAssertEqual(SendAuthType(authType: .email), .email)
        XCTAssertEqual(SendAuthType(authType: .password), .password)
        XCTAssertEqual(SendAuthType(authType: .none), .none)
    }

    /// `rawValue` returns the correct integer for each auth type.
    func test_rawValue() {
        XCTAssertEqual(SendAuthType.email.rawValue, 0)
        XCTAssertEqual(SendAuthType.password.rawValue, 1)
        XCTAssertEqual(SendAuthType.none.rawValue, 2)
    }

    /// `sdkAuthType` returns the correct SDK `AuthType` for each auth type.
    func test_sdkAuthType() {
        XCTAssertEqual(SendAuthType.email.sdkAuthType, .email)
        XCTAssertEqual(SendAuthType.password.sdkAuthType, .password)
        XCTAssertEqual(SendAuthType.none.sdkAuthType, .none)
    }
}
