import XCTest

@testable import BitwardenShared

class CheckoutSessionRequestModelTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(platform:)` initializes `CheckoutSessionRequestModel` with the correct values.
    func test_init() {
        let subject = CheckoutSessionRequestModel(platform: "ios")
        XCTAssertEqual(subject.platform, "ios")
    }

    /// Validates encoding the model to JSON.
    func test_encode() throws {
        let subject = CheckoutSessionRequestModel(platform: "ios")
        let encoder = JSONEncoder()
        let data = try encoder.encode(subject)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"platform\":\"ios\""))
    }
}
