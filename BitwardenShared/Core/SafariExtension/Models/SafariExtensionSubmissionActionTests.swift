import XCTest

@testable import BitwardenShared

class SafariExtensionSubmissionActionTests: BitwardenTestCase {
    func test_classify_fill_withoutMatchedLogin_returnsFill() {
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
            )
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: nil), .fill)
    }

    func test_classify_saveLogin_withoutMatchedLogin_returnsSaveNewLogin() {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "secret",
            urlString: "https://example.com/login",
            username: "new-user@example.com",
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: nil), .saveNewLogin)
    }

    func test_classify_saveLogin_withMatchedLoginAndDifferentPassword_returnsUpdateExistingLogin() {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "new-secret",
            urlString: "https://example.com/login",
            username: "user@example.com",
        )
        let matchedLogin = SafariExtensionMatchedLogin(
            id: "cipher-1",
            username: "user@example.com",
            password: "old-secret",
            urlString: "https://example.com/login",
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin), .updateExistingLogin)
    }

    func test_classify_changePassword_withMatchedLogin_returnsUpdatePassword() {
        let request = SafariExtensionRequest(
            kind: .changePassword,
            oldPassword: "old-secret",
            password: "new-secret",
            urlString: "https://example.com/change-password",
        )
        let matchedLogin = SafariExtensionMatchedLogin(
            id: "cipher-1",
            username: "user@example.com",
            password: "old-secret",
            urlString: "https://example.com/login",
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin), .updatePassword)
    }

    func test_classify_saveLogin_withMatchedLoginAndDifferentUsername_returnsSaveNewLogin() {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "secret",
            urlString: "https://example.com/login",
            username: "second-user@example.com",
        )
        let matchedLogin = SafariExtensionMatchedLogin(
            id: "cipher-1",
            username: "first-user@example.com",
            password: "secret",
            urlString: "https://example.com/login",
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin), .saveNewLogin)
    }

    func test_classify_changePassword_withMismatchedOldPassword_returnsNone() {
        let request = SafariExtensionRequest(
            kind: .changePassword,
            oldPassword: "typed-old-secret",
            password: "new-secret",
            urlString: "https://example.com/change-password",
        )
        let matchedLogin = SafariExtensionMatchedLogin(
            id: "cipher-1",
            username: "user@example.com",
            password: "different-stored-secret",
            urlString: "https://example.com/login",
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin), .none)
    }

    func test_classify_incompleteRequest_returnsNone() {
        XCTAssertEqual(
            SafariExtensionSubmissionAction.classify(
                SafariExtensionRequest(kind: .saveLogin),
                matchedLogin: nil,
            ),
            .none,
        )
    }
}
