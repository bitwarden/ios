import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - ExportVaultServiceTests

final class ExportVaultServiceTests: BitwardenTestCase {
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

    let deletedCipehr = Cipher(
        cipherView: .loginFixture(
            deletedDate: .init(
                year: 2023,
                month: 12,
                day: 31
            ),
            id: "123"
        )
    )

    let folder = Folder.fixture(
        id: "1234",
        name: "Mock Folder",
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
                    autofillOnPageLoad: false
                )
            ),
            name: "Login",
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
    var errorReporter: MockErrorReporter!
    var exporters: MockClientExporters!
    var folderService: MockFolderService!
    var subject: ExportVaultService!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        cipherService.fetchAllCiphersResult = .success(
            [
                cardCipher,
                deletedCipehr,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ]
        )
        errorReporter = MockErrorReporter()
        exporters = MockClientExporters()
        exporters.exportVaultResult = .success("success")
        folderService = MockFolderService()
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
            clientExporters: exporters,
            errorReporter: errorReporter,
            folderService: folderService,
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        exporters = nil
        errorReporter = nil
        folderService = nil
        cipherService = nil
        timeProvider = nil
        subject = nil
    }

    // MARK: Tests

    /// Test the exporter receives the correct content for CSV export type.
    ///
    func test_fileContent_csv() async throws {
        let fileType = ExportFileType.csv
        exporters.exportVaultResult = .success("success")
        _ = try await subject.exportVaultFileContents(format: fileType)
        XCTAssertEqual(exporters.folders, [folder])
        XCTAssertEqual(
            exporters.ciphers,
            [
                loginCipher,
                secureNoteCipher,
            ]
        )
    }

    /// Test the exporter receives the correct content for encrypted JSON export type.
    ///
    func test_fileContent_encryptedJSON() async throws {
        let fileType = ExportFileType.encryptedJson(password: "1234")
        exporters.exportVaultResult = .success("success")
        _ = try await subject.exportVaultFileContents(format: fileType)
        XCTAssertEqual(exporters.folders, [folder])
        XCTAssertEqual(
            exporters.ciphers,
            [
                cardCipher,
                identityCipher,
                secureNoteCipher,
            ]
        )
    }

    /// Test the exporter throws on a cipher fetch error.
    ///
    func test_fileContent_error_ciphers() async throws {
        cipherService.fetchAllCiphersResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.exportVaultFileContents(format: .csv)
        }
    }

    /// Test the exporter throws on an export error.
    ///
    func test_fileContent_error_export() async throws {
        exporters.exportVaultResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.exportVaultFileContents(format: .csv)
        }
    }

    /// Test the exporter throws on a folder fetch error.
    ///
    func test_fileContent_error_folders() async throws {
        folderService.fetchAllFoldersResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.exportVaultFileContents(format: .csv)
        }
    }

    /// Test the exporter receives the correct content for JSON export type.
    ///
    func test_fileContent_json() async throws {
        let fileType = ExportFileType.json
        exporters.exportVaultResult = .success("success")
        _ = try await subject.exportVaultFileContents(format: fileType)
        XCTAssertEqual(exporters.folders, [folder])
        XCTAssertEqual(
            exporters.ciphers,
            [
                cardCipher,
                identityCipher,
                loginCipher,
                secureNoteCipher,
            ]
        )
    }

    /// Test the file name formatting for CSV export type.
    ///
    func test_fileName_csv() {
        let fileType = ExportFileType.csv
        let expectedName = "bitwarden_export_20240214000000.csv"
        let name = subject.generateExportFileName(extension: fileType.fileExtension)
        XCTAssertEqual(name, expectedName)
    }

    /// Test the file name formatting for encrypted JSON export type.
    ///
    func test_fileName_encryptedJSON() {
        let fileType = ExportFileType.encryptedJson(password: "secure-password-1234?")
        let expectedName = "bitwarden_export_20240214000000.json"
        let name = subject.generateExportFileName(extension: fileType.fileExtension)
        XCTAssertEqual(name, expectedName)
    }

    /// Test the file name formatting for JSON export type.
    ///
    func test_fileName_json() {
        let fileType = ExportFileType.json
        let expectedName = "bitwarden_export_20240214000000.json"
        let name = subject.generateExportFileName(extension: fileType.fileExtension)
        XCTAssertEqual(name, expectedName)
    }
}
