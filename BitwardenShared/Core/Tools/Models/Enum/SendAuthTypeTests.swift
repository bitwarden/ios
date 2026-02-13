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

    /// `init(from:)` decodes known values correctly.
    func test_init_decoder_knownValues() throws {
        XCTAssertEqual(try JSONDecoder().decode(SendAuthType.self, from: "0".data(using: .utf8)!), .email)
        XCTAssertEqual(try JSONDecoder().decode(SendAuthType.self, from: "1".data(using: .utf8)!), .password)
        XCTAssertEqual(try JSONDecoder().decode(SendAuthType.self, from: "2".data(using: .utf8)!), .none)
    }

    /// `init(from:)` decodes unknown values to `.unknown`.
    func test_init_decoder_unknownValues() throws {
        XCTAssertEqual(try JSONDecoder().decode(SendAuthType.self, from: "99".data(using: .utf8)!), .unknown)
        XCTAssertEqual(try JSONDecoder().decode(SendAuthType.self, from: "-5".data(using: .utf8)!), .unknown)
    }

    /// `rawValue` returns the correct integer for each auth type.
    func test_rawValue() {
        XCTAssertEqual(SendAuthType.email.rawValue, 0)
        XCTAssertEqual(SendAuthType.password.rawValue, 1)
        XCTAssertEqual(SendAuthType.none.rawValue, 2)
        XCTAssertEqual(SendAuthType.unknown.rawValue, -1)
    }

    /// `sdkAuthType` returns the correct SDK `AuthType` for each auth type.
    func test_sdkAuthType() {
        XCTAssertEqual(SendAuthType.email.sdkAuthType, .email)
        XCTAssertEqual(SendAuthType.password.sdkAuthType, .password)
        XCTAssertEqual(SendAuthType.none.sdkAuthType, .none)
        XCTAssertEqual(SendAuthType.unknown.sdkAuthType, .none)
    }
}
