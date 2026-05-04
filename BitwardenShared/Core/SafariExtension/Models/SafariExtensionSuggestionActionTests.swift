import XCTest

@testable import BitwardenShared

class SafariExtensionSuggestionActionTests: BitwardenTestCase {
    func test_from_fillRequest_returnsFill() {
        let request = SafariExtensionRequest(
            kind: .fill,
            pageDetails: PageDetails(
                collectedTimestamp: Date(timeIntervalSince1970: 1_715_000_000),
                documentUUID: "doc-1",
                documentUrl: "https://example.com/login",
                fields: [
                    PageDetails.Field(
                        disabled: false,
                        elementNumber: 1,
                        form: nil,
                        htmlClass: nil,
                        htmlId: "password",
                        htmlName: "password",
                        labelLeft: nil,
                        labelRight: nil,
                        labelTag: nil,
                        onepasswordFieldType: nil,
                        opId: "password-field",
                        placeholder: nil,
                        readOnly: false,
                        type: "password",
                        value: nil,
                        viewable: true,
                        visible: true,
                    ),
                ],
                forms: [:],
                tabUrl: "https://example.com/login",
                title: "Login",
                url: "https://example.com/login",
            ),
        )

        XCTAssertEqual(SafariExtensionSuggestionAction.from(request), .fill)
    }

    func test_from_saveLoginRequest_returnsSaveLogin() {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "secret",
            urlString: "https://example.com/login",
            username: "user@example.com",
        )

        XCTAssertEqual(SafariExtensionSuggestionAction.from(request), .saveLogin)
    }

    func test_from_changePasswordRequest_returnsUpdatePassword() {
        let request = SafariExtensionRequest(
            kind: .changePassword,
            oldPassword: "old-secret",
            password: "new-secret",
            urlString: "https://example.com/change-password",
        )

        XCTAssertEqual(SafariExtensionSuggestionAction.from(request), .updatePassword)
    }

    func test_from_changePasswordRequestWithoutOldPassword_returnsUpdatePassword() {
        let request = SafariExtensionRequest(
            kind: .changePassword,
            oldPassword: nil,
            password: "new-secret",
            urlString: "https://example.com/reset-password",
        )

        XCTAssertEqual(SafariExtensionSuggestionAction.from(request), .updatePassword)
    }

    func test_from_generatePasswordRequest_returnsGeneratePassword() {
        let request = SafariExtensionRequest(kind: .generatePassword)

        XCTAssertEqual(SafariExtensionSuggestionAction.from(request), .generatePassword)
    }

    func test_from_incompleteRequest_returnsNone() {
        let request = SafariExtensionRequest(kind: .saveLogin)

        XCTAssertEqual(SafariExtensionSuggestionAction.from(request), .none)
    }
}
