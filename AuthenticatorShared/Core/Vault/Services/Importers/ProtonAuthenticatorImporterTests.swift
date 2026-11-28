import AuthenticatorSharedMocks
import Foundation
import Testing

@testable import AuthenticatorShared

// MARK: - ProtonAuthenticatorImporterTests

struct ProtonAuthenticatorImporterTests {
    // MARK: Static Properties

    /// The items expected from `ProtonAuthenticatorExport.json`.
    private static let fixtureItems = [
        ExpectedItem(
            name: "SimpleLogin",
            totpKey: "otpauth://totp/SimpleLogin:john%2Edoe%40example%2Ecom"
                + "?secret=JBSWY3DPEHPK3PXP&issuer=SimpleLogin&algorithm=SHA1&digits=6&period=30",
            username: "john.doe@example.com",
        ),
        ExpectedItem(
            name: "Work VPN",
            totpKey: "otpauth://totp/?secret=KRSXG5CTMVRXEZLU"
                + "&issuer=Work%20VPN&algorithm=SHA256&digits=8&period=60",
            username: nil,
        ),
        ExpectedItem(
            name: "example.com",
            totpKey: "otpauth://totp/example%2Ecom:Example"
                + "?secret=JBSWY3DPEHPK3PXQ&issuer=example%2Ecom&algorithm=SHA512&digits=6&period=30",
            username: "Example",
        ),
        ExpectedItem(
            name: "GitHub",
            totpKey: "otpauth://totp/GitHub:octocat"
                + "?secret=GEZDGNBVGY3TQOJQ&issuer=GitHub&algorithm=SHA1&digits=6&period=30",
            username: "octocat",
        ),
        ExpectedItem(
            name: "My Company",
            totpKey: "otpauth://totp/My%20Company:jane%40example%2Ecom"
                + "?secret=MFRGGZDFMZTWQ2LK&issuer=My%20Company&algorithm=SHA1&digits=6&period=30",
            username: "jane@example.com",
        ),
        ExpectedItem(
            name: "A+B",
            totpKey: "otpauth://totp/A%2BB:admin"
                + "?secret=MFRGGZDFMZTWQ2LL&issuer=A%2BB&algorithm=SHA1&digits=6&period=30",
            username: "admin",
        ),
        ExpectedItem(
            name: "Dashed",
            totpKey: "otpauth://totp/Dashed:dashed"
                + "?secret=JBSWY3DPEHPK3PXP&issuer=Dashed&algorithm=SHA1&digits=6&period=30",
            username: "dashed",
        ),
        ExpectedItem(
            name: "Raw",
            totpKey: "otpauth://totp/Raw:raw"
                + "?secret=JVMVGRKDKJCVIMI&issuer=Raw&algorithm=SHA1&digits=6&period=30",
            username: "raw",
        ),
        ExpectedItem(name: "Steam", totpKey: "steam://JBSWY3DPEHPK3PXP", username: "Main account"),
        ExpectedItem(
            name: "Steam",
            totpKey: "steam://77776ERUKZ4JVPG66AISEM2EKVTHPCEZ",
            username: "Base 64 secret",
        ),
    ]

    // MARK: Tests

    /// `importItems(data:)` maps TOTP and Steam entries, cleans secrets like Proton and skips unknown types.
    @Test
    func importItems() throws {
        let actual = try ProtonAuthenticatorImporter.importItems(data: ImportTestData.protonAuthenticatorJson.data)

        #expect(actual.map(ExpectedItem.init) == Self.fixtureItems)
        #expect(actual.allSatisfy { !$0.favorite })
        #expect(Set(actual.map(\.id)).count == actual.count)
    }

