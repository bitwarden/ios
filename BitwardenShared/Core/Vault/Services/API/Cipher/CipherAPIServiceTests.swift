import InlineSnapshotTesting
import Networking
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
                    totp: "totp",
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
                    totp: "totp",
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

    /// `deleteAttachment(withID:cipherId:)` performs the delete attachment request.
    func test_deleteAttachment() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        _ = try await subject.deleteAttachment(withID: "456", cipherId: "123")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .delete)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/123/attachment/456")
    }

    /// `deleteCipher()` performs the delete cipher request.
    func test_deleteCipher() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        _ = try await subject.deleteCipher(withID: "123")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .delete)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/123")
    }

    /// `restoreCipher()` performs the restore cipher request.
    func test_restoreCipher() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        _ = try await subject.restoreCipher(withID: "123")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .put)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/123/restore")
    }

    /// `saveAttachment(cipherId:fileName:fileSize:key:)` performs the save attachment request and decodes the response.
    func test_saveAttachment() async throws { // swiftlint:disable:this function_body_length
        client.result = .httpSuccess(testData: .saveAttachment)

        let response = try await subject.saveAttachment(
            cipherId: "42",
            fileName: "The Answer",
            fileSize: "lots",
            key: "🔑"
        )

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/42/attachment/v2")

        XCTAssertEqual(
            response,
            SaveAttachmentResponse(
                attachmentId: "1",
                cipherResponse: CipherDetailsResponseModel(
                    attachments: [
                        .init(
                            fileName: "2.q4Pl+Pz7D3sxr1VEKuwke",
                            id: "opbq2xocqozcwmlvtwoh15bovberxibb",
                            key: "2.jUls4EBVWgMO9BR9aU+0WA==|H",
                            size: "5725713",
                            sizeName: "5.46 MB",
                            url: "https://cdn.bitwarden.net/attachments/071350c"
                        ),
                    ],
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
                        totp: "totp",
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
                ),
                fileUploadType: 1,
                url: "https://bitwardenxx5keu3w.blob.core.windows.net/attachments-v2/etc"
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
                    totp: "totp",
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

    /// `softDeleteCipher()` performs the soft delete cipher request.
    func test_softDeleteCipher() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        _ = try await subject.softDeleteCipher(withID: "123")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .put)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/123/delete")
    }

    /// `updateCipherCollections()` performs the update cipher collections request.
    func test_updateCipherCollections() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        try await subject.updateCipherCollections(.fixture(collectionIds: ["1", "2", "3"], id: "1"))

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .put)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/1/collections")
    }
}
