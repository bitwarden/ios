import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared

class Fido2CredentialStoreServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var cipherService: MockCipherService!
    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var subject: Fido2CredentialStoreService!
    var syncService: MockSyncService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        syncService = MockSyncService()

        subject = Fido2CredentialStoreService(
            cipherService: cipherService,
            clientService: clientService,
            errorReporter: errorReporter,
            syncService: syncService
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        clientService = nil
        errorReporter = nil
        subject = nil
        syncService = nil
    }

    // MARK: Tests

    /// `.allCredentials()` returns all credentials decrypted which are active
    /// and have Fido2 credentials in it.
    func test_allCredentials() async throws {
        cipherService.fetchAllCiphersResult = .success([
            .fixture(deletedDate: Date.distantPast, id: "1"),
            .fixture(id: "2", type: .card),
            .fixture(id: "3", type: .identity),
            .fixture(id: "4", type: .login),
            .fixture(
                id: "5",
                login: .fixture(
                    fido2Credentials: [
                        .fixture(),
                    ]
                ),
                type: .login
            ),
            .fixture(id: "6", type: .secureNote),
        ])

        let result = try await subject.allCredentials()

        XCTAssertTrue(result.count == 1)
        XCTAssertTrue(result[0].id == "5")
    }

    /// `.allCredentials()` throws when fetching ciphers.
    func test_allCredentials_throwsFetchingCiphers() async throws {
        cipherService.fetchAllCiphersResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.allCredentials()
        }
    }

    /// `.allCredentials()` throws when decrypting ciphers.
    func test_allCredentials_throwsDecryptingCiphers() async throws {
        cipherService.fetchAllCiphersResult = .success([
            .fixture(
                id: "1",
                login: .fixture(
                    fido2Credentials: [
                        .fixture(),
                    ]
                ),
                type: .login
            ),
        ])
        clientService.mockVault.clientCiphers.decryptListError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.allCredentials()
        }
    }

    /// `.findCredentials(ids:ripId:)` returns the login ciphers that are active, have Fido2 credentials
    /// and match the `ripId` and the credential `ids` if any.
    func test_findCredentials() async throws {
        let expectedRpId = Fido2CredentialAutofillView.defaultRpId
        let expectedCredentialId = Data(repeating: 1, count: 16)
        let credentialIds = [
            expectedCredentialId,
            Data(repeating: 4, count: 16),
        ]
        let expectedCipherId = "4"

        setupFindCredentials(cipherIdWithFullFido2Credential: expectedCipherId, expectedRpId: expectedRpId)

        clientService.mockPlatform.fido2Mock.decryptFido2AutofillCredentialsMocker
            .withResult { cipherView in
                guard let cipherId = cipherView.id else {
                    return []
                }
                let hasExpectedCredentialId = cipherId == expectedCipherId
                return [
                    .fixture(
                        credentialId: hasExpectedCredentialId
                            ? expectedCredentialId
                            : Data(repeating: 123, count: 16),
                        cipherId: cipherId,
                        rpId: expectedRpId
                    ),
                    .fixture(
                        credentialId: Data(repeating: 123, count: 16),
                        cipherId: cipherId,
                        rpId: "test"
                    ),
                ]
            }

        let result = try await subject.findCredentials(ids: credentialIds, ripId: expectedRpId)

        XCTAssertTrue(syncService.didFetchSync)
        XCTAssertTrue(result.count == 1)
        XCTAssertTrue(result[0].id == expectedCipherId)
    }

    /// `.findCredentials(ids:ripId:)` returns the login ciphers that are active, have Fido2 credentials
    /// and match the `ripId` and the credential `ids` if any.
    func test_findCredentials_noCredentialIds() async throws {
        let expectedRpId = Fido2CredentialAutofillView.defaultRpId
        let expectedCipherIds = ["3", "4"]

        setupFindCredentials(cipherIdWithFullFido2Credential: "4", expectedRpId: expectedRpId)

        clientService.mockPlatform.fido2Mock.decryptFido2AutofillCredentialsMocker
            .withResult { cipherView in
                guard let cipherId = cipherView.id,
                      expectedCipherIds.contains(cipherId) else {
                    return []
                }
                return [
                    .fixture(
                        credentialId: Data(repeating: 1, count: 16),
                        cipherId: cipherId,
                        rpId: expectedRpId
                    ),
                    .fixture(
                        credentialId: Data(repeating: 123, count: 16),
                        cipherId: cipherId,
                        rpId: "test"
                    ),
                ]
            }

        let result = try await subject.findCredentials(ids: nil, ripId: expectedRpId)

        XCTAssertTrue(result.count == 2)
        XCTAssertTrue(result[0].id == expectedCipherIds[0])
        XCTAssertTrue(result[1].id == expectedCipherIds[1])
    }

    /// `.findCredentials(ids:ripId:)` returns empty if there are active Fido2 credentials.
    func test_findCredentials_empty() async throws {
        cipherService.fetchAllCiphersResult = .success([])

        let result = try await subject.findCredentials(ids: nil, ripId: "something")

        XCTAssertTrue(result.isEmpty)
    }

    /// `.findCredentials(ids:ripId)` throws when syncing.
    func test_findCredentials_throwsSync() async throws {
        syncService.fetchSyncResult = .failure(BitwardenTestError.example)

        _ = try await subject.findCredentials(ids: nil, ripId: "something")

        XCTAssertFalse(errorReporter.errors.isEmpty)
        XCTAssertTrue(cipherService.fetchAllCiphersCalled)
    }

    /// `.findCredentials(ids:ripId:)` throws when fetching ciphers..
    func test_findCredentials_throwsWhenFetchingCipher() async throws {
        cipherService.fetchAllCiphersResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.findCredentials(ids: nil, ripId: "something")
        }
    }

    /// `.findCredentials(ids:ripId:)` throws when decrypting ciphers..
    func test_findCredentials_throwsWhenDecryptingCiphers() async throws {
        cipherService.fetchAllCiphersResult = .success([
            .fixture(
                id: "1",
                login: .fixture(
                    fido2Credentials: [
                        .fixture(),
                    ]
                ),
                type: .login
            ),
        ])
        clientService.mockVault.clientCiphers.decryptResult = { _ in
            throw BitwardenTestError.example
        }

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.findCredentials(ids: nil, ripId: "something")
        }
    }

    /// `.findCredentials(ids:ripId:)` throws when decrypting Fido2 credentials..
    func test_findCredentials_throwsWhenDecryptingFido2Credentials() async throws {
        cipherService.fetchAllCiphersResult = .success([
            .fixture(
                id: "1",
                login: .fixture(
                    fido2Credentials: [
                        .fixture(),
                    ]
                ),
                type: .login
            ),
        ])
        clientService.mockPlatform.fido2Mock.decryptFido2AutofillCredentialsMocker
            .throwing(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.findCredentials(ids: nil, ripId: "something")
        }
    }

    /// `.saveCredential(cred:)` add cipher to server when no id present.
    func test_saveCredential_add() async throws {
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: .fixture())
        )
        XCTAssertTrue(cipherService.addCipherWithServerCiphers.count == 1)
        XCTAssertEqual(cipherService.addCipherWithServerEncryptedFor, "1")
    }

    /// `.saveCredential(cred:)` add cipher to server when no id present.
    func test_saveCredential_update() async throws {
        try await subject.saveCredential(cred: EncryptionContext(encryptedFor: "1", cipher: .fixture(id: "1")))
        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.count == 1)
        XCTAssertEqual(cipherService.updateCipherWithServerEncryptedFor, "1")
    }

    /// `.saveCredential(cred:)` adding cipher to server throws.
    func test_saveCredential_addThrows() async throws {
        cipherService.addCipherWithServerResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.saveCredential(cred: EncryptionContext(encryptedFor: "1", cipher: .fixture()))
        }
    }

    /// `.saveCredential(cred:)` updating cipher to server throws.
    func test_saveCredential_updateThrows() async throws {
        cipherService.updateCipherWithServerResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.saveCredential(cred: EncryptionContext(encryptedFor: "1", cipher: .fixture(id: "1")))
        }
    }

    // MARK: Private

    func setupFindCredentials(cipherIdWithFullFido2Credential: String, expectedRpId: String) {
        cipherService.fetchAllCiphersResult = .success([
            .fixture(deletedDate: Date.distantPast, id: "deletedDate"),
            .fixture(id: "card", type: .card),
            .fixture(id: "identity", type: .identity),
            .fixture(id: "login", type: .login),
            .fixture(
                id: "1",
                login: .fixture(
                    fido2Credentials: [
                        .fixture(),
                    ]
                ),
                type: .login
            ),
            .fixture(
                id: "2",
                login: .fixture(
                    fido2Credentials: [
                        .fixture(rpId: "thrash"),
                    ]
                ),
                type: .login
            ),
            .fixture(
                id: "3",
                login: .fixture(
                    fido2Credentials: [
                        .fixture(rpId: expectedRpId),
                    ]
                ),
                type: .login
            ),
            .fixture(
                id: cipherIdWithFullFido2Credential,
                login: .fixture(
                    fido2Credentials: [
                        .fixture(
                            credentialId: "some credential id",
                            rpId: expectedRpId
                        ),
                    ]
                ),
                type: .login
            ),
            .fixture(id: "secureNote", type: .secureNote),
        ])
    }
}

