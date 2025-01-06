#if compiler(>=6.0.3)
import AuthenticationServices
import XCTest

@testable import BitwardenShared

// MARK: - ImportCiphersRepositoryTests

class ImportCiphersRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var clientService: MockClientService!
    var credentialManagerFactory: MockCredentialManagerFactory!
    var importCiphersService: MockImportCiphersService!
    var syncService: MockSyncService!
    var subject: ImportCiphersRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        credentialManagerFactory = MockCredentialManagerFactory()
        importCiphersService = MockImportCiphersService()
        syncService = MockSyncService()
        subject = DefaultImportCiphersRepository(
            clientService: clientService,
            credentialManagerFactory: credentialManagerFactory,
            importCiphersService: importCiphersService,
            syncService: syncService
        )
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        credentialManagerFactory = nil
        importCiphersService = nil
        subject = nil
        syncService = nil
    }

    // MARK: Tests

    /// `importCiphers(credentialImportToken:progressDelegate:)` imports the ciphers,
    /// updates progress report and returns the credentials result with each type count.
    @MainActor
    func test_importCiphers_success() async throws {
        guard #available(iOS 18.2, *) else {
            throw XCTSkip("Importing ciphers requires iOS 18.2")
        }

        let credentialImportManager = MockCredentialImportManager()
        credentialImportManager.importCredentialsResult =
            .success(
                ASExportedCredentialData(
                    accounts: [
                        .fixture(items: [.fixture()]),
                    ]
                )
            )
        credentialManagerFactory.importManager = credentialImportManager

        clientService.mockExporters.importCxfResult = .success([
            .fixture(id: "1", login: .fixture(), type: .login),
            .fixture(id: "2", login: .fixture(), type: .login),
            .fixture(id: "3", login: .fixture(fido2Credentials: [.fixture()]), type: .login),
            .fixture(id: "4", type: .card),
            .fixture(id: "5", type: .card),
            .fixture(id: "6", type: .card),
            .fixture(id: "7", type: .identity),
            .fixture(id: "8", type: .secureNote),
            .fixture(id: "9", type: .secureNote),
            .fixture(id: "10", type: .sshKey),
        ])

        let expectedResults = [
            ImportedCredentialsResult(count: 2, type: .password),
            ImportedCredentialsResult(count: 1, type: .passkey),
            ImportedCredentialsResult(count: 3, type: .card),
            ImportedCredentialsResult(count: 1, type: .identity),
            ImportedCredentialsResult(count: 2, type: .secureNote),
            ImportedCredentialsResult(count: 1, type: .sshKey),
        ]

        var progressReports: [Double] = []
        let result = try await subject.importCiphers(
            credentialImportToken: UUID(
                uuidString: "e8f3b381-aac2-4379-87fe-14fac61079ec"
            )!,
            onProgress: { progress in progressReports.append(progress) }
        )

        XCTAssertNotNil(clientService.mockExporters.importCxfPayload)
        XCTAssertTrue(importCiphersService.importCiphersCalled)
        XCTAssertEqual(importCiphersService.importCiphersCiphers?.count, 10)
        XCTAssertTrue(syncService.didFetchSync)
        XCTAssertTrue(syncService.fetchSyncForceSync == true)
        XCTAssertEqual(progressReports, [0.3, 0.8, 1.0])
        XCTAssertEqual(result, expectedResults)
    }

    /// `importCiphers(credentialImportToken:progressDelegate:)` throws `noDataFound`
    /// when there are no accounts after importing credentials.
    @MainActor
    func test_importCiphers_noDataFound() async throws {
        guard #available(iOS 18.2, *) else {
            throw XCTSkip("Importing ciphers requires iOS 18.2")
        }

        let credentialImportManager = MockCredentialImportManager()
        credentialImportManager.importCredentialsResult =
            .success(
                ASExportedCredentialData(
                    accounts: []
                )
            )
        credentialManagerFactory.importManager = credentialImportManager

        await assertAsyncThrows(error: ImportCiphersRepositoryError.noDataFound) {
            _ = try await subject.importCiphers(
                credentialImportToken: UUID(
                    uuidString: "e8f3b381-aac2-4379-87fe-14fac61079ec"
                )!,
                onProgress: { _ in }
            )
        }
    }

    /// `importCiphers(credentialImportToken:progressDelegate:)` throws when calling
    /// the SDK to import the ciphers.
    @MainActor
    func test_importCiphers_sdkThrows() async throws {
        guard #available(iOS 18.2, *) else {
            throw XCTSkip("Importing ciphers requires iOS 18.2")
        }

        let credentialImportManager = MockCredentialImportManager()
        credentialImportManager.importCredentialsResult =
            .success(
                ASExportedCredentialData(
                    accounts: [
                        .fixture(items: [.fixture()]),
                    ]
                )
            )
        credentialManagerFactory.importManager = credentialImportManager

        clientService.mockExporters.importCxfResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.importCiphers(
                credentialImportToken: UUID(
                    uuidString: "e8f3b381-aac2-4379-87fe-14fac61079ec"
                )!,
                onProgress: { _ in }
            )
        }
    }

    /// `importCiphers(credentialImportToken:progressDelegate:)` throws when calling the API
    /// to import the ciphers.
    @MainActor
    func test_importCiphers_throwsWhenImportingCiphersAPI() async throws {
        guard #available(iOS 18.2, *) else {
            throw XCTSkip("Importing ciphers requires iOS 18.2")
        }

        let credentialImportManager = MockCredentialImportManager()
        credentialImportManager.importCredentialsResult =
            .success(
                ASExportedCredentialData(
                    accounts: [
                        .fixture(items: [.fixture()]),
                    ]
                )
            )
        credentialManagerFactory.importManager = credentialImportManager

        clientService.mockExporters.importCxfResult = .success([
            .fixture(id: "1", login: .fixture(), type: .login),
            .fixture(id: "2", login: .fixture(), type: .login),
        ])

        importCiphersService.importCiphersError = BitwardenTestError.example

        var progressReports: [Double] = []
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.importCiphers(
                credentialImportToken: UUID(
                    uuidString: "e8f3b381-aac2-4379-87fe-14fac61079ec"
                )!,
                onProgress: { progress in progressReports.append(progress) }
            )
        }
        XCTAssertEqual(progressReports, [0.3])
    }

    /// `importCiphers(credentialImportToken:progressDelegate:)` throws when syncing after
    /// importing the ciphers.
    @MainActor
    func test_importCiphers_throwsWhenSyncing() async throws {
        guard #available(iOS 18.2, *) else {
            throw XCTSkip("Importing ciphers requires iOS 18.2")
        }

        let credentialImportManager = MockCredentialImportManager()
        credentialImportManager.importCredentialsResult =
            .success(
                ASExportedCredentialData(
                    accounts: [
                        .fixture(items: [.fixture()]),
                    ]
                )
            )
        credentialManagerFactory.importManager = credentialImportManager

        clientService.mockExporters.importCxfResult = .success([
            .fixture(id: "1", login: .fixture(), type: .login),
            .fixture(id: "2", login: .fixture(), type: .login),
        ])

        syncService.fetchSyncResult = .failure(BitwardenTestError.example)

        var progressReports: [Double] = []
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.importCiphers(
                credentialImportToken: UUID(
                    uuidString: "e8f3b381-aac2-4379-87fe-14fac61079ec"
                )!,
                onProgress: { progress in progressReports.append(progress) }
            )
        }
        XCTAssertEqual(progressReports, [0.3, 0.8])
    }
}
#endif
