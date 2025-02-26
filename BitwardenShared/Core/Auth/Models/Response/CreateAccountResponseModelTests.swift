import XCTest

@testable import BitwardenShared

// MARK: - CreateAccountResponseModelTests

class CreateAccountResponseModelTests: BitwardenTestCase {
    /// Tests that a response is initialized correctly.
    func test_init() {
        let subject = CreateAccountResponseModel(captchaBypassToken: "captchaBypassToken")
        XCTAssertEqual(subject.captchaBypassToken, "captchaBypassToken")
    }

    /// Tests the successful decoding of a JSON response.
    func test_decode_success() throws {
        let json = APITestData.createAccountSuccess.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(CreateAccountResponseModel.self, from: json)
        XCTAssertEqual(subject.captchaBypassToken, "captchaBypassToken")
    }
}
