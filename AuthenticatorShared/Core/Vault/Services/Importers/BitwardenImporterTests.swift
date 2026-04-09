import AuthenticatorSharedMocks
import XCTest

@testable import AuthenticatorShared

final class BitwardenImporterTests: BitwardenTestCase {
    /// Can import Bitwarden JSON
    func test_raivoImport() throws {
        let data = ImportTestData.bitwardenJson.data
        let expected = [
            AuthenticatorItemView(
                favorite: false,
                id: "One",
                name: "Name",
                totpKey: "otpauth://totp/Bitwarden:person@example.com?secret=EXAMPLE&issuer=Bitwarden",
                username: "person@example.com",
            ),
            AuthenticatorItemView(
                favorite: true,
                id: "Two",
                name: "Steam",
                totpKey: "steam://EXAMPLE",
                username: "person@example.com",
            ),
        ]
        let actual = try BitwardenImporter.importItems(data: data)
        XCTAssertEqual(actual, expected)
    }
}
