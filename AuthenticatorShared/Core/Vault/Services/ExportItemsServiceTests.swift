import XCTest

@testable import AuthenticatorShared

// MARK: - ExportItemsServiceTests

final class ExportItemsServiceTests: AuthenticatorTestCase {
    // MARK: Properties

    var authItemRepository: MockAuthenticatorItemRepository!
    var errorReporter: MockErrorReporter!
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

    /// `exportFileContents` handles the JSON export
    ///
    func test_exportFileContents_json() async throws {
        let fileType = ExportFileType.json
        let items = [
            AuthenticatorItemView(
                id: "One",
                name: "Name",
                totpKey: "otpauth://totp/Bitwarden:person@example.com?secret=EXAMPLE&issuer=Bitwarden"
            ),
        ]
        authItemRepository.fetchAllAuthenticatorItemsResult = .success(items)

        let exported = try await subject.exportFileContents(format: fileType)

        let decoder = JSONDecoder()
        let actual = try decoder.decode([AuthenticatorItemView].self, from: exported.data(using: .utf8)!)
        XCTAssertEqual(items, actual)
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
