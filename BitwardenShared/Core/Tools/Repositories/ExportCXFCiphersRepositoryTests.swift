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
    var exportVaultService: MockExportVaultService!
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
        exportVaultService = MockExportVaultService()
        stateService = MockStateService()

        subject = DefaultExportCXFCiphersRepository(
            cipherService: cipherService,
            clientService: clientService,
            credentialManagerFactory: credentialManagerFactory,
            cxfCredentialsResultBuilder: cxfCredentialsResultBuilder,
            errorReporter: errorReporter,
            exportVaultService: exportVaultService,
            stateService: stateService,
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        clientService = nil
        credentialManagerFactory = nil
        cxfCredentialsResultBuilder = nil
        errorReporter = nil
        exportVaultService = nil
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

    /// `getAllCiphersToExportCXF()` fetches all ciphers to export from the export service.
    func test_getAllCiphersToExportCXF() async throws {
        exportVaultService.fetchAllCiphersToExportResult = .success([
            .fixture(id: "1"),
            .fixture(id: "2"),
        ])
        let result = try await subject.getAllCiphersToExportCXF()
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "1")
        XCTAssertEqual(result[1].id, "2")
        XCTAssertEqual(exportVaultService.fetchAllCiphersIncludeArchived, false)
    }

    /// `getAllCiphersToExportCXF()` throws when fetching ciphers throws.
    func test_getAllCiphersToExportCXF_throws() async throws {
        exportVaultService.fetchAllCiphersToExportResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getAllCiphersToExportCXF()
        }
    }

    /// `getExportVaultDataForCXF()` gets the vault data prepared for export on CXF.
    @MainActor
    func test_getExportVaultDataForCXF() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("This test requires iOS 26.0")
        }
        exportVaultService.fetchAllCiphersToExportResult = .success([
            .fixture(id: "1"),
            .fixture(id: "2"),
        ])
        stateService.activeAccount = .fixture(
            profile: .fixture(
                email: "example@example.com",
                name: "Test",
                userId: "1",
            ),
        )

        clientService.mockExporters.exportCxfResult = .success(
            """
            {"items":[{"title":"Item 1","creationAt":1735689600,"credentials":[{"password":{"fieldType":"concealed-string","value":"pass"},"type":"basic-auth","username":{"fieldType":"string","value":"user"}}],"id":"","modifiedAt":1740787200},{"title":"Item 2","creationAt":1740009600,"credentials":[{"number":{"value":"4111111111111111","fieldType":"string"},"fullName":{"value":"John Doe","fieldType":"string"},"type":"credit-card","cardType":{"value":"type","fieldType":"string"}}],"id":"","modifiedAt":1743552000}],"collections":[],"username":"User1","id":"","email":"user1@example.com"}
            """, // swiftlint:disable:previous line_length
        )

        let result = try await subject.getExportVaultDataForCXF()

        XCTAssertEqual(clientService.mockExporters.account?.email, "example@example.com")
        XCTAssertEqual(clientService.mockExporters.account?.name, "Test")
        XCTAssertEqual(clientService.mockExporters.account?.id, "1")
        assertInlineSnapshot(of: result.dump(), as: .lines) {
            """
            Email: user1@example.com
            UserName: User1
            --- Items ---
              Title: Item 1
              Creation: 2025-01-01 00:00:00 +0000
              Modified: 2025-03-01 00:00:00 +0000
              --- Credentials ---
                Username.FieldType: string
                Username.Value: user
                Password.FieldType: concealedString
                Password.Value: pass

              Title: Item 2
              Creation: 2025-02-20 00:00:00 +0000
              Modified: 2025-04-02 00:00:00 +0000
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
        exportVaultService.fetchAllCiphersToExportResult = .failure(BitwardenTestError.example)

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
        exportVaultService.fetchAllCiphersToExportResult = .success([
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
        exportVaultService.fetchAllCiphersToExportResult = .success([
            .fixture(id: "1"),
        ])
        stateService.activeAccount = .fixture(
            profile: .fixture(
                email: "example@example.com",
                name: "Test",
                userId: "1",
            ),
        )
        clientService.mockExporters.exportCxfResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getExportVaultDataForCXF()
        }
    }
}

#endif