class DebuggingFido2CredentialStoreServiceTests: BitwardenTestCase {
    // MARK: Properties

    var fido2CredentialStore: MockFido2CredentialStore!
    var subject: DebuggingFido2CredentialStoreService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        fido2CredentialStore = MockFido2CredentialStore()

        subject = DebuggingFido2CredentialStoreService(
            fido2CredentialStore: fido2CredentialStore
        )
    }

    override func tearDown() {
        super.tearDown()

        fido2CredentialStore = nil
        subject = nil
    }

    // MARK: Tests

    /// `.allCredentials()` returns all credentials and reports it.
    func test_allCredentials() async throws {
        fido2CredentialStore.allCredentialsResult = .success([.fixture()])
        let result = try await subject.allCredentials()
        XCTAssert(result.count == 1)
        XCTAssertFalse(
            (try? Fido2DebuggingReportBuilder.builder
                .getReport()?.allCredentialsResult?.get().isEmpty) ?? true
        )
    }

    /// `.allCredentials()` throws and reports it.
    func test_allCredentials_throws() async throws {
        fido2CredentialStore.allCredentialsResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.allCredentials()
        }
        XCTAssertNil(try? Fido2DebuggingReportBuilder.builder.getReport()?
            .allCredentialsResult?.get()
        )
    }

    /// `.findCredentials(ids:ripId:)` returns found credentials and reports it.
    func test_findCredentials() async throws {
        fido2CredentialStore.findCredentialsResult = .success([.fixture()])
        let result = try await subject.findCredentials(ids: nil, ripId: "something")
        XCTAssert(result.count == 1)
        XCTAssertFalse(
            (try? Fido2DebuggingReportBuilder.builder
                .getReport()?.findCredentialsResult?.get().isEmpty) ?? true
        )
    }

    /// `.findCredentials(ids:ripId:)` throws and reports it.
    func test_findCredentialsthrows() async throws {
        fido2CredentialStore.findCredentialsResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.findCredentials(ids: nil, ripId: "something")
        }
        XCTAssertNil(try? Fido2DebuggingReportBuilder.builder.getReport()?
            .findCredentialsResult?.get()
        )
    }

    /// `.saveCredential(cred:)` saves credentials and adds it to the report.
    func test_saveCredential() async throws {
        try await subject.saveCredential(cred: EncryptionContext(encryptedFor: "1", cipher: .fixture(id: "1")))
        XCTAssertTrue(fido2CredentialStore.saveCredentialCalled)
        XCTAssertTrue(
            (try? Fido2DebuggingReportBuilder.builder
                .getReport()?.saveCredentialCipher?.get().id) == "1"
        )
    }

    /// `.saveCredential(cred:)` throws and reports it.
    func test_saveCredential_throws() async throws {
        fido2CredentialStore.saveCredentialError = BitwardenTestError.example
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.saveCredential(cred: EncryptionContext(encryptedFor: "1", cipher: .fixture(id: "1")))
        }
        XCTAssertNil(try? Fido2DebuggingReportBuilder.builder.getReport()?
            .saveCredentialCipher?.get()
        )
    }
}
