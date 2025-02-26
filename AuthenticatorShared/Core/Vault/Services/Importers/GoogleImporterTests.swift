import XCTest

@testable import AuthenticatorShared

// swiftlint:disable line_length
final class GoogleImporterTests: AuthenticatorTestCase {
    /// Can import Google protobuf
    func test_googleImport() throws {
        let data = "otpauth-migration://offline?data=ChgKCkhlbGxvId6tvu8SBE5hbWUgASgBMAIKGwoMAESNbONNjj/vBKjSEgVOYW1lMiABKAEwAhACGAEgAA%3D%3D".data(using: .utf8)!
        let expected = [
            AuthenticatorItemView(
                favorite: false,
                id: "One",
                name: "Name",
                totpKey: "otpauth://totp/Name?secret=JBSWY3DPEHPK3PXP&algorithm=SHA1&digits=6&period=30",
                username: "Name"
            ),
            AuthenticatorItemView(
                favorite: false,
                id: "Two",
                name: "Name2",
                totpKey: "otpauth://totp/Name2?secret=ABCI23HDJWHD73YEVDJA&algorithm=SHA1&digits=6&period=30",
                username: "Name2"
            ),
        ]
        let actual = try GoogleImporter.importItems(data: data)
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
