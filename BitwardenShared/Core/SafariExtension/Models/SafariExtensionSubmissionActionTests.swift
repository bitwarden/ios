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

    func test_classify_changePasswordWithoutOldPassword_withMatchedLogin_returnsUpdatePassword() {
        let request = SafariExtensionRequest(
            kind: .changePassword,
            oldPassword: nil,
            password: "new-secret",
            urlString: "https://example.com/reset-password",
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

    func test_classify_saveLogin_withMissingUsernameAndMatchingURL_returnsUpdateExistingLogin() {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "new-secret",
            urlString: "https://example.com/login",
            username: nil,
        )
        let matchedLogin = SafariExtensionMatchedLogin(
            id: "cipher-1",
            username: "user@example.com",
            password: "old-secret",
            urlString: "https://example.com/login",
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin), .updateExistingLogin)
    }

    func test_classify_saveLogin_withMissingUsernameAndDifferentURL_returnsSaveNewLogin() {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "new-secret",
            urlString: "https://example.com/register",
            username: nil,
        )
        let matchedLogin = SafariExtensionMatchedLogin(
            id: "cipher-1",
            username: "user@example.com",
            password: "old-secret",
            urlString: "https://example.com/login",
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin), .saveNewLogin)
    }

    func test_classify_saveLogin_withMissingUsernameAndSameOriginLoginPath_returnsUpdateExistingLogin() {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "new-secret",
            urlString: "https://example.com/sign-in?ref=header",
            username: nil,
        )
        let matchedLogin = SafariExtensionMatchedLogin(
            id: "cipher-1",
            username: "user@example.com",
            password: "old-secret",
            urlString: "https://example.com/login",
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin), .updateExistingLogin)
    }

    func test_classify_saveLogin_withMissingUsernameAndDifferentOrigin_returnsSaveNewLogin() {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "new-secret",
            urlString: "https://accounts.example.net/sign-in",
            username: nil,
        )
        let matchedLogin = SafariExtensionMatchedLogin(
            id: "cipher-1",
            username: "user@example.com",
            password: "old-secret",
            urlString: "https://example.com/login",
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin), .saveNewLogin)
    }

    func test_classify_saveLogin_withMissingUsernameAndSignupLikeAuthPath_returnsSaveNewLogin() {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "new-secret",
            urlString: "https://example.com/auth/register",
            username: nil,
        )
        let matchedLogin = SafariExtensionMatchedLogin(
            id: "cipher-1",
            username: "user@example.com",
            password: "old-secret",
            urlString: "https://example.com/login",
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin), .saveNewLogin)
    }

    func test_classify_saveLogin_withMissingUsernameAndSignupSurface_returnsSaveNewLogin() {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            pageDetails: testMakePageDetails(
                title: "Create your account",
                formIdentifier: "signup-form",
                passwordLabel: "Create password"
            ),
            password: "new-secret",
            urlString: "https://example.com/account",
            username: nil,
        )
        let matchedLogin = SafariExtensionMatchedLogin(
            id: "cipher-1",
            username: "user@example.com",
            password: "old-secret",
            urlString: "https://example.com/login",
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin), .saveNewLogin)
    }

    func test_classify_saveLogin_withMissingUsernameAndLoginSurface_returnsUpdateExistingLogin() {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            pageDetails: testMakePageDetails(
                title: "Sign in to Example",
                formIdentifier: "login-form",
                passwordLabel: "Password"
            ),
            password: "new-secret",
            urlString: "https://example.com/account",
            username: nil,
        )
        let matchedLogin = SafariExtensionMatchedLogin(
            id: "cipher-1",
            username: "user@example.com",
            password: "old-secret",
            urlString: "https://example.com/login",
        )

        XCTAssertEqual(SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin), .updateExistingLogin)
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

private func testMakePageDetails(
    title: String,
    formIdentifier: String,
    passwordLabel: String
) -> PageDetails {
    PageDetails(
        collectedTimestamp: Date(timeIntervalSince1970: 1_715_000_000),
        documentUUID: "doc-surface",
        documentUrl: "https://example.com/account",
        fields: [
            PageDetails.Field(
                disabled: false,
                elementNumber: 1,
                form: formIdentifier,
                htmlClass: nil,
                htmlId: "password",
                htmlName: "password",
                labelLeft: nil,
                labelRight: nil,
                labelTag: passwordLabel,
                onepasswordFieldType: nil,
                opId: "password-field",
                placeholder: passwordLabel,
                readOnly: false,
                type: "password",
                value: nil,
                viewable: true,
                visible: true
            ),
        ],
        forms: [
            formIdentifier: PageDetails.Form(
                htmlAction: "https://example.com/account",
                htmlId: formIdentifier,
                htmlMethod: "post",
                htmlName: formIdentifier,
                opId: formIdentifier
            ),
        ],
        tabUrl: "https://example.com/account",
        title: title,
        url: "https://example.com/account"
    )
}
