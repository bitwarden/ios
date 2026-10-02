import BitwardenKit
import Foundation
import Testing

@testable import BitwardenShared

// MARK: - SendDataModelTests

struct SendDataModelTests {
    // MARK: Tests

    /// `init(from:)` defaults to `.v1` instead of throwing when the encryption version has the wrong type.
    @Test
    func decode_encryptionVersion_invalidType() throws {
        let subject = try decode(#"{"data": "DATA", "encryptionVersion": "invalid"}"#)
        #expect(subject.encryptionVersion == .v1)
    }

    /// `init(from:)` defaults to `.v1` when the encryption version is missing.
    @Test
    func decode_encryptionVersion_missing() throws {
        let subject = try decode(#"{"data": "DATA"}"#)
        #expect(subject.encryptionVersion == .v1)
    }

    /// `init(from:)` defaults to `.v1` when the encryption version is `null`.
    @Test
    func decode_encryptionVersion_null() throws {
        let subject = try decode(#"{"data": "DATA", "encryptionVersion": null}"#)
        #expect(subject.encryptionVersion == .v1)
    }

    /// `init(from:)` decodes an unrecognized encryption version to `.unknown` instead of throwing.
    @Test
    func decode_encryptionVersion_unknownValue() throws {
        let subject = try decode(#"{"data": "DATA", "encryptionVersion": 99}"#)
        #expect(subject.encryptionVersion == .unknown)
    }

    /// `init(from:)` decodes a valid encryption version.
    @Test
    func decode_encryptionVersion_valid() throws {
        let subject = try decode(#"{"data": "DATA", "encryptionVersion": 1}"#)
        #expect(subject == SendDataModel(data: "DATA", encryptionVersion: .v1))
    }

    /// `encode(to:)` encodes the encryption version as its raw value.
    @Test
    func encode_encryptionVersion() throws {
        let data = try JSONEncoder().encode(SendDataModel(data: "DATA", encryptionVersion: .v1))
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["encryptionVersion"] as? Int == 1)
    }

    // MARK: Private

    private func decode(_ json: String) throws -> SendDataModel {
        try JSONDecoder.defaultDecoder.decode(SendDataModel.self, from: Data(json.utf8))
    }
}
