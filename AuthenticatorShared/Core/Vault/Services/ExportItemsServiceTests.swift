import XCTest

@testable import AuthenticatorShared

// MARK: - ExportItemsServiceTests

final class ExportItemsServiceTests: AuthenticatorTestCase {
    // MARK: Properties

    var authItemRepository: MockAuthenticatorItemRepository!
    var errorReporter: MockErrorReporter!
    var importService: ImportItemsService!
    var timeProvider: MockTimeProvider!
    var subject: ExportItemsService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authItemRepository = MockAuthenticatorItemRepository()
        errorReporter = MockErrorReporter()
        timeProvider = MockTimeProvider(
            .mockTime(
                .init(
                    year: 2024,
                    month: 02,
                    day: 14
                )
            )
        )

        importService = DefaultImportItemsService(
            authenticatorItemRepository: authItemRepository,
            errorReporter: errorReporter
        )

        subject = DefaultExportItemsService(
            authenticatorItemRepository: authItemRepository,
            errorReporter: errorReporter,
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `exportFileContents` handles the CSV export
    ///
    func test_exportFileContents_csv() async throws {
        let fileType = ExportFileType.csv
        let items = [
            AuthenticatorItemView(
                favorite: false,
                id: "One",
                name: "Name",
                totpKey: "otpauth://totp/Bitwarden:person@example.com?secret=EXAMPLE&issuer=Bitwarden",
                username: "person@example.com"
            ),
        ]
        authItemRepository.fetchAllAuthenticatorItemsResult = .success(items)

        let exported = try await subject.exportFileContents(format: fileType)

        // swiftlint:disable line_length
        let expected =
            """
            folder,favorite,type,name,notes,fields,reprompt,login_uri,login_username,login_password,login_totp
            ,,login,Name,,,0,,person@example.com,,otpauth://totp/Bitwarden:person@example.com?secret=EXAMPLE&issuer=Bitwarden\n
            """
        // swiftlint:enable line_length
        XCTAssertEqual(exported, expected)
    }

    /// `exportFileContents` handles the JSON export
    ///
    func test_exportFileContents_json() async throws {
        let fileType = ExportFileType.json
        let items = [
            AuthenticatorItemView(
                favorite: false,
                id: "One",
                name: "Name",
                totpKey: "otpauth://totp/Bitwarden:person@example.com?secret=EXAMPLE&issuer=Bitwarden",
                username: "person@example.com"
            ),
            AuthenticatorItemView(
                favorite: true,
                id: "Two",
                name: "Steam",
                totpKey: "steam://EXAMPLE",
                username: "person@example.com"
            ),
        ]
        authItemRepository.fetchAllAuthenticatorItemsResult = .success(items)

        let exported = try await subject.exportFileContents(format: fileType)
        let decoder = JSONDecoder()
        let actual = try decoder.decode(VaultLike.self, from: exported.data(using: .utf8)!)
        let expected = VaultLike(encrypted: false, items: items.compactMap(CipherLike.init))
        XCTAssertEqual(actual, expected)
        try await importService.importItems(data: exported.data(using: .utf8)!, format: .json)
        let importedItems = authItemRepository.addAuthItemAuthItems
        XCTAssertEqual(importedItems, items)
    }

    /// `generateExportFileName` handles the JSON extension
    ///
    func test_fileName_json() {
        let fileType = ExportFileType.json
        let expectedName = "bitwarden_authenticator_export_20240214000000.json"
        let name = subject.generateExportFileName(format: fileType)
        XCTAssertEqual(name, expectedName)
    }
}
