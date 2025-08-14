import BitwardenKitMocks
import BitwardenSdk
import InlineSnapshotTesting
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - ExportVaultServiceTests

final class ExportVaultServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let cardCipher = Cipher(
        cipherView: .fixture(
            card: .init(
                cardholderName: "Card Name",
                expMonth: "01",
                expYear: "29",
                code: "555",
                brand: "Visa",
                number: "4400111122223333"
            ),
            folderId: "1234",
            id: "example-card-uuid",
            name: "Card",
            type: .card
        )
    )

    let deletedCipher = Cipher(
        cipherView: .loginFixture(
            deletedDate: .init(
                year: 2023,
                month: 12,
                day: 31
            ),
            id: "example-deleted-uuid",
            name: "Deleted"
        )
    )

    let folder = Folder.fixture(
        id: "1234",
        name: "Folder",
        revisionDate: .init(
            year: 2024,
            month: 01,
            day: 01
        )
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
                licenseNumber: nil
            ),
            name: "Identity",
            type: .identity
        )
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
                    fido2Credentials: nil
                )
            ),
            name: "Login",
            organizationId: nil,
            type: .login
        )
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
                    fido2Credentials: nil
                )
            ),
            name: "Login Org",
            organizationId: "123",
            type: .login
        )
    )

    let secureNoteCipher = Cipher(
        cipherView: .fixture(
            id: "example-note-uuid",
            name: "Secure Note",
            notes: "Secure content.",
            secureNote: .init(type: .generic),
            type: .secureNote
        )
    )

    var cipherService: MockCipherService!
    var clientService: MockClientService!
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
                cardCipher,
                deletedCipher,
                identityCipher,
                loginCipher,
                loginOrgCipher,
                secureNoteCipher,
            ]
        )
        errorReporter = MockErrorReporter()
        clientService = MockClientService()
        folderService = MockFolderService()
        policyService = MockPolicyService()
        stateService = MockStateService()
        clientService.mockExporters.exportVaultResult = .success("success")
        folderService.fetchAllFoldersResult = .success(
            [
                folder,
            ]
        )
        timeProvider = MockTimeProvider(
            .mockTime(
                .init(
                    year: 2024,
                    month: 02,
                    day: 14
                )
            )
        )
        subject = DefultExportVaultService(
            cipherService: cipherService,
            clientService: clientService,
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
    func test_fileContent_csv() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        _ = try await subject.exportVaultFileContents(format: ExportFileType.csv)
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            clientService.mockExporters.ciphers,
            [
                loginCipher,
                secureNoteCipher,
            ]
        )
    }

    /// `exportVaultFileContents(format:)` applies the correct content for encrypted JSON export type.
    ///
    func test_fileContent_encryptedJSON() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        _ = try await subject.exportVaultFileContents(format: ExportFileType.encryptedJson(password: "1234"))
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            Set(clientService.mockExporters.ciphers),
            Set([
                cardCipher,
                loginCipher,
                identityCipher,
                secureNoteCipher,
            ])
        )
    }

    /// `exportVaultFileContents(format:)` throws on a cipher fetch error.
    ///
    func test_fileContent_error_ciphers() async throws {
        cipherService.fetchAllCiphersResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.exportVaultFileContents(format: .csv)
        }
    }

    /// `exportVaultFileContents(format:)` throws on an export error.
    ///
    func test_fileContent_error_export() async throws {
        clientService.mockExporters.exportVaultResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.exportVaultFileContents(format: .csv)
        }
    }

    /// `exportVaultFileContents(format:)` throws on a folder fetch error.
    ///
    func test_fileContent_error_folders() async throws {
        folderService.fetchAllFoldersResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.exportVaultFileContents(format: .csv)
        }
    }

    /// `exportVaultFileContents(format:)` applies the correct content for JSON export type.
    ///
    func test_fileContent_json() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        _ = try await subject.exportVaultFileContents(format: ExportFileType.json)
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            clientService.mockExporters.ciphers,
            [
                cardCipher,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ]
        )
    }

    /// `exportVaultFileContents(format:)` doesn't filter ciphers if restrictedTypes is empty
    ///
    func test_fileContent_restrictedTypes_empty() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        policyService.getRestrictedItemCipherTypesResult = []
        _ = try await subject.exportVaultFileContents(format: ExportFileType.json)
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            clientService.mockExporters.ciphers,
            [
                cardCipher,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ]
        )
    }

    /// `exportVaultFileContents(format:)` excludes card ciphers when restrictedTypes contains `.card`
    ///
    func test_fileContent_restrictedTypes_excludeLogin() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        policyService.getRestrictedItemCipherTypesResult = [.card]
        _ = try await subject.exportVaultFileContents(format: ExportFileType.json)
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            clientService.mockExporters.ciphers,
            [
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ]
        )
    }

    /// `exportVaultFileContents(format:)` still applies login/secureNote filter when using CSV export
    /// with restrictedTypes.
    ///
    func test_fileContent_restrictedTypes_csvWithRestrictions() async throws {
        clientService.mockExporters.exportVaultResult = .success("success")
        policyService.getRestrictedItemCipherTypesResult = [.card]
        _ = try await subject.exportVaultFileContents(format: ExportFileType.csv)
        XCTAssertEqual(clientService.mockExporters.folders, [folder])
        XCTAssertEqual(
            clientService.mockExporters.ciphers,
            [
                loginCipher,
                secureNoteCipher,
            ]
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
            extension: ExportFileType.encryptedJson(password: "secure-password-1234?").fileExtension
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
