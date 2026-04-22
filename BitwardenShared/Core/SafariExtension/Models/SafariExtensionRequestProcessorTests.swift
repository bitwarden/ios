import XCTest

@testable import BitwardenShared

class SafariExtensionRequestProcessorTests: BitwardenTestCase {
    func test_makeResponse_generatePassword_returnsGeneratedPasswordResponse() throws {
        let subject = SafariExtensionRequestProcessor()

        let response = try XCTUnwrap(subject.makeResponse(for: SafariExtensionRequest(kind: .generatePassword)))

        XCTAssertEqual(response.generatedPassword, "generated-password")
        XCTAssertEqual(response.submissionAction, .generatePassword)
    }

    func test_makeResponse_setup_returnsSetupMessage() throws {
        let subject = SafariExtensionRequestProcessor()

        let response = try XCTUnwrap(subject.makeResponse(for: SafariExtensionRequest(kind: .setup)))

        XCTAssertEqual(response.userMessage, "Safari Web Extension setup")
        XCTAssertEqual(response.submissionAction, .none)
    }

    func test_makeResponse_saveLogin_returnsSuggestedAction() throws {
        let subject = SafariExtensionRequestProcessor()
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "secret",
            urlString: "https://example.com/login",
            username: "user@example.com"
        )

        let response = try XCTUnwrap(subject.makeResponse(for: request))

        XCTAssertEqual(response.suggestionAction, .saveLogin)
        XCTAssertEqual(response.submissionAction, .saveNewLogin)
        XCTAssertEqual(response.userMessage, "saveLogin")
    }
}
