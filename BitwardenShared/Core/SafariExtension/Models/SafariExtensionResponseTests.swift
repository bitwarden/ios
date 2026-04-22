import XCTest

@testable import BitwardenShared

class SafariExtensionResponseTests: BitwardenTestCase {
    func test_fill_buildsEncodedFillScriptResponse() throws {
        let subject = try SafariExtensionResponse.fill(
            request: makeFillRequest(),
            username: "user@example.com",
            password: "secret",
            fields: [("otp", "123456")],
            matchedLogin: nil,
        )

        XCTAssertEqual(subject.suggestionAction, .fill)
        XCTAssertEqual(subject.submissionAction, .fill)
        XCTAssertTrue(subject.canFinalizeWithScript)
        XCTAssertNil(subject.generatedPassword)

        let fillScriptJSON = try XCTUnwrap(subject.fillScriptJSON)
        let scriptData = try XCTUnwrap(fillScriptJSON.data(using: .utf8))
        let fillScript = try JSONDecoder().decode(FillScript.self, from: scriptData)
        XCTAssertEqual(fillScript.documentUUID, "doc-1")
        XCTAssertFalse(fillScript.script.isEmpty)
    }

    func test_generatedPassword_buildsGeneratePasswordResponse() throws {
        let request = SafariExtensionRequest(kind: .generatePassword)

        let subject = try SafariExtensionResponse.generatedPassword("generated-secret", for: request)

        XCTAssertEqual(subject.suggestionAction, .generatePassword)
        XCTAssertEqual(subject.submissionAction, .generatePassword)
        XCTAssertEqual(subject.generatedPassword, "generated-secret")
        XCTAssertTrue(subject.hasGeneratedPassword)
        XCTAssertFalse(subject.canFinalizeWithScript)
    }

    func test_fill_withoutAutofillableRequest_throws() {
        let request = SafariExtensionRequest(kind: .fill)

        XCTAssertThrowsError(
            try SafariExtensionResponse.fill(
                request: request,
                username: "user@example.com",
                password: "secret",
                fields: [],
                matchedLogin: nil,
            )
        )
    }

    func test_generatedPassword_withNonGenerateRequest_throws() {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "secret",
            urlString: "https://example.com/login",
            username: "user@example.com",
        )

        XCTAssertThrowsError(try SafariExtensionResponse.generatedPassword("generated-secret", for: request))
    }

    func test_roundTripEncodeDecode_saveNewLoginResponse() throws {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "secret",
            urlString: "https://example.com/login",
            username: "user@example.com",
        )
        let subject = SafariExtensionResponse(
            request: request,
            suggestionAction: .saveLogin,
            submissionAction: .saveNewLogin,
            matchedLogin: nil,
            fillScriptJSON: nil,
            generatedPassword: nil,
            userMessage: "Save login",
        )

        let data = try JSONEncoder().encode(subject)
        let decoded = try JSONDecoder().decode(SafariExtensionResponse.self, from: data)

        XCTAssertEqual(decoded, subject)
        XCTAssertFalse(decoded.canFinalizeWithScript)
        XCTAssertFalse(decoded.hasGeneratedPassword)
    }

    private func makeFillRequest() -> SafariExtensionRequest {
        SafariExtensionRequest(
            kind: .fill,
            pageDetails: PageDetails(
                collectedTimestamp: Date(timeIntervalSince1970: 1_715_000_000),
                documentUUID: "doc-1",
                documentUrl: "https://example.com/login",
                fields: [
                    PageDetails.Field(
                        disabled: false,
                        elementNumber: 1,
                        form: "login-form",
                        htmlClass: nil,
                        htmlId: "email",
                        htmlName: "email",
                        labelLeft: nil,
                        labelRight: nil,
                        labelTag: "Email",
                        onepasswordFieldType: nil,
                        opId: "username-field",
                        placeholder: "Email",
                        readOnly: false,
                        type: "email",
                        value: nil,
                        viewable: true,
                        visible: true,
                    ),
                    PageDetails.Field(
                        disabled: false,
                        elementNumber: 2,
                        form: "login-form",
                        htmlClass: nil,
                        htmlId: "password",
                        htmlName: "password",
                        labelLeft: nil,
                        labelRight: nil,
                        labelTag: "Password",
                        onepasswordFieldType: nil,
                        opId: "password-field",
                        placeholder: "Password",
                        readOnly: false,
                        type: "password",
                        value: nil,
                        viewable: true,
                        visible: true,
                    ),
                ],
                forms: [
                    "login-form": PageDetails.Form(
                        htmlAction: "/login",
                        htmlId: "login-form",
                        htmlMethod: "post",
                        htmlName: "login",
                        opId: "login-form",
                    ),
                ],
                tabUrl: "https://example.com/login",
                title: "Login",
                url: "https://example.com/login",
            ),
            urlString: "https://example.com/login",
        )
    }
}
