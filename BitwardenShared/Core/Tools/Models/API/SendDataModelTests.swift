import Foundation
import Testing

@testable import BitwardenShared

// MARK: - SendDataModelTests

struct SendDataModelTests {
    // MARK: Tests

    /// `init(from:)` throws when the encryption version has the wrong type.
    @Test
    func decode_encryptionVersion_invalidType() {
        #expect(throws: DecodingError.self) {
            try decode(#"{"data": "DATA", "encryptionVersion": "invalid"}"#)
        }
    }

    /// `init(from:)` decodes a missing encryption version as `nil`.
    @Test
    func decode_encryptionVersion_missing() throws {
        let subject = try decode(#"{"data": "DATA"}"#)
        #expect(subject.encryptionVersion == nil)
    }

    /// `init(from:)` decodes a `null` encryption version as `nil`.
    @Test
    func decode_encryptionVersion_null() throws {
        let subject = try decode(#"{"data": "DATA", "encryptionVersion": null}"#)
        #expect(subject.encryptionVersion == nil)
    }

    /// `init(from:)` keeps an unrecognized encryption version as-is, so it can be rejected when
    /// mapping to the SDK.
    @Test
    func decode_encryptionVersion_unknownValue() throws {
        let subject = try decode(#"{"data": "DATA", "encryptionVersion": 99}"#)
        #expect(subject.encryptionVersion == 99)
    }

    /// `init(from:)` decodes a valid encryption version.
    @Test
    func decode_encryptionVersion_valid() throws {
        let subject = try decode(#"{"data": "DATA", "encryptionVersion": 1}"#)
        #expect(subject == SendDataModel(data: "DATA", encryptionVersion: 1))
    }

    /// `encode(to:)` encodes the encryption version.
    @Test
    func encode_encryptionVersion() throws {
        let data = try JSONEncoder().encode(SendDataModel(data: "DATA", encryptionVersion: 1))
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["encryptionVersion"] as? Int == 1)
    }

    // MARK: Private

    private func decode(_ json: String) throws -> SendDataModel {
        try JSONDecoder.defaultDecoder.decode(SendDataModel.self, from: Data(json.utf8))
    }
}