    /// `importItems(data:)` returns no items for an export without entries.
    @Test
    func importItems_emptyEntries() throws {
        let actual = try ProtonAuthenticatorImporter.importItems(data: Data(#"{"version":1,"entries":[]}"#.utf8))

        #expect(actual.isEmpty)
    }

    /// `importItems(data:)` accepts a byte order mark, CRLF line endings, any entry type case, and
    /// entries without a name, id or note. A Steam name that repeats the title is dropped.
    @Test
    func importItems_lenientFormatting() throws {
        let json = """
        {
        "version": 1,
        "entries": [
        {"content": {"uri": "otpauth://totp/?secret=JBSWY3DPEHPK3PXP&issuer=Example",
        "entry_type": "TOTP", "name": null}},
        {"content": {"uri": "STEAM://JBSWY3DPEHPK3PXP", "entry_type": "steam", "name": "Steam"}}
        ]
        }
        """.replacingOccurrences(of: "\n", with: "\r\n")
        let data = Data([0xEF, 0xBB, 0xBF]) + Data(json.utf8)

        let actual = try ProtonAuthenticatorImporter.importItems(data: data)

        #expect(actual.map(ExpectedItem.init) == [
            ExpectedItem(
                name: "Example",
                totpKey: "otpauth://totp/?secret=JBSWY3DPEHPK3PXP&issuer=Example&algorithm=SHA1&digits=6&period=30",
                username: nil,
            ),
            ExpectedItem(name: "Steam", totpKey: "steam://JBSWY3DPEHPK3PXP", username: nil),
        ])
    }

    /// `importItems(data:)` throws a `dataCorrupted` error for a file that isn't JSON.
    @Test
    func importItems_malformed() throws {
        let error = #expect(throws: DecodingError.self) {
            try ProtonAuthenticatorImporter.importItems(data: Data("not json".utf8))
        }

