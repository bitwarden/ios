import XCTest

@testable import BitwardenShared

class SyncAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: APIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()

        subject = APIService(
            baseUrlService: DefaultBaseUrlService(baseUrl: .example),
            client: client
        )
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        subject = nil
    }

    // MARK: Tests

    /// `getSync()` successfully decodes a response with ciphers.
    func test_sync_withCiphers() async throws {
        client.result = .httpSuccess(testData: .syncWithCipher)

        let response = try await subject.getSync()

        XCTAssertEqual(
            response,
            .fixture(
                ciphers: [
                    .fixture(
                        collectionIds: [],
                        creationDate: Date(timeIntervalSince1970: 1_691_656_425.345),
                        edit: true,
                        id: "3792af7a-4441-11ee-be56-0242ac120002",
                        login: .fixture(
                            password: "encrypted password",
                            uris: [
                                CipherLoginUriModel(match: nil, uri: "encrypted uri"),
                            ],
                            username: "encrypted username"
                        ),
                        name: "encrypted name",
                        reprompt: CipherRepromptType.none,
                        revisionDate: Date(timeIntervalSince1970: 1_691_656_425.345),
                        type: .login,
                        viewPassword: true
                    ),
                ],
                collections: [],
                folders: [],
                policies: [],
                sends: []
            )
        )
    }

    /// `getSync()` successfully decodes a response with a profile.
    func test_sync_withProfile() async throws {
        client.result = .httpSuccess(testData: .syncWithProfile)

        let response = try await subject.getSync()

        XCTAssertEqual(
            response,
            .fixture(
                ciphers: [],
                collections: [],
                folders: [],
                policies: [],
                profile: .fixture(
                    culture: "en-US",
                    email: "user@bitwarden.com",
                    id: "c8aa1e36-4427-11ee-be56-0242ac120002",
                    key: "key",
                    organizations: [],
                    privateKey: "private key",
                    securityStamp: "security stamp"
                ),
                sends: []
            )
        )
    }

    /// `getSync()` successfully decodes a response with sends.
    func test_sync_withSends() async throws {
        client.result = .httpSuccess(testData: .syncWithSends)

        let response = try await subject.getSync()

        XCTAssertEqual(
            response,
            .fixture(
                ciphers: [],
                collections: [],
                folders: [],
                policies: [],
                profile: nil,
                sends: [
                    SendResponseModel.fixture(
                        accessId: "access id",
                        deletionDate: Date(timeIntervalSince1970: 1_691_443_980),
                        id: "fc483c22-443c-11ee-be56-0242ac120002",
                        key: "encrypted key",
                        name: "encrypted name",
                        revisionDate: Date(timeIntervalSince1970: 1_690_925_611.636),
                        text: SendTextModel(
                            hidden: false,
                            text: "encrypted text"
                        ),
                        type: .text
                    ),
                    SendResponseModel.fixture(
                        accessId: "access id",
                        deletionDate: Date(timeIntervalSince1970: 1_692_230_400),
                        file: SendFileModel(
                            fileName: "test.txt",
                            id: "1",
                            size: "123",
                            sizeName: nil
                        ),
                        id: "d7a7e48c-443f-11ee-be56-0242ac120002",
                        key: "encrypted key",
                        name: "encrypted name",
                        revisionDate: Date(timeIntervalSince1970: 1_691_625_600),
                        type: .file
                    ),
                ]
            )
        )
    }
}
