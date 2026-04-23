import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

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

    func test_liveResolver_withNoCipherData_returnsNil() async throws {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "secret",
            urlString: "https://example.com/login",
            username: "user@example.com",
        )
        let subject = SafariExtensionMatchedLoginResolver(
            cipherMatchingHelperFactory: MockCipherMatchingHelperFactory(),
            ciphersClientWrapperService: DefaultCiphersClientWrapperService(
                clientService: MockClientService(),
                errorReporter: MockErrorReporter(),
            ),
            cipherService: MockCipherService(),
            stateService: MockStateService(),
        )

        let matchedLogin = try await subject.resolveMatchedLogin(for: request)

        XCTAssertNil(matchedLogin)
    }

    func test_liveResolver_withMatchingCipher_returnsMatchedLogin() async throws {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "new-secret",
            urlString: "https://example.com/login",
            username: "user@example.com",
        )
        let matchingHelper = MockCipherMatchingHelper()
        matchingHelper.doesCipherMatchClosure = { cipher, _ in
            cipher.id == "cipher-1" ? .exact : .none
        }
        let matchingHelperFactory = MockCipherMatchingHelperFactory()
        matchingHelperFactory.makeReturnValue = matchingHelper
        let clientService = MockClientService()
        clientService.mockVault.clientCiphers.decryptListWithFailuresResultClosure = { ciphers in
            let successes = ciphers.map { cipher in
                CipherListView(
                    id: cipher.id,
                    organizationId: cipher.organizationId,
                    folderId: cipher.folderId,
                    collectionIds: cipher.collectionIds,
                    key: cipher.key,
                    name: cipher.name,
                    subtitle: "",
                    type: .login(.fixture(
                        username: cipher.login?.username,
                        uris: cipher.login?.uris?.map { LoginUriView(loginUri: $0) },
                    )),
                    favorite: cipher.favorite,
                    reprompt: cipher.reprompt,
                    organizationUseTotp: cipher.organizationUseTotp,
                    edit: cipher.edit,
                    permissions: cipher.permissions,
                    viewPassword: cipher.viewPassword,
                    attachments: UInt32(cipher.attachments?.count ?? 0),
                    hasOldAttachments: false,
                    creationDate: cipher.creationDate,
                    deletedDate: cipher.deletedDate,
                    revisionDate: cipher.revisionDate,
                    archivedDate: cipher.archivedDate,
                    copyableFields: [],
                    localData: cipher.localData.map { LocalDataView(localData: $0) },
                )
            }
            return DecryptCipherListResult(successes: successes, failures: [])
        }
        let cipherService = MockCipherService()
        cipherService.fetchAllCiphersResult = .success([
            Cipher.fixture(
                id: "cipher-1",
                login: .fixture(
                    password: "stored-secret",
                    uris: [.fixture(uri: "https://example.com/login")],
                    username: "user@example.com"
                )
            )
        ])
        let subject = SafariExtensionMatchedLoginResolver(
            cipherMatchingHelperFactory: matchingHelperFactory,
            ciphersClientWrapperService: DefaultCiphersClientWrapperService(
                clientService: clientService,
                errorReporter: MockErrorReporter(),
            ),
            cipherService: cipherService,
            stateService: MockStateService(),
        )

        let matchedLogin = try await subject.resolveMatchedLogin(for: request)

        XCTAssertEqual(matchedLogin?.id, "cipher-1")
        XCTAssertEqual(matchedLogin?.username, "user@example.com")
        XCTAssertEqual(matchedLogin?.urlString, "https://example.com/login")
    }
}

private struct MockSafariExtensionMatchedLoginResolver: SafariExtensionMatchedLoginResolving {
    var matchedLogin: SafariExtensionMatchedLogin?

    func resolveMatchedLogin(for request: SafariExtensionRequest) async throws -> SafariExtensionMatchedLogin? {
        matchedLogin
    }
}
