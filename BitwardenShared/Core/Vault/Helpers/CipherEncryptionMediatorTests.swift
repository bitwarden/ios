import BitwardenKitMocks
import BitwardenSdk
import BitwardenSdkMocks
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - CipherEncryptionMediatorTests

class CipherEncryptionMediatorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var cipherService: MockCipherService!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var delegate: MockCipherEncryptionMediatorDelegate!
    var subject: DefaultCipherEncryptionMediator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        clientService = MockClientService()
        configService = MockConfigService()
        delegate = MockCipherEncryptionMediatorDelegate()

        subject = DefaultCipherEncryptionMediator(
            cipherService: cipherService,
            clientService: clientService,
            configService: configService,
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        clientService = nil
        configService = nil
        delegate = nil
        subject = nil
    }

    // MARK: Tests - encryptAndUpdateCipher

    /// `encryptAndUpdateCipher(_:)` calls `updateCipherWithServer` when the cipher view has no key
    /// and encryption adds one, then returns the encrypted cipher.
    func test_encryptAndUpdateCipher_cipherViewHasNoKey_encryptionAddsKey_updatesWithServer() async throws {
        let cipherView = CipherView.fixture(key: nil)
        let encryptedCipher = Cipher.fixture(key: "encryptedKey")
        clientService.mockVault.clientCiphers.encryptClosure = { _ in
            EncryptionContext(encryptedFor: "userId", encryptedByKeyId: "key-1", cipher: encryptedCipher)
        }

        let result = try await subject.encryptAndUpdateCipher(cipherView)

        XCTAssertEqual(cipherService.updateCipherWithServerCiphers, [encryptedCipher])
        XCTAssertEqual(cipherService.updateCipherWithServerEncryptedByKeyId, "key-1")
        XCTAssertEqual(cipherService.updateCipherWithServerEncryptedFor, "userId")
        XCTAssertEqual(result, encryptedCipher)
    }

    /// `encryptAndUpdateCipher(_:)` skips `updateCipherWithServer` when the cipher view already has
    /// a key (no migration needed).
    func test_encryptAndUpdateCipher_cipherViewHasKey_doesNotUpdateWithServer() async throws {
        let cipherView = CipherView.fixture(key: "existingKey")

        let result = try await subject.encryptAndUpdateCipher(cipherView)

        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
        XCTAssertEqual(clientService.mockVault.clientCiphers.encryptReceivedCipherView, cipherView)
        XCTAssertNotNil(result)
    }

    /// `encryptAndUpdateCipher(_:)` skips `updateCipherWithServer` when neither the cipher view
    /// nor the encrypted result has a key.
    func test_encryptAndUpdateCipher_cipherViewHasNoKey_encryptedCipherHasNoKey_doesNotUpdateWithServer() async throws {
        let cipherView = CipherView.fixture(key: nil)
        let encryptedCipher = Cipher.fixture(key: nil)
        clientService.mockVault.clientCiphers.encryptClosure = { _ in
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher)
        }

        let result = try await subject.encryptAndUpdateCipher(cipherView)

        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
        XCTAssertEqual(result, encryptedCipher)
    }

    /// `encryptAndUpdateCipher(_:)` rethrows errors from the SDK encryption call.
    func test_encryptAndUpdateCipher_encryptThrows_throwsError() async throws {
        let cipherView = CipherView.fixture(key: nil)
        clientService.mockVault.clientCiphers.encryptThrowableError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await self.subject.encryptAndUpdateCipher(cipherView)
        }
    }

    /// `encryptAndUpdateCipher(_:)` rethrows errors from the server update call.
    func test_encryptAndUpdateCipher_updateWithServerThrows_throwsError() async throws {
        let cipherView = CipherView.fixture(key: nil)
        let encryptedCipher = Cipher.fixture(key: "encryptedKey")
        clientService.mockVault.clientCiphers.encryptClosure = { _ in
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher)
        }
        cipherService.updateCipherWithServerResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await self.subject.encryptAndUpdateCipher(cipherView)
        }
    }

    /// `encryptAndUpdateCipher(_:)` saves the cipher with the SDK when the cipher view has no key,
    /// encryption adds one, and the SDK cipher operations feature flag is enabled. It returns the
    /// cipher re-encrypted with the key saved by the SDK.
    @MainActor
    func test_encryptAndUpdateCipher_sdkCipherOperations_encryptionAddsKey_editsWithSdk() async throws {
        configService.featureFlagsBool[.sdkCipherOperations] = true
        let cipherView = CipherView.fixture(id: "1", key: nil, login: .fixture())
        let savedCipherView = CipherView.fixture(id: "1", key: "savedKey", login: .fixture())
        let ciphersClient = clientService.mockVault.clientCiphers
        ciphersClient.encryptClosure = { cipherView in
            EncryptionContext(
                encryptedFor: "userId",
                cipher: Cipher.fixture(id: cipherView.id, key: "encrypted-\(cipherView.key ?? "generatedKey")"),
            )
        }
        ciphersClient.editReturnValue = savedCipherView

        let result = try await subject.encryptAndUpdateCipher(cipherView)

        XCTAssertEqual(ciphersClient.editReceivedRequest, try CipherEditRequest(cipherView: cipherView))
        XCTAssertEqual(ciphersClient.encryptReceivedCipherView, savedCipherView)
        XCTAssertEqual(result, Cipher.fixture(id: "1", key: "encrypted-savedKey"))
        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
    }

    /// `encryptAndUpdateCipher(_:)` keeps the caller's collection IDs and deleted date when the SDK
    /// saves the cipher to add its key, since the SDK's edit request doesn't include those values.
    @MainActor
    func test_encryptAndUpdateCipher_sdkCipherOperations_keepsCallerChanges() async throws {
        configService.featureFlagsBool[.sdkCipherOperations] = true
        let deletedDate = Date(year: 2026, month: 11, day: 19)
        let cipherView = CipherView.fixture(
            collectionIds: ["newCollection"],
            deletedDate: deletedDate,
            id: "1",
            key: nil,
            login: .fixture(),
        )
        let savedCipherView = CipherView.fixture(
            collectionIds: ["oldCollection"],
            id: "1",
            key: "savedKey",
            login: .fixture(),
            revisionDate: Date(year: 2026, month: 11, day: 20),
        )
        let ciphersClient = clientService.mockVault.clientCiphers
        ciphersClient.encryptClosure = { cipherView in
            EncryptionContext(
                encryptedFor: "userId",
                cipher: Cipher.fixture(id: cipherView.id, key: "encrypted-\(cipherView.key ?? "generatedKey")"),
            )
        }
        ciphersClient.editReturnValue = savedCipherView

        _ = try await subject.encryptAndUpdateCipher(cipherView)

        let encryptedCipherView = try XCTUnwrap(ciphersClient.encryptReceivedCipherView)
        XCTAssertEqual(encryptedCipherView.collectionIds, ["newCollection"])
        XCTAssertEqual(encryptedCipherView.deletedDate, deletedDate)
        XCTAssertEqual(encryptedCipherView.key, "savedKey")
        XCTAssertEqual(encryptedCipherView.revisionDate, Date(year: 2026, month: 11, day: 20))
    }

    /// `encryptAndUpdateCipher(_:)` doesn't save the cipher with the SDK when the cipher view already
    /// has a key and the SDK cipher operations feature flag is enabled.
    @MainActor
    func test_encryptAndUpdateCipher_sdkCipherOperations_cipherViewHasKey_doesNotEdit() async throws {
        configService.featureFlagsBool[.sdkCipherOperations] = true
        let cipherView = CipherView.fixture(key: "existingKey")

        _ = try await subject.encryptAndUpdateCipher(cipherView)

        XCTAssertFalse(clientService.mockVault.clientCiphers.editCalled)
        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
    }

    /// `encryptAndUpdateCipher(_:)` rethrows errors from the SDK edit call.
    @MainActor
    func test_encryptAndUpdateCipher_sdkCipherOperations_editThrows_throwsError() async throws {
        configService.featureFlagsBool[.sdkCipherOperations] = true
        let ciphersClient = clientService.mockVault.clientCiphers
        ciphersClient.encryptClosure = { _ in
            EncryptionContext(encryptedFor: "userId", cipher: Cipher.fixture(key: "encryptedKey"))
        }
        ciphersClient.editThrowableError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await self.subject.encryptAndUpdateCipher(.fixture(id: "1", key: nil, login: .fixture()))
        }
    }

    // MARK: Tests - updateCipherKeyIfNeeded

    /// `updateCipherKeyIfNeeded(_:)` returns the original cipher view early when it already has a key.
    func test_updateCipherKeyIfNeeded_cipherViewHasKey_returnsOriginal() async throws {
        let cipherView = CipherView.fixture(id: "1", key: "existingKey")

        let result = try await subject.updateCipherKeyIfNeeded(cipherView)

        XCTAssertEqual(result, cipherView)
        XCTAssertFalse(clientService.mockVault.clientCiphers.encryptCalled)
        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
    }

    /// `updateCipherKeyIfNeeded(_:)` returns the original cipher view early when the cipher has no id.
    func test_updateCipherKeyIfNeeded_cipherViewHasNoId_returnsOriginal() async throws {
        let cipherView = CipherView.fixture(id: nil, key: nil)

        let result = try await subject.updateCipherKeyIfNeeded(cipherView)

        XCTAssertEqual(result, cipherView)
        XCTAssertFalse(clientService.mockVault.clientCiphers.encryptCalled)
        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
    }

    /// `updateCipherKeyIfNeeded(_:)` returns the original cipher view when the encrypted result
    /// still has no key — the SDK did not migrate it.
    func test_updateCipherKeyIfNeeded_encryptedCipherHasNoKey_returnsOriginal() async throws {
        let cipherView = CipherView.fixture(id: "1", key: nil)
        let encryptedCipher = Cipher.fixture(key: nil)
        clientService.mockVault.clientCiphers.encryptClosure = { _ in
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher)
        }

        let result = try await subject.updateCipherKeyIfNeeded(cipherView)

        XCTAssertEqual(result, cipherView)
        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
    }

    /// `updateCipherKeyIfNeeded(_:)` updates the server and returns the freshly fetched cipher view
    /// when the SDK adds a key during encryption.
    func test_updateCipherKeyIfNeeded_encryptionAddsKey_updatesServerAndReturnsUpdatedView() async throws {
        let cipherView = CipherView.fixture(id: "1", key: nil)
        let encryptedCipher = Cipher.fixture(key: "encryptedKey")
        let updatedCipherView = CipherView.fixture(id: "1", key: "decryptedKey")
        clientService.mockVault.clientCiphers.encryptClosure = { _ in
            EncryptionContext(encryptedFor: "userId", encryptedByKeyId: "key-1", cipher: encryptedCipher)
        }
        delegate.fetchCipherReturnValue = updatedCipherView
        subject.setDelegate(delegate)

        let result = try await subject.updateCipherKeyIfNeeded(cipherView)

        XCTAssertEqual(cipherService.updateCipherWithServerCiphers, [encryptedCipher])
        XCTAssertEqual(cipherService.updateCipherWithServerEncryptedByKeyId, "key-1")
        XCTAssertEqual(cipherService.updateCipherWithServerEncryptedFor, "userId")
        XCTAssertEqual(delegate.fetchCipherReceivedId, "1")
        XCTAssertEqual(result, updatedCipherView)
    }

    /// `updateCipherKeyIfNeeded(_:)` returns the original cipher view when the delegate returns `nil`
    /// after the server update.
    func test_updateCipherKeyIfNeeded_encryptionAddsKey_delegateReturnsNil_returnsOriginal() async throws {
        let cipherView = CipherView.fixture(id: "1", key: nil)
        let encryptedCipher = Cipher.fixture(key: "encryptedKey")
        clientService.mockVault.clientCiphers.encryptClosure = { _ in
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher)
        }
        delegate.fetchCipherReturnValue = nil
        subject.setDelegate(delegate)

        let result = try await subject.updateCipherKeyIfNeeded(cipherView)

        XCTAssertEqual(result, cipherView)
    }

    /// `updateCipherKeyIfNeeded(_:)` returns the original cipher view when no delegate has been set.
    func test_updateCipherKeyIfNeeded_encryptionAddsKey_noDelegate_returnsOriginal() async throws {
        let cipherView = CipherView.fixture(id: "1", key: nil)
        let encryptedCipher = Cipher.fixture(key: "encryptedKey")
        clientService.mockVault.clientCiphers.encryptClosure = { _ in
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher)
        }

        let result = try await subject.updateCipherKeyIfNeeded(cipherView)

        XCTAssertEqual(cipherService.updateCipherWithServerCiphers, [encryptedCipher])
        XCTAssertEqual(result, cipherView)
    }

    /// `updateCipherKeyIfNeeded(_:)` rethrows errors from the SDK encryption call.
    func test_updateCipherKeyIfNeeded_encryptThrows_throwsError() async throws {
        let cipherView = CipherView.fixture(id: "1", key: nil)
        clientService.mockVault.clientCiphers.encryptThrowableError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await self.subject.updateCipherKeyIfNeeded(cipherView)
        }
    }

    /// `updateCipherKeyIfNeeded(_:)` rethrows errors from the server update call.
    func test_updateCipherKeyIfNeeded_updateWithServerThrows_throwsError() async throws {
        let cipherView = CipherView.fixture(id: "1", key: nil)
        let encryptedCipher = Cipher.fixture(key: "encryptedKey")
        clientService.mockVault.clientCiphers.encryptClosure = { _ in
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher)
        }
        cipherService.updateCipherWithServerResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await self.subject.updateCipherKeyIfNeeded(cipherView)
        }
    }

    /// `updateCipherKeyIfNeeded(_:)` saves the cipher with the SDK and returns the saved cipher view
    /// when the SDK adds a key during encryption and the SDK cipher operations feature flag is enabled.
    @MainActor
    func test_updateCipherKeyIfNeeded_sdkCipherOperations_encryptionAddsKey_editsWithSdk() async throws {
        configService.featureFlagsBool[.sdkCipherOperations] = true
        let cipherView = CipherView.fixture(id: "1", key: nil, login: .fixture())
        let savedCipherView = CipherView.fixture(id: "1", key: "savedKey", login: .fixture())
        let ciphersClient = clientService.mockVault.clientCiphers
        ciphersClient.encryptClosure = { _ in
            EncryptionContext(encryptedFor: "userId", cipher: Cipher.fixture(key: "encryptedKey"))
        }
        ciphersClient.editReturnValue = savedCipherView
        subject.setDelegate(delegate)

        let result = try await subject.updateCipherKeyIfNeeded(cipherView)

        XCTAssertEqual(result, savedCipherView)
        XCTAssertEqual(ciphersClient.editReceivedRequest, try CipherEditRequest(cipherView: cipherView))
        XCTAssertFalse(delegate.fetchCipherCalled)
        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
    }

    /// `updateCipherKeyIfNeeded(_:)` rethrows errors from the SDK edit call.
    @MainActor
    func test_updateCipherKeyIfNeeded_sdkCipherOperations_editThrows_throwsError() async throws {
        configService.featureFlagsBool[.sdkCipherOperations] = true
        let ciphersClient = clientService.mockVault.clientCiphers
        ciphersClient.encryptClosure = { _ in
            EncryptionContext(encryptedFor: "userId", cipher: Cipher.fixture(key: "encryptedKey"))
        }
        ciphersClient.editThrowableError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await self.subject.updateCipherKeyIfNeeded(.fixture(id: "1", key: nil, login: .fixture()))
        }
    }
}
