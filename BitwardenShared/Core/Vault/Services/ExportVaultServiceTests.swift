import BitwardenKitMocks
import BitwardenSdk
import InlineSnapshotTesting
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// swiftlint:disable file_length

// MARK: - ExportVaultServiceTests

final class ExportVaultServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let archivedCipher = Cipher(
        cipherView: .loginFixture(
            archivedDate: .init(year: 2024, month: 1, day: 15),
            id: "archived-uuid",
            name: "Archived Login",
        ),
    )

    let cardCipher = Cipher(
        cipherView: .fixture(
            card: .init(
                cardholderName: "Card Name",
                expMonth: "01",
                expYear: "29",
                code: "555",
                brand: "Visa",
                number: "4400111122223333",
            ),
            folderId: "1234",
            id: "example-card-uuid",
            name: "Card",
            type: .card,
        ),
    )

    let deletedCipher = Cipher(
        cipherView: .loginFixture(
            deletedDate: .init(
                year: 2023,
                month: 12,
                day: 31,
            ),
            id: "example-deleted-uuid",
            name: "Deleted",
        ),
    )

    let folder = Folder.fixture(
        id: "1234",
        name: "Folder",
        revisionDate: .init(
            year: 2024,
            month: 01,
            day: 01,
        ),
    )

    let identityCipher = Cipher(
        cipherView: .fixture(
            id: "example-identity-uuid",
            identity: .init(
                title: "Dr.",
                firstName: "Test",
                middleName: "Able",
                lastName: "User",
                address1: nil,
                address2: nil,
                address3: nil,
                city: nil,
                state: "MN",
                postalCode: nil,
                country: "USA",
                company: nil,
                email: "example@bitwarden.com",
                phone: nil,
                ssn: nil,
                username: nil,
                passportNumber: nil,
                licenseNumber: nil,
            ),
            name: "Identity",
            type: .identity,
        ),
    )

    let loginCipher = Cipher(
        cipherView: .fixture(
            id: "example-login-uuid",
            login: .init(
                .init(
                    username: "example@bitwarden.com",
                    password: "password9876",
                    passwordRevisionDate: nil,
                    uris: nil,
                    totp: nil,
                    autofillOnPageLoad: false,
                    fido2Credentials: nil,
                ),
            ),
            name: "Login",
            organizationId: nil,
            type: .login,
        ),
    )

    let loginOrgCipher = Cipher(
        cipherView: .fixture(
            id: "example-login-org-uuid",
            login: .init(
                .init(
                    username: "example@bitwarden.com",
                    password: "password9876",
                    passwordRevisionDate: nil,
                    uris: nil,
                    totp: nil,
                    autofillOnPageLoad: false,
                    fido2Credentials: nil,
                ),
            ),
            name: "Login Org",
            organizationId: "123",
            type: .login,
        ),
    )

    let secureNoteCipher = Cipher(
        cipherView: .fixture(
            id: "example-note-uuid",
            name: "Secure Note",
            notes: "Secure content.",
            secureNote: .init(type: .generic),
            type: .secureNote,
        ),
    )

    var cipherService: MockCipherService!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var folderService: MockFolderService!
    var stateService: MockStateService!
    var subject: ExportVaultService!
    var timeProvider: MockTimeProvider!
    var policyService: MockPolicyService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        cipherService.fetchAllCiphersResult = .success(
            [
                archivedCipher,
                cardCipher,
                deletedCipher,
                identityCipher,
                loginCipher,
                loginOrgCipher,
                secureNoteCipher,
            ],
        )
        configService = MockConfigService()
        // Enable the archive feature flag by default to exclude archived items in existing tests
        configService.featureFlagsBool[.archiveVaultItems] = true
        errorReporter = MockErrorReporter()
        clientService = MockClientService()
        folderService = MockFolderService()
        policyService = MockPolicyService()
        stateService = MockStateService()
        clientService.mockExporters.exportVaultResult = .success("success")
        folderService.fetchAllFoldersResult = .success(
            [
                folder,
            ],
        )
        timeProvider = MockTimeProvider(
            .mockTime(
                .init(
                    year: 2024,
                    month: 02,
                    day: 14,
                ),
            ),
        )
        subject = DefaultExportVaultService(
            cipherService: cipherService,
            clientService: clientService,
            configService: configService,
            errorReporter: errorReporter,
            folderService: folderService,
            policyService: policyService,
            stateService: stateService,
            timeProvider: timeProvider,
        )
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        cipherService = nil
        configService = nil
        errorReporter = nil
        folderService = nil
        timeProvider = nil
        stateService = nil
        policyService = nil
        subject = nil
    }

    // MARK: Tests

    /// `exportVaultFileContents(format:)` applies the correct content for CSV export type.
    ///
    func test_exportVaultFileContents_csv() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        _ = try await subject.exportVaultFileContents(format: ExportFileType.csv, includeArchivedItems: true)
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            clientService.mockExporters.ciphers,
            [
                archivedCipher,
                loginCipher,
                secureNoteCipher,
            ],
        )
    }

    /// `exportVaultFileContents(format:)` applies the correct content for encrypted JSON export type.
    ///
    func test_exportVaultFileContents_encryptedJSON() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        _ = try await subject.exportVaultFileContents(
            format: ExportFileType.encryptedJson(password: "1234"),
            includeArchivedItems: true,
        )
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            Set(clientService.mockExporters.ciphers),
            Set([
                archivedCipher,
                cardCipher,
                loginCipher,
                identityCipher,
                secureNoteCipher,
            ]),
        )
    }

    /// `exportVaultFileContents(format:)` throws on a cipher fetch error.
    ///
    func test_exportVaultFileContents_error_ciphers() async throws {
        cipherService.fetchAllCiphersResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.exportVaultFileContents(format: .csv, includeArchivedItems: true)
        }
    }

    /// `exportVaultFileContents(format:)` throws on an export error.
    ///
    func test_exportVaultFileContents_error_export() async throws {
        clientService.mockExporters.exportVaultResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.exportVaultFileContents(format: .csv, includeArchivedItems: true)
        }
    }

    /// `exportVaultFileContents(format:)` throws on a folder fetch error.
    ///
    func test_exportVaultFileContents_error_folders() async throws {
        folderService.fetchAllFoldersResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.exportVaultFileContents(format: .csv, includeArchivedItems: true)
        }
    }

    /// `exportVaultFileContents(format:includeArchivedItems:)` excludes archived ciphers when
    /// `includeArchivedItems` is false.
    ///
    func test_exportVaultFileContents_excludeArchivedItems() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        _ = try await subject.exportVaultFileContents(format: .json, includeArchivedItems: false)
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            Set(clientService.mockExporters.ciphers),
            Set([
                cardCipher,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ]),
        )
    }

    /// `exportVaultFileContents(format:includeArchivedItems:)` includes archived ciphers when
    /// `includeArchivedItems` is false but the archive vault items FF is disabled.
    ///
    @MainActor
    func test_exportVaultFileContents_includeArchivedItemsWithFFDisabled() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        configService.featureFlagsBool[.archiveVaultItems] = false
        _ = try await subject.exportVaultFileContents(format: .json, includeArchivedItems: false)
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            Set(clientService.mockExporters.ciphers),
            Set([
                archivedCipher,
                cardCipher,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ]),
        )
    }

    /// `exportVaultFileContents(format:)` applies the correct content for JSON export type.
    ///
    func test_exportVaultFileContents_json() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        _ = try await subject.exportVaultFileContents(format: ExportFileType.json, includeArchivedItems: true)
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            clientService.mockExporters.ciphers,
            [
                archivedCipher,
                cardCipher,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ],
        )
    }

    /// `exportVaultFileContents(format:)` doesn't filter ciphers if restrictedTypes is empty
    ///
    func test_exportVaultFileContents_restrictedTypes_empty() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        policyService.getRestrictedItemCipherTypesResult = []
        _ = try await subject.exportVaultFileContents(format: ExportFileType.json, includeArchivedItems: true)
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            clientService.mockExporters.ciphers,
            [
                archivedCipher,
                cardCipher,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ],
        )
    }

    /// `exportVaultFileContents(format:)` excludes card ciphers when restrictedTypes contains `.card`
    ///
    @MainActor
    func test_exportVaultFileContents_restrictedTypes_excludeCard() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        policyService.getRestrictedItemCipherTypesResult = [.card]
        _ = try await subject.exportVaultFileContents(format: ExportFileType.json, includeArchivedItems: true)
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            clientService.mockExporters.ciphers,
            [
                archivedCipher,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ],
        )
    }

    /// `exportVaultFileContents(format:)` still applies login/secureNote filter when using CSV export
    /// with restrictedTypes.
    ///
    func test_exportVaultFileContents_restrictedTypes_csvWithRestrictions() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        policyService.getRestrictedItemCipherTypesResult = [.card]
        _ = try await subject.exportVaultFileContents(format: ExportFileType.csv, includeArchivedItems: true)
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            clientService.mockExporters.ciphers,
            [
                archivedCipher,
                loginCipher,
                secureNoteCipher,
            ],
        )
    }

    /// `fetchAllCiphersToExport()` fetches all ciphers to be exported.
    ///
    @MainActor
    func test_fetchAllCiphersToExport() async throws {
        let ciphers = try await subject.fetchAllCiphersToExport(includeArchivedItems: true)
        XCTAssertEqual(
            ciphers,
            [
                archivedCipher,
                cardCipher,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ],
        )
    }

    /// `fetchAllCiphersToExport()` includes archived ciphers when the feature flag is disabled,
    /// regardless of `includeArchivedItems` parameter.
    ///
    @MainActor
    func test_fetchAllCiphersToExport_archivedWithFFDisabled() async throws {
        configService.featureFlagsBool[.archiveVaultItems] = false
        let ciphers = try await subject.fetchAllCiphersToExport(includeArchivedItems: false)
        XCTAssertEqual(
            ciphers,
            [
                archivedCipher,
                cardCipher,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ],
        )
    }

    /// `fetchAllCiphersToExport()` excludes archived items when `includeArchivedItems` is false.
    ///
    @MainActor
    func test_fetchAllCiphersToExport_excludesArchived() async throws {
        let ciphers = try await subject.fetchAllCiphersToExport(includeArchivedItems: false)
        XCTAssertEqual(
            ciphers,
            [
                cardCipher,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ],
        )
    }

    /// `fetchAllCiphersToExport()` fetches all ciphers to be exported except `.card` items
    /// given there are restricted types.
    ///
    @MainActor
    func test_fetchAllCiphersToExport_restrictedItemCipherTypes() async throws {
        policyService.getRestrictedItemCipherTypesResult = [.card]
        let ciphers = try await subject.fetchAllCiphersToExport(includeArchivedItems: true)
        XCTAssertEqual(
            ciphers,
            [
                archivedCipher,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ],
        )
    }

    /// `generateExportFileName(extension:)` applies correct file name formatting for CSV export type.
    ///
    func test_fileName_csv() {
        let expectedName = "bitwarden_export_20240214000000.csv"
        let name = subject.generateExportFileName(extension: ExportFileType.csv.fileExtension)
        XCTAssertEqual(name, expectedName)
    }

    /// `generateExportFileName(extension:)` applies correct file name formatting for encrypted JSON export type.
    ///
    func test_fileName_encryptedJSON() {
        let expectedName = "bitwarden_export_20240214000000.json"
        let name = subject.generateExportFileName(
            extension: ExportFileType.encryptedJson(password: "secure-password-1234?").fileExtension,
        )
        XCTAssertEqual(name, expectedName)
    }

    /// `generateExportFileName(extension:)` applies correct file name formatting for JSON export type.
    ///
    func test_fileName_json() {
        let expectedName = "bitwarden_export_20240214000000.json"
        let name = subject.generateExportFileName(extension: ExportFileType.json.fileExtension)
        XCTAssertEqual(name, expectedName)
    }
}
