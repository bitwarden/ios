import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared

class SafariExtensionRequestProcessorTests: BitwardenTestCase {
    func test_makeResponse_generatePassword_returnsGeneratedPasswordResponse() throws {
        let subject = SafariExtensionRequestProcessor(
            passwordGenerator: { _ in "generated-secret" }
        )

        let response = try XCTUnwrap(subject.makeResponse(for: SafariExtensionRequest(kind: .generatePassword)))

        XCTAssertEqual(response.generatedPassword, "generated-secret")
        XCTAssertEqual(response.submissionAction, .generatePassword)
    }

    func test_makeResponse_changePasswordWithMatchedLogin_returnsUpdatePasswordMessage() async throws {
        let request = SafariExtensionRequest(
            kind: .changePassword,
            oldPassword: "old-secret",
            password: "new-secret",
            urlString: "https://example.com/change-password"
        )
        let subject = SafariExtensionRequestProcessor(
            matchedLoginResolver: MockSafariExtensionMatchedLoginResolver(
                matchedLogin: SafariExtensionMatchedLogin(
                    id: "cipher-1",
                    username: "user@example.com",
                    password: "old-secret",
                    urlString: "https://example.com/login"
                )
            )
        )

        let maybeResponse = await subject.makeResponse(for: request)
        let response = try XCTUnwrap(maybeResponse)

        XCTAssertEqual(response.suggestionAction, .updatePassword)
        XCTAssertEqual(response.submissionAction, .updatePassword)
        XCTAssertEqual(response.userMessage, "updatePassword")
    }

    @MainActor
    func test_liveProcessor_withMockServices_makeResponse_generatePasswordReturnsResponse() async throws {
        let subject = SafariExtensionRequestProcessor.live(services: ServiceContainer.withMocks())

        let maybeResponse = await subject.makeResponse(for: SafariExtensionRequest(kind: .generatePassword))
        let response = try XCTUnwrap(maybeResponse)

        XCTAssertEqual(response.submissionAction, .generatePassword)
        XCTAssertNotNil(response.generatedPassword)
        XCTAssertFalse(response.generatedPassword?.isEmpty ?? true)
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

    func test_makeResponse_fillWithMatchedLogin_returnsFillScriptResponse() async throws {
        let request = SafariExtensionRequest(
            kind: .fill,
            pageDetails: makePageDetails(),
            urlString: "https://example.com/login"
        )
        let subject = SafariExtensionRequestProcessor(
            matchedLoginResolver: MockSafariExtensionMatchedLoginResolver(
                matchedLogin: SafariExtensionMatchedLogin(
                    id: "cipher-1",
                    username: "user@example.com",
                    password: "secret",
                    urlString: "https://example.com/login"
                )
            )
        )

        let maybeResponse = await subject.makeResponse(for: request)
        let response = try XCTUnwrap(maybeResponse)

        XCTAssertEqual(response.submissionAction, .fill)
        XCTAssertEqual(response.matchedLogin?.id, "cipher-1")
        XCTAssertTrue(response.canFinalizeWithScript)
    }

    func test_makeResponse_saveLoginWithMatchedLogin_returnsUpdateExistingLoginMessage() async throws {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "new-secret",
            urlString: "https://example.com/login",
            username: "user@example.com"
        )
        let subject = SafariExtensionRequestProcessor(
            matchedLoginResolver: MockSafariExtensionMatchedLoginResolver(
                matchedLogin: SafariExtensionMatchedLogin(
                    id: "cipher-1",
                    username: "user@example.com",
                    password: "old-secret",
                    urlString: "https://example.com/login"
                )
            )
        )

        let maybeResponse = await subject.makeResponse(for: request)
        let response = try XCTUnwrap(maybeResponse)

        XCTAssertEqual(response.submissionAction, .updateExistingLogin)
        XCTAssertEqual(response.userMessage, "updateExistingLogin")
    }

    private func makePageDetails() -> PageDetails {
        PageDetails(
            collectedTimestamp: Date(timeIntervalSince1970: 1_715_000_000),
            documentUUID: "doc-1",
            documentUrl: "https://example.com/login",
            fields: [
                PageDetails.Field(
                    disabled: false,
                    elementNumber: 0,
                    form: "form__0",
                    htmlClass: nil,
                    htmlId: "username",
                    htmlName: "username",
                    labelLeft: nil,
                    labelRight: nil,
                    labelTag: "Username",
                    onepasswordFieldType: nil,
                    opId: "field__0",
                    placeholder: nil,
                    readOnly: false,
                    type: "text",
                    value: nil,
                    viewable: true,
                    visible: true
                ),
                PageDetails.Field(
                    disabled: false,
                    elementNumber: 1,
                    form: "form__0",
                    htmlClass: nil,
                    htmlId: "password",
                    htmlName: "password",
                    labelLeft: nil,
                    labelRight: nil,
                    labelTag: "Password",
                    onepasswordFieldType: nil,
                    opId: "field__1",
                    placeholder: nil,
                    readOnly: false,
                    type: "password",
                    value: nil,
                    viewable: true,
                    visible: true
                )
            ],
            forms: [
                "form__0": PageDetails.Form(
                    htmlAction: "https://example.com/login",
                    htmlId: "login-form",
                    htmlMethod: "post",
                    htmlName: "login",
                    opId: "form__0"
                )
            ],
            tabUrl: "https://example.com/login",
            title: "Example",
            url: "https://example.com/login"
        )
    }
}

private struct MockSafariExtensionMatchedLoginResolver: SafariExtensionMatchedLoginResolving {
    var matchedLogin: SafariExtensionMatchedLogin?

    func resolveMatchedLogin(for request: SafariExtensionRequest) async throws -> SafariExtensionMatchedLogin? {
        matchedLogin
    }
}
