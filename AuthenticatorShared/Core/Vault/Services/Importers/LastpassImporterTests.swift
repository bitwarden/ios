import AuthenticatorSharedMocks
import XCTest

@testable import AuthenticatorShared

// swiftlint:disable line_length
final class LastpassImporterTests: BitwardenTestCase {
    /// Can import Raivo JSON
    func test_lastpassImport() throws {
        let data = ImportTestData.lastpassJson.data
        let expected = [
            AuthenticatorItemView(
                favorite: false,
                id: "One",
                name: "Name",
                totpKey: "otpauth://totp/Name:person%40example%2Ecom?secret=Secret1One&issuer=Name&algorithm=SHA1&digits=6&period=30",
                username: "person@example.com",
            ),
            AuthenticatorItemView(
                favorite: true,
                id: "Two",
                name: "Issuer2",
                totpKey: "otpauth://totp/Issuer2:name?secret=SecretTwo&issuer=Issuer2&algorithm=SHA512&digits=8&period=60",
                username: "name",
            ),
        ]
        let actual = try LastpassImporter.importItems(data: data)
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
