import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - RegisterFinishResponseModelTests

class RegisterFinishResponseModelTests: BitwardenTestCase {
    /// Tests that a response is initialized correctly.
    func test_init() {
        let subject = RegisterFinishResponseModel(captchaBypassToken: "captchaBypassToken")
        XCTAssertEqual(subject.captchaBypassToken, "captchaBypassToken")
    }

    /// Tests the successful decoding of a JSON response.
    func test_decode_success() throws {
        let json = APITestData.registerFinishSuccess.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(RegisterFinishResponseModel.self, from: json)
        XCTAssertEqual(subject.captchaBypassToken, "captchaBypassToken")
    }
}
