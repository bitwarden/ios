import XCTest

@testable import BitwardenShared

class SafariExtensionRequestTests: BitwardenTestCase {
    func test_roundTripDecodeEncode_fillRequest() throws {
        let subject = SafariExtensionRequest(
            kind: .fill,
            loginTitle: "Bitwarden",
            notes: "example",
            oldPassword: nil,
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
                        htmlId: "password",
                        htmlName: "password",
                        labelLeft: "Password",
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
            password: "secret",
            passwordOptions: PasswordGenerationOptions(length: 20, type: .password),
            urlString: "https://example.com/login",
            username: "user@example.com",
        )

        let data = try JSONEncoder().encode(subject)
        let decoded = try JSONDecoder().decode(SafariExtensionRequest.self, from: data)

        XCTAssertEqual(decoded, subject)
        XCTAssertTrue(decoded.canAutofill)
        XCTAssertFalse(decoded.canSaveLogin)
        XCTAssertFalse(decoded.canChangePassword)
        XCTAssertFalse(decoded.canGeneratePassword)
    }

    func test_canSaveLogin_requiresUsernameAndPassword() {
        let subject = SafariExtensionRequest(
            kind: .saveLogin,
            password: "secret",
            urlString: "https://example.com/login",
            username: "user@example.com",
        )

        XCTAssertTrue(subject.canSaveLogin)
        XCTAssertFalse(subject.canAutofill)
    }

    func test_canChangePassword_requiresOldAndNewPassword() {
        let subject = SafariExtensionRequest(
            kind: .changePassword,
            oldPassword: "old-secret",
            password: "new-secret",
            urlString: "https://example.com/change-password",
        )

        XCTAssertTrue(subject.canChangePassword)
        XCTAssertFalse(subject.canSaveLogin)
    }

    func test_canGeneratePassword_trueForGenerateRequest() {
        let subject = SafariExtensionRequest(kind: .generatePassword)

        XCTAssertTrue(subject.canGeneratePassword)
        XCTAssertFalse(subject.canAutofill)
        XCTAssertFalse(subject.canSaveLogin)
        XCTAssertFalse(subject.canChangePassword)
    }
}