        guard case .dataCorrupted = error else {
            Issue.record("Expected dataCorrupted, got \(String(describing: error))")
            return
        }
    }

    /// `importItems(data:)` throws a `keyNotFound` error when an unencrypted export has no entries key.
    @Test
    func importItems_missingEntries() throws {
        let error = #expect(throws: DecodingError.self) {
            try ProtonAuthenticatorImporter.importItems(data: Data(#"{"version":1}"#.utf8))
        }

        guard case let .keyNotFound(key, _) = error else {
            Issue.record("Expected keyNotFound, got \(String(describing: error))")
            return
        }
        #expect(key.stringValue == "entries")
    }

    /// `importItems(data:)` uses the entry name as the title when the uri has no issuer or label.
    @Test
    func importItems_nameFallback() throws {
        let json = """
        {"version":1,"entries":[{"id":"1","content":{
        "uri":"otpauth://totp/?secret=JBSWY3DPEHPK3PXP","entry_type":"Totp","name":"Fallback"}}]}
        """

        let actual = try ProtonAuthenticatorImporter.importItems(data: Data(json.utf8))

        #expect(actual.map(ExpectedItem.init) == [
            ExpectedItem(
                name: "Fallback",
                totpKey: "otpauth://totp/?secret=JBSWY3DPEHPK3PXP&issuer=Fallback&algorithm=SHA1&digits=6&period=30",
                username: nil,
            ),
        ])
    }

    /// `importItems(data:)` uppercases only ASCII letters in a secret, like Proton, before falling back to
    /// the secret's raw bytes.
    @Test
    func importItems_nonAsciiSecret() throws {
        let json = """
        {"version":1,"entries":[{"content":{
        "uri":"otpauth://totp/?secret=abc%C3%9F1&issuer=Example","entry_type":"Totp"}}]}
        """

        let actual = try ProtonAuthenticatorImporter.importItems(data: Data(json.utf8))

        #expect(actual.map(\.totpKey) == [
            "otpauth://totp/?secret=IFBEHQ47GE&issuer=Example&algorithm=SHA1&digits=6&period=30",
        ])
    }

    /// `importItems(data:)` throws `passwordProtectedFile` for a password-protected export.
    @Test
    func importItems_passwordProtected() throws {
        let json = #"{"version":1,"salt":"c2FsdHNhbHRzYWx0c2FsdA==","content":"ZW5jcnlwdGVk"}"#

        #expect(throws: ProtonAuthenticatorImporterError.passwordProtectedFile) {
            try ProtonAuthenticatorImporter.importItems(data: Data(json.utf8))
        }
    }

    /// `importItems(data:)` round-trips the account name through the stored TOTP key.
    @Test
    func importItems_totpKeyParsesBack() throws {
        let actual = try ProtonAuthenticatorImporter.importItems(data: ImportTestData.protonAuthenticatorJson.data)

        let keys = actual.compactMap { TOTPKey($0.totpKey ?? "") }
        #expect(keys.count == actual.count)
        #expect(keys.map(\.accountName) == [
            "john.doe@example.com", nil, "Example", "octocat", "jane@example.com", "admin", "dashed", "raw", nil, nil,
        ])
        #expect(keys.map(\.digits) == [6, 8, 6, 6, 6, 6, 6, 6, 5, 5])
        #expect(keys.map(\.period) == [30, 60, 30, 30, 30, 30, 30, 30, 30, 30])
        #expect(keys.map(\.algorithm) == [.sha1, .sha256, .sha512, .sha1, .sha1, .sha1, .sha1, .sha1, .sha1, .sha1])
    }

    /// `importItems(data:)` fails the whole import when a TOTP or Steam entry can't be read.
    @Test(arguments: [
        ("Totp", "otpauth://totp/Name?issuer=Example"),
        ("Totp", "otpauth://totp/Name?secret=&issuer=Example"),
        ("Totp", "otpauth://totp/Name?secret=--__"),
        ("Totp", "otpauth://hotp/Name?secret=JBSWY3DPEHPK3PXP"),
        ("Totp", "https://totp/Name?secret=JBSWY3DPEHPK3PXP"),
        ("Totp", "otpauth://totp/Name?secret=JBSWY3DPEHPK3PXP&algorithm=MD5"),
        ("Totp", "otpauth://totp/Name?secret=JBSWY3DPEHPK3PXP&digits=4"),
        ("Totp", "otpauth://totp/Name?secret=JBSWY3DPEHPK3PXP&digits=11"),
        ("Totp", "otpauth://totp/Name?secret=JBSWY3DPEHPK3PXP&digits=six"),
        ("Totp", "otpauth://totp/Name?secret=JBSWY3DPEHPK3PXP&period=0"),
        ("Totp", "steam://JBSWY3DPEHPK3PXP"),
        ("Steam", "steam://"),
        ("Steam", "steam://not base 64!"),
        ("Steam", "otpauth://totp/Name?secret=JBSWY3DPEHPK3PXP"),
    ])
    func importItems_unreadableEntry(entryType: String, uri: String) throws {
        let entries = [
            ["content": ["uri": "otpauth://totp/Valid?secret=JBSWY3DPEHPK3PXP", "entry_type": "Totp"]],
            ["content": ["uri": uri, "entry_type": entryType]],
        ]
        let data = try JSONSerialization.data(withJSONObject: ["version": 1, "entries": entries])

        #expect(throws: ProtonAuthenticatorImporterError.unreadableEntry) {
            try ProtonAuthenticatorImporter.importItems(data: data)
        }
    }

    /// `importItems(data:)` throws a `dataCorrupted` error for an unsupported version.
    @Test
    func importItems_unsupportedVersion() throws {
        let error = #expect(throws: DecodingError.self) {
            try ProtonAuthenticatorImporter.importItems(data: Data(#"{"version":2,"entries":[]}"#.utf8))
        }

        guard case let .dataCorrupted(context) = error else {
            Issue.record("Expected dataCorrupted, got \(String(describing: error))")
            return
        }
        #expect(context.codingPath.map(\.stringValue) == ["version"])
    }

    /// `importItems(data:)` throws a `typeMismatch` error when a field has the wrong type.
    @Test
    func importItems_wrongType() throws {
        let json = #"{"version":1,"entries":[{"content":{"uri":1,"entry_type":"Totp"}}]}"#

        let error = #expect(throws: DecodingError.self) {
            try ProtonAuthenticatorImporter.importItems(data: Data(json.utf8))
        }

        guard case .typeMismatch = error else {
            Issue.record("Expected typeMismatch, got \(String(describing: error))")
            return
        }
    }
}

// MARK: - ExpectedItem

/// The fields of an imported item that the tests compare. The id is random per import.
///
private struct ExpectedItem: Equatable {
    let name: String
    let totpKey: String?
    let username: String?

    init(name: String, totpKey: String?, username: String?) {
        self.name = name
        self.totpKey = totpKey
        self.username = username
    }

    init(_ item: AuthenticatorItemView) {
        self.init(name: item.name, totpKey: item.totpKey, username: item.username)
    }
}
