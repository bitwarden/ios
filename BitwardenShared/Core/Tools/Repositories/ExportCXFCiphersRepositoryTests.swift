#if SUPPORTS_CXP
import AuthenticationServices
import BitwardenKitMocks
import InlineSnapshotTesting
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - ExportCXFCiphersRepositoryTests

class ExportCXFCiphersRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var cipherService: MockCipherService!
    var clientService: MockClientService!
    var credentialManagerFactory: MockCredentialManagerFactory!
    var cxfCredentialsResultBuilder: MockCXFCredentialsResultBuilder!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: ExportCXFCiphersRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        clientService = MockClientService()
        credentialManagerFactory = MockCredentialManagerFactory()
        cxfCredentialsResultBuilder = MockCXFCredentialsResultBuilder()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        subject = DefaultExportCXFCiphersRepository(
            cipherService: cipherService,
            clientService: clientService,
            credentialManagerFactory: credentialManagerFactory,
            cxfCredentialsResultBuilder: cxfCredentialsResultBuilder,
            errorReporter: errorReporter,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        clientService = nil
        credentialManagerFactory = nil
        cxfCredentialsResultBuilder = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `buildCiphersToExportSummary(from:)` returns the summary from the ciphers sent filtering the empty type ones.
    func test_buildCiphersToExportSummary() {
        cxfCredentialsResultBuilder.buildResult = [
            CXFCredentialsResult(count: 1, type: .password),
            CXFCredentialsResult(count: 0, type: .card),
            CXFCredentialsResult(count: 0, type: .identity),
        ]
        let result = subject.buildCiphersToExportSummary(from: [.fixture()])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 1)
        XCTAssertEqual(result[0].type, .password)
    }

    /// `buildCiphersToExportSummary(from:)` returns empty when empty ciphers are sent.
    func test_buildCiphersToExportSummary_empty() {
        XCTAssertTrue(subject.buildCiphersToExportSummary(from: []).isEmpty)
    }

    /// `exportCredentials(data:presentationAnchor:)` exports the credential data.
    @MainActor
    func test_exportCredentials() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("Exporting ciphers requires iOS 26.0")
        }
        let exportManager = MockCredentialExportManager()
        credentialManagerFactory.exportManager = exportManager

        try await subject.exportCredentials(data: .fixture(), presentationAnchor: { UIWindow() })
        XCTAssertTrue(exportManager.exportCredentialsCalled)
    }

    /// `exportCredentials(data:presentationAnchor:)` throws when exporting.
    @MainActor
    func test_exportCredentials_throws() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("Exporting ciphers requires iOS 26.0")
        }
        let exportManager = MockCredentialExportManager()
        exportManager.exportCredentialsError = BitwardenTestError.example
        credentialManagerFactory.exportManager = exportManager

        let presentationAnchor = UIWindow()
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.exportCredentials(data: .fixture(), presentationAnchor: { presentationAnchor })
        }
    }

    /// `getAllCiphersToExportCXF()` fetches all ciphers filtering the deleted ones out.
    func test_getAllCiphersToExportCXF() async throws {
        cipherService.fetchAllCiphersResult = .success([
            .fixture(id: "1"),
            .fixture(deletedDate: .now, id: "del1"),
            .fixture(deletedDate: .now, id: "del2"),
            .fixture(id: "2"),
            .fixture(id: "org1", organizationId: "someorg1"),
            .fixture(id: "org5", organizationId: "someorg2"),
            .fixture(deletedDate: .now, id: "del3"),
        ])
        let result = try await subject.getAllCiphersToExportCXF()
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "1")
        XCTAssertEqual(result[1].id, "2")
    }

    /// `getAllCiphersToExportCXF()` throws when fetching ciphers throws.
    func test_getAllCiphersToExportCXF_throws() async throws {
        cipherService.fetchAllCiphersResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getAllCiphersToExportCXF()
        }
    }

    /// `getExportVaultDataForCXF()` gets the vault data prepared for export on CXF.
    @MainActor
    func test_getExportVaultDataForCXF() async throws { // swiftlint:disable:this function_body_length
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("This test requires iOS 26.0")
        }
        cipherService.fetchAllCiphersResult = .success([
            .fixture(id: "1"),
            .fixture(deletedDate: .now, id: "del1"),
            .fixture(deletedDate: .now, id: "del2"),
            .fixture(id: "2"),
            .fixture(deletedDate: .now, id: "del3"),
        ])
        stateService.activeAccount = .fixture(
            profile: .fixture(
                email: "example@example.com",
                name: "Test",
                userId: "1"
            )
        )

        clientService.mockExporters.exportCxfResult = .success(
            """
            {"items":[{"creationAt":1735850484,"credentials":[{"password":{"fieldType":"concealed-string","id":"","value":"pass"},"username":{"id":"","fieldType":"string","value":"user"},"type":"basic-auth","urls":["example.com"]}],"type":"login","title":"Item 1","id":"","modifiedAt":1735850484},{"id":"","creationAt":1735850484,"modifiedAt":1735850484,"type":"login","title":"Item 2","credentials":[{"cardType":"type","type":"credit-card","fullName":"John Doe","number":"4111111111111111"}]}],"email":"","collections":[],"userName":"","id":""}
            """) // swiftlint:disable:previous line_length

        let result = try await subject.getExportVaultDataForCXF()

        XCTAssertEqual(clientService.mockExporters.account?.email, "example@example.com")
        XCTAssertEqual(clientService.mockExporters.account?.name, "Test")
        XCTAssertEqual(clientService.mockExporters.account?.id, "1")
        assertInlineSnapshot(of: result.dump(), as: .lines) {
            """
            Email: 
            UserName: 
            --- Items ---
              Title: Item 1
              Type: login
              Creation: 2025-01-02 20:41:24 +0000
              Modified: 2025-01-02 20:41:24 +0000
              --- Credentials ---
                Username.FieldType: string
                Username.Value: user
                Password.FieldType: concealedString
                Password.Value: pass
                --- Urls ---
                      example.com

              Title: Item 2
              Type: login
              Creation: 2025-01-02 20:41:24 +0000
              Modified: 2025-01-02 20:41:24 +0000
              --- Credentials ---
                FullName: John Doe
                Number: 4111111111111111
                CardType: type

            """
        }
    }

    /// `getExportVaultDataForCXF()` throws when getting all ciphers to export.
    @MainActor
    func test_getExportVaultDataForCXF_throwsGettingCiphers() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("This test requires iOS 26.0")
        }
        cipherService.fetchAllCiphersResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getExportVaultDataForCXF()
        }
    }

    /// `getExportVaultDataForCXF()` throws when getting account.
    @MainActor
    func test_getExportVaultDataForCXF_throwsAccount() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("This test requires iOS 26.0")
        }
        cipherService.fetchAllCiphersResult = .success([
            .fixture(id: "1"),
        ])
        stateService.activeAccount = nil

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getExportVaultDataForCXF()
        }
    }

    /// `getExportVaultDataForCXF()` throws when exporting using the SDK.
    @MainActor
    func test_getExportVaultDataForCXF_throwsExporting() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("This test requires iOS 26.0")
        }
        cipherService.fetchAllCiphersResult = .success([
            .fixture(id: "1"),
        ])
        stateService.activeAccount = .fixture(
            profile: .fixture(
                email: "example@example.com",
                name: "Test",
                userId: "1"
            )
        )
        clientService.mockExporters.exportCxfResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getExportVaultDataForCXF()
        }
    }
}

#endif
