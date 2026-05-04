import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

final class SafariExtensionCredentialStoreServiceTests: BitwardenTestCase {
    var cipherService: MockCipherService!
    var clientService: MockClientService!
    var now: Date!
    var subject: SafariExtensionCredentialStoreService!

    override func setUp() {
        super.setUp()
        cipherService = MockCipherService()
        clientService = MockClientService()
        now = Date(year: 2026, month: 4, day: 23, hour: 19, minute: 35)
        subject = SafariExtensionCredentialStoreService(
            cipherService: cipherService,
            clientService: clientService,
            nowProvider: { self.now }
        )
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
        now = nil
        clientService = nil
        cipherService = nil
    }

    func test_saveCredential_saveNewLogin_encryptsAndAddsCipher() async throws {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            loginTitle: "Example",
            notes: "Imported from Safari",
            requestContext: SafariExtensionRequestContext(
                trigger: .actionPanelPrimary,
                submissionAction: .saveNewLogin
            ),
            password: "secret",
            urlString: "https://example.com/login",
            username: "user@example.com"
        )

        try await subject.saveCredential(
            for: request,
            matchedLogin: nil,
            submissionAction: .saveNewLogin
        )

        XCTAssertEqual(clientService.mockVault.clientCiphers.encryptedCiphers.count, 1)
        let encryptedCipherView = try XCTUnwrap(clientService.mockVault.clientCiphers.encryptedCiphers.first)
        XCTAssertNil(encryptedCipherView.id)
        XCTAssertEqual(encryptedCipherView.name, "Example")
        XCTAssertEqual(encryptedCipherView.notes, "Imported from Safari")
        XCTAssertEqual(encryptedCipherView.login?.username, "user@example.com")
        XCTAssertEqual(encryptedCipherView.login?.password, "secret")
        XCTAssertEqual(encryptedCipherView.login?.passwordRevisionDate, now)
        XCTAssertEqual(encryptedCipherView.login?.uris?.first?.uri, "https://example.com/login")
        XCTAssertEqual(cipherService.addCipherWithServerCiphers.count, 1)
        XCTAssertEqual(cipherService.addCipherWithServerEncryptedFor, "1")
        XCTAssertTrue(cipherService.updateCipherWithServerCiphers.isEmpty)
    }

    func test_saveCredential_updateExistingLogin_fetchesDecryptsEncryptsAndUpdatesCipher() async throws {
        let existingCipher = Cipher.fixture(
            id: "cipher-1",
            login: .fixture(
                password: "old-secret",
                passwordRevisionDate: Date(year: 2025, month: 1, day: 1),
                uris: [.fixture(uri: "https://example.com/old")],
                username: "old@example.com"
            ),
            name: "Existing login",
            notes: "Existing notes",
            type: .login
        )
        cipherService.fetchCipherResult = .success(existingCipher)

        let request = SafariExtensionRequest(
            kind: .saveLogin,
            requestContext: SafariExtensionRequestContext(
                trigger: .actionPanelPrimary,
                submissionAction: .updateExistingLogin
            ),
            password: "new-secret",
            urlString: "https://example.com/login",
            username: "new@example.com"
        )
        let matchedLogin = SafariExtensionMatchedLogin(
            id: "cipher-1",
            username: "old@example.com",
            password: "old-secret",
            urlString: "https://example.com/old"
        )

        try await subject.saveCredential(
            for: request,
            matchedLogin: matchedLogin,
            submissionAction: .updateExistingLogin
        )

        XCTAssertEqual(cipherService.fetchCipherId, "cipher-1")
        XCTAssertEqual(clientService.mockVault.clientCiphers.encryptedCiphers.count, 1)
        let encryptedCipherView = try XCTUnwrap(clientService.mockVault.clientCiphers.encryptedCiphers.first)
        XCTAssertEqual(encryptedCipherView.id, "cipher-1")
        XCTAssertEqual(encryptedCipherView.name, "Existing login")
        XCTAssertEqual(encryptedCipherView.notes, "Existing notes")
        XCTAssertEqual(encryptedCipherView.login?.username, "new@example.com")
        XCTAssertEqual(encryptedCipherView.login?.password, "new-secret")
        XCTAssertEqual(encryptedCipherView.login?.passwordRevisionDate, now)
        XCTAssertEqual(encryptedCipherView.login?.uris?.first?.uri, "https://example.com/login")
        XCTAssertEqual(cipherService.updateCipherWithServerCiphers.count, 1)
        XCTAssertEqual(cipherService.updateCipherWithServerEncryptedFor, "1")
        XCTAssertTrue(cipherService.addCipherWithServerCiphers.isEmpty)
    }
}
