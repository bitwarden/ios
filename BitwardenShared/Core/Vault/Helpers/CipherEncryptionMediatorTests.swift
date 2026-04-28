import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - CipherEncryptionMediatorTests

class CipherEncryptionMediatorTests: BitwardenTestCase {
    // MARK: Properties

    var cipherService: MockCipherService!
    var clientService: MockClientService!
    var delegate: MockCipherEncryptionMediatorDelegate!
    var subject: DefaultCipherEncryptionMediator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        clientService = MockClientService()
        delegate = MockCipherEncryptionMediatorDelegate()

        subject = DefaultCipherEncryptionMediator(
            cipherService: cipherService,
            clientService: clientService,
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        clientService = nil
        delegate = nil
        subject = nil
    }

    // MARK: Tests - encryptAndUpdateCipher

    /// `encryptAndUpdateCipher(_:)` calls `updateCipherWithServer` when the cipher view has no key
    /// and encryption adds one, then returns the encrypted cipher.
    func test_encryptAndUpdateCipher_cipherViewHasNoKey_encryptionAddsKey_updatesWithServer() async throws {
        let cipherView = CipherView.fixture(key: nil)
        let encryptedCipher = Cipher.fixture(key: "encryptedKey")
        clientService.mockVault.clientCiphers.encryptCipherResult = .success(
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher),
        )

        let result = try await subject.encryptAndUpdateCipher(cipherView)

