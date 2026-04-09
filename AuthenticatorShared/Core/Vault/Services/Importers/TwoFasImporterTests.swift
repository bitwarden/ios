import AuthenticatorSharedMocks
import XCTest

@testable import AuthenticatorShared

// swiftlint:disable line_length
final class TwoFasImporterTests: BitwardenTestCase {
    /// Can import 2FAS JSON
    func test_twoFasImport() throws {
        let data = ImportTestData.twoFasJson.data
        let expected = [
            AuthenticatorItemView(
                favorite: false,
                id: "One",
                name: "Name",
                totpKey: "otpauth://totp/Name:person%40example%2Ecom?secret=Secret1One&issuer=Name&algorithm=SHA1&digits=6&period=30",
                username: "person@example.com",
            ),
            AuthenticatorItemView(
                favorite: false,
                id: "Two",
                name: "Issuer2",
                totpKey: "otpauth://totp/?secret=SecretTwo&issuer=Issuer2&algorithm=SHA256&digits=8&period=60",
                username: nil,
            ),
            AuthenticatorItemView(
                favorite: false,
                id: "Three",
                name: "Steam",
                totpKey: "steam://STEAMSECRET",
                username: "addl",
            ),
        ]
        let actual = try TwoFasImporter.importItems(data: data)
        XCTAssertEqual(actual.count, expected.count)
        zip(actual, expected).forEach { actualItem, expectedItem in
            XCTAssertEqual(actualItem.favorite, expectedItem.favorite)
            XCTAssertEqual(actualItem.name, expectedItem.name)
            XCTAssertEqual(actualItem.totpKey, expectedItem.totpKey)
            XCTAssertEqual(actualItem.username, expectedItem.username)
        }
    }
}

// swiftlint:enable line_length
