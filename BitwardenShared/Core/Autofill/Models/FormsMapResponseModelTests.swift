import Foundation
import Testing

@testable import BitwardenShared

// MARK: - FormsMapResponseModelTests

struct FormsMapResponseModelTests {
    // MARK: Tests - FormsMapResponseModel

    /// `init(from:)` excludes null-valued host entries during decoding.
    @Test
    func decode_nullHostsExcluded() throws {
        let json = """
        {
            "schemaVersion": "0.1.0",
            "hosts": {
                "example.com": {
                    "forms": [{
                        "category": "account-login",
                        "fields": { "username": ["input#user"] }
                    }]
                },
                "irrelevant.com": null
            }
        }
        """
        let model = try JSONDecoder().decode(FormsMapResponseModel.self, from: Data(json.utf8))
        #expect(model.hosts.keys.contains("example.com"))
        #expect(!model.hosts.keys.contains("irrelevant.com"))
        #expect(model.hosts.count == 1)
    }

    // MARK: Tests - FormsMapHostEntry

    /// `init(from:)` excludes null-valued pathname entries during decoding.
    @Test
    func decode_nullPathnamesExcluded() throws {
        let json = """
        {
            "schemaVersion": "1.0.0",
            "hosts": {
                "example.com": {
                    "pathnames": {
                        "/login": {
                            "forms": [{
                                "category": "account-login",
                                "fields": { "username": ["input#user"] }
                            }]
                        },
                        "/irrelevant": null
                    }
                }
            }
        }
        """
        let model = try JSONDecoder().decode(FormsMapResponseModel.self, from: Data(json.utf8))
        let pathnames = try #require(model.hosts["example.com"]?.pathnames)
        #expect(pathnames.keys.contains("/login"))
        #expect(!pathnames.keys.contains("/irrelevant"))
        #expect(pathnames.count == 1)
    }

    // MARK: Tests - FormsMapSelector

    /// `init(from:)` decodes a JSON string as `.single`.
    @Test
    func formsMapSelector_decodeSingle() throws {
        let json = #""input#username""#
        let selector = try JSONDecoder().decode(FormsMapSelector.self, from: Data(json.utf8))
        #expect(selector == .single("input#username"))
    }

    /// `init(from:)` decodes a JSON array of strings as `.sequence`.
    @Test
    func formsMapSelector_decodeSequence() throws {
        let json = #"["input[name='otp-0']","input[name='otp-1']"]"#
        let selector = try JSONDecoder().decode(FormsMapSelector.self, from: Data(json.utf8))
        #expect(selector == .sequence(["input[name='otp-0']", "input[name='otp-1']"]))
    }
}