        XCTAssertEqual(cipherService.updateCipherWithServerCiphers, [encryptedCipher])
        XCTAssertEqual(cipherService.updateCipherWithServerEncryptedFor, "userId")
        XCTAssertEqual(result, encryptedCipher)
    }

    /// `encryptAndUpdateCipher(_:)` skips `updateCipherWithServer` when the cipher view already has
    /// a key (no migration needed).
    func test_encryptAndUpdateCipher_cipherViewHasKey_doesNotUpdateWithServer() async throws {
        let cipherView = CipherView.fixture(key: "existingKey")

        let result = try await subject.encryptAndUpdateCipher(cipherView)

        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
        XCTAssertEqual(clientService.mockVault.clientCiphers.encryptedCiphers, [cipherView])
        XCTAssertNotNil(result)
    }

    /// `encryptAndUpdateCipher(_:)` skips `updateCipherWithServer` when neither the cipher view
    /// nor the encrypted result has a key.
    func test_encryptAndUpdateCipher_cipherViewHasNoKey_encryptedCipherHasNoKey_doesNotUpdateWithServer() async throws {
        let cipherView = CipherView.fixture(key: nil)
        let encryptedCipher = Cipher.fixture(key: nil)
        clientService.mockVault.clientCiphers.encryptCipherResult = .success(
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher),
        )

        let result = try await subject.encryptAndUpdateCipher(cipherView)

        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
        XCTAssertEqual(result, encryptedCipher)
    }

    /// `encryptAndUpdateCipher(_:)` rethrows errors from the SDK encryption call.
    func test_encryptAndUpdateCipher_encryptThrows_throwsError() async throws {
        let cipherView = CipherView.fixture(key: nil)
        clientService.mockVault.clientCiphers.encryptError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await self.subject.encryptAndUpdateCipher(cipherView)
        }
    }

    /// `encryptAndUpdateCipher(_:)` rethrows errors from the server update call.
    func test_encryptAndUpdateCipher_updateWithServerThrows_throwsError() async throws {
        let cipherView = CipherView.fixture(key: nil)
        let encryptedCipher = Cipher.fixture(key: "encryptedKey")
        clientService.mockVault.clientCiphers.encryptCipherResult = .success(
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher),
        )
        cipherService.updateCipherWithServerResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await self.subject.encryptAndUpdateCipher(cipherView)
        }
    }

    // MARK: Tests - updateCipherKeyIfNeeded

    /// `updateCipherKeyIfNeeded(_:)` returns the original cipher view early when it already has a key.
    func test_updateCipherKeyIfNeeded_cipherViewHasKey_returnsOriginal() async throws {
        let cipherView = CipherView.fixture(id: "1", key: "existingKey")

        let result = try await subject.updateCipherKeyIfNeeded(cipherView)

        XCTAssertEqual(result, cipherView)
        XCTAssertTrue(clientService.mockVault.clientCiphers.encryptedCiphers.isEmpty)
        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
    }

    /// `updateCipherKeyIfNeeded(_:)` returns the original cipher view early when the cipher has no id.
    func test_updateCipherKeyIfNeeded_cipherViewHasNoId_returnsOriginal() async throws {
        let cipherView = CipherView.fixture(id: nil, key: nil)

        let result = try await subject.updateCipherKeyIfNeeded(cipherView)

        XCTAssertEqual(result, cipherView)
        XCTAssertTrue(clientService.mockVault.clientCiphers.encryptedCiphers.isEmpty)
        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
    }

    /// `updateCipherKeyIfNeeded(_:)` returns the original cipher view when the encrypted result
    /// still has no key — the SDK did not migrate it.
    func test_updateCipherKeyIfNeeded_encryptedCipherHasNoKey_returnsOriginal() async throws {
        let cipherView = CipherView.fixture(id: "1", key: nil)
        let encryptedCipher = Cipher.fixture(key: nil)
        clientService.mockVault.clientCiphers.encryptCipherResult = .success(
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher),
        )

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
        clientService.mockVault.clientCiphers.encryptCipherResult = .success(
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher),
        )
        delegate.fetchCipherReturnValue = updatedCipherView
        subject.setDelegate(delegate)

        let result = try await subject.updateCipherKeyIfNeeded(cipherView)

        XCTAssertEqual(cipherService.updateCipherWithServerCiphers, [encryptedCipher])
        XCTAssertEqual(cipherService.updateCipherWithServerEncryptedFor, "userId")
        XCTAssertEqual(delegate.fetchCipherReceivedId, "1")
        XCTAssertEqual(result, updatedCipherView)
    }

    /// `updateCipherKeyIfNeeded(_:)` returns the original cipher view when the delegate returns `nil`
    /// after the server update.
    func test_updateCipherKeyIfNeeded_encryptionAddsKey_delegateReturnsNil_returnsOriginal() async throws {
        let cipherView = CipherView.fixture(id: "1", key: nil)
        let encryptedCipher = Cipher.fixture(key: "encryptedKey")
        clientService.mockVault.clientCiphers.encryptCipherResult = .success(
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher),
        )
        delegate.fetchCipherReturnValue = nil
        subject.setDelegate(delegate)

        let result = try await subject.updateCipherKeyIfNeeded(cipherView)

        XCTAssertEqual(result, cipherView)
    }

    /// `updateCipherKeyIfNeeded(_:)` returns the original cipher view when no delegate has been set.
    func test_updateCipherKeyIfNeeded_encryptionAddsKey_noDelegate_returnsOriginal() async throws {
        let cipherView = CipherView.fixture(id: "1", key: nil)
        let encryptedCipher = Cipher.fixture(key: "encryptedKey")
        clientService.mockVault.clientCiphers.encryptCipherResult = .success(
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher),
        )

        let result = try await subject.updateCipherKeyIfNeeded(cipherView)

        XCTAssertEqual(cipherService.updateCipherWithServerCiphers, [encryptedCipher])
        XCTAssertEqual(result, cipherView)
    }

    /// `updateCipherKeyIfNeeded(_:)` rethrows errors from the SDK encryption call.
    func test_updateCipherKeyIfNeeded_encryptThrows_throwsError() async throws {
        let cipherView = CipherView.fixture(id: "1", key: nil)
        clientService.mockVault.clientCiphers.encryptError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await self.subject.updateCipherKeyIfNeeded(cipherView)
        }
    }

    /// `updateCipherKeyIfNeeded(_:)` rethrows errors from the server update call.
    func test_updateCipherKeyIfNeeded_updateWithServerThrows_throwsError() async throws {
        let cipherView = CipherView.fixture(id: "1", key: nil)
        let encryptedCipher = Cipher.fixture(key: "encryptedKey")
        clientService.mockVault.clientCiphers.encryptCipherResult = .success(
            EncryptionContext(encryptedFor: "userId", cipher: encryptedCipher),
        )
        cipherService.updateCipherWithServerResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await self.subject.updateCipherKeyIfNeeded(cipherView)
        }
    }
}
