import XCTest

@testable import BitwardenShared

class SafariExtensionMatchedLoginResolverTests: BitwardenTestCase {
    func test_resolveContext_withoutMatchedLogin_classifiesSaveNewLogin() async throws {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "secret",
            urlString: "https://example.com/login",
            username: "user@example.com",
        )
        let subject = MockSafariExtensionMatchedLoginResolver(matchedLogin: nil)

        let resolved = try await subject.resolveContext(for: request)

        XCTAssertNil(resolved.matchedLogin)
        XCTAssertEqual(resolved.suggestionAction, .saveLogin)
        XCTAssertEqual(resolved.submissionAction, .saveNewLogin)
    }

    func test_resolveContext_withMatchedLogin_classifiesUpdatePassword() async throws {
        let request = SafariExtensionRequest(
            kind: .changePassword,
            oldPassword: "old-secret",
            password: "new-secret",
            urlString: "https://example.com/change-password",
        )
        let subject = MockSafariExtensionMatchedLoginResolver(
            matchedLogin: SafariExtensionMatchedLogin(
                id: "cipher-1",
                username: "user@example.com",
                password: "old-secret",
                urlString: "https://example.com/login",
            ),
        )

        let resolved = try await subject.resolveContext(for: request)

        XCTAssertEqual(resolved.matchedLogin?.id, "cipher-1")
        XCTAssertEqual(resolved.suggestionAction, .updatePassword)
        XCTAssertEqual(resolved.submissionAction, .updatePassword)
    }
}

private struct MockSafariExtensionMatchedLoginResolver: SafariExtensionMatchedLoginResolving {
    var matchedLogin: SafariExtensionMatchedLogin?

    func resolveMatchedLogin(for request: SafariExtensionRequest) async throws -> SafariExtensionMatchedLogin? {
        matchedLogin
    }
}
