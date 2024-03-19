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

        subject = APIService(client: client)
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
                            fido2Credentials: [
                                CipherLoginFido2Credential(
                                    counter: "encrypted counter",
                                    creationDate: Date(timeIntervalSince1970: 1_710_523_862.244),
                                    credentialId: "encrypted credentialId",
                                    discoverable: "encrypted discoverable",
                                    keyAlgorithm: "encrypted keyAlgorithm",
                                    keyCurve: "encrypted keyCurve",
                                    keyType: "encrypted keyType",
                                    keyValue: "encrypted keyValue",
                                    rpId: "encrypted rpId",
                                    rpName: "encrypted rpName",
                                    userDisplayName: "encrypted userDisplayName",
                                    userHandle: "encrypted userHandle",
                                    userName: "encrypted userName"
                                ),
                            ],
                            password: "encrypted password",
                            totp: "totp",
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

    /// `getSync()` successfully decodes a response with policies.
    func test_sync_withPolicies() async throws {
        client.result = .httpSuccess(testData: .syncWithPolicies)

        let response = try await subject.getSync()

        XCTAssertEqual(
            response,
            .fixture(
                policies: [
                    PolicyResponseModel(
                        data: nil,
                        enabled: false,
                        id: "policy-0",
                        organizationId: "org-1",
                        type: .twoFactorAuthentication
                    ),
                    PolicyResponseModel(
                        data: [
                            "minComplexity": .null,
                            "minLength": .int(12),
                            "requireUpper": .bool(true),
                            "requireLower": .bool(true),
                            "requireNumbers": .bool(true),
                            "requireSpecial": .bool(false),
                            "enforceOnLogin": .bool(false),
                        ],
                        enabled: true,
                        id: "policy-1",
                        organizationId: "org-1",
                        type: .masterPassword
                    ),
                    PolicyResponseModel(
                        data: nil,
                        enabled: false,
                        id: "policy-3",
                        organizationId: "org-1",
                        type: .onlyOrg
                    ),
                    PolicyResponseModel(
                        data: ["autoEnrollEnabled": .bool(false)],
                        enabled: true,
                        id: "policy-8",
                        organizationId: "org-1",
                        type: .resetPassword
                    ),
                ]
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
                    securityStamp: "stamp"
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
                            sizeName: "123 KB"
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
