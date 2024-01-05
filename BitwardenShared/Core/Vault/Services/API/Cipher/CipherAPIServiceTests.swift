import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class CipherAPIServiceTests: XCTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: APIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()

        subject = APIService(client: client)
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        subject = nil
    }

    // MARK: Tests

    /// `addCipher()` performs the add cipher request and decodes the response.
    func test_addCipher() async throws {
        client.result = .httpSuccess(testData: .cipherResponse)

        let response = try await subject.addCipher(.fixture())

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers")

        XCTAssertEqual(
            response,
            CipherDetailsResponseModel(
                attachments: nil,
                card: nil,
                collectionIds: nil,
                creationDate: Date(timeIntervalSince1970: 1_691_656_425.345),
                deletedDate: nil,
                edit: true,
                favorite: false,
                fields: nil,
                folderId: nil,
                id: "3792af7a-4441-11ee-be56-0242ac120002",
                identity: nil,
                key: nil,
                login: CipherLoginModel(
                    autofillOnPageLoad: nil,
                    password: "encrypted password",
                    passwordRevisionDate: nil,
                    totp: nil,
                    uris: [CipherLoginUriModel(match: nil, uri: "encrypted uri")],
                    username: "encrypted username"
                ),
                name: "encrypted name",
                notes: nil,
                organizationId: nil,
                organizationUseTotp: false,
                passwordHistory: nil,
                reprompt: .none,
                revisionDate: Date(timeIntervalSince1970: 1_691_656_425.345),
                secureNote: nil,
                type: .login,
                viewPassword: true
            )
        )
    }

    /// `addCipherWithCollections()` performs the add cipher with collections request and decodes the response.
    func test_addCipherWithCollections() async throws {
        client.result = .httpSuccess(testData: .cipherResponse)

        let response = try await subject.addCipherWithCollections(.fixture(collectionIds: ["1", "2", "3"]))

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/create")

        XCTAssertEqual(
            response,
            CipherDetailsResponseModel(
                attachments: nil,
                card: nil,
                collectionIds: nil,
                creationDate: Date(timeIntervalSince1970: 1_691_656_425.345),
                deletedDate: nil,
                edit: true,
                favorite: false,
                fields: nil,
                folderId: nil,
                id: "3792af7a-4441-11ee-be56-0242ac120002",
                identity: nil,
                key: nil,
                login: CipherLoginModel(
                    autofillOnPageLoad: nil,
                    password: "encrypted password",
                    passwordRevisionDate: nil,
                    totp: nil,
                    uris: [CipherLoginUriModel(match: nil, uri: "encrypted uri")],
                    username: "encrypted username"
                ),
                name: "encrypted name",
                notes: nil,
                organizationId: nil,
                organizationUseTotp: false,
                passwordHistory: nil,
                reprompt: .none,
                revisionDate: Date(timeIntervalSince1970: 1_691_656_425.345),
                secureNote: nil,
                type: .login,
                viewPassword: true
            )
        )
    }

    /// `shareCipher()` performs the share cipher request and decodes the response.
    func test_shareCipher() async throws {
        client.result = .httpSuccess(testData: .cipherResponse)

        let response = try await subject.shareCipher(.fixture(collectionIds: ["1", "2", "3"], id: "1"))

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .put)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/1/share")

        XCTAssertEqual(
            response,
            CipherDetailsResponseModel(
                attachments: nil,
                card: nil,
                collectionIds: nil,
                creationDate: Date(timeIntervalSince1970: 1_691_656_425.345),
                deletedDate: nil,
                edit: true,
                favorite: false,
                fields: nil,
                folderId: nil,
                id: "3792af7a-4441-11ee-be56-0242ac120002",
                identity: nil,
                key: nil,
                login: CipherLoginModel(
                    autofillOnPageLoad: nil,
                    password: "encrypted password",
                    passwordRevisionDate: nil,
                    totp: nil,
                    uris: [CipherLoginUriModel(match: nil, uri: "encrypted uri")],
                    username: "encrypted username"
                ),
                name: "encrypted name",
                notes: nil,
                organizationId: nil,
                organizationUseTotp: false,
                passwordHistory: nil,
                reprompt: .none,
                revisionDate: Date(timeIntervalSince1970: 1_691_656_425.345),
                secureNote: nil,
                type: .login,
                viewPassword: true
            )
        )
    }
}
