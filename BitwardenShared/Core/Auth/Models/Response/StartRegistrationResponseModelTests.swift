import XCTest

@testable import BitwardenShared

// MARK: - StartRegistrationResponseModelTests

class StartRegistrationResponseModelTests: BitwardenTestCase {
    /// Tests that a response is initialized correctly.
    func test_init() {
        let subject = StartRegistrationResponseModel(
            emailVerificationToken: "emailVerificationToken",
            captchaBypassToken: "captchaBypassToken"
        )
        XCTAssertEqual(subject.captchaBypassToken, "captchaBypassToken")
        XCTAssertEqual(subject.emailVerificationToken, "emailVerificationToken")
    }

    /// Tests the successful decoding of a JSON response.
    func test_decode_success() throws {
        let json = APITestData.startRegistrationSuccess.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(StartRegistrationResponseModel.self, from: json)
        XCTAssertEqual(subject.captchaBypassToken, "captchaBypassToken")
        XCTAssertEqual(subject.emailVerificationToken, "emailVerificationToken")
    }
}
