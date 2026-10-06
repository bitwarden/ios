// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BitwardenSdkToolsTests

struct BitwardenSdkToolsTests {
    // MARK: Tests

    /// `Send(sendResponseModel:)` maps the response's item data into the SDK send.
    @Test
    func send_init_sendResponseModel_data() throws {
        let model = try SendResponseModel.fixture(data: SendDataModel(data: cipherJSON(), encryptionVersion: 1))

        let send = try Send(sendResponseModel: model)

        #expect(send.data == SendItem(encryptionVersion: .v1, data: Cipher.fixture(id: "CIPHER_ID")))
    }

    /// `Send(sendResponseModel:)` throws if the item data can't be decoded.
    @Test
    func send_init_sendResponseModel_invalidData() {
        let model = SendResponseModel.fixture(data: SendDataModel(data: "not valid json", encryptionVersion: 1))

        #expect(throws: (any Error).self) {
            try Send(sendResponseModel: model)
        }
    }

    /// `Send(sendResponseModel:)` maps a missing item data to `nil`.
    @Test
    func send_init_sendResponseModel_noData() throws {
        let model = SendResponseModel.fixture(data: nil)

        let send = try Send(sendResponseModel: model)

        #expect(send.data == nil)
    }

    /// `Send(sendResponseModel:)` throws if the item data has an unknown encryption version.
    @Test
    func send_init_sendResponseModel_unknownEncryptionVersion() throws {
        let model = try SendResponseModel.fixture(data: SendDataModel(data: cipherJSON(), encryptionVersion: 2))

        #expect(throws: DataMappingError.invalidData) {
            try Send(sendResponseModel: model)
        }
    }

    /// `SendDataModel(sendItem:)` encodes the item's cipher and encryption version.
    @Test
    func sendDataModel_init_sendItem() throws {
        let sendItem = SendItem(encryptionVersion: .v1, data: Cipher.fixture(id: "CIPHER_ID"))

        let model = try SendDataModel(sendItem: sendItem)

        #expect(model.data != nil)
        #expect(model.encryptionVersion == 1)
    }

    /// `SendItem(sendDataModel:)` defaults to v1 if the encryption version is missing.
    @Test
    func sendItem_init_sendDataModel_missingEncryptionVersion() throws {
        let model = try SendDataModel(data: cipherJSON(), encryptionVersion: nil)

        let sendItem = try SendItem(sendDataModel: model)

        #expect(sendItem == SendItem(encryptionVersion: .v1, data: Cipher.fixture(id: "CIPHER_ID")))
    }

    /// `SendItem(sendDataModel:)` throws if the encryption version is outside the SDK's raw value range.
    @Test(arguments: [-1, 300])
    func sendItem_init_sendDataModel_outOfRangeEncryptionVersion(encryptionVersion: Int) throws {
        let model = try SendDataModel(data: cipherJSON(), encryptionVersion: encryptionVersion)

        #expect(throws: DataMappingError.invalidData) {
            try SendItem(sendDataModel: model)
        }
    }

    /// `SendItem(sendDataModel:)` throws if the encryption version is unknown.
    @Test
    func sendItem_init_sendDataModel_unknownEncryptionVersion() throws {
        let model = try SendDataModel(data: cipherJSON(), encryptionVersion: 2)

        #expect(throws: DataMappingError.invalidData) {
            try SendItem(sendDataModel: model)
        }
    }

    /// `SendItem(sendDataModel:)` maps a v1 encryption version and the item's cipher.
    @Test
    func sendItem_init_sendDataModel_v1EncryptionVersion() throws {
        let model = try SendDataModel(data: cipherJSON(), encryptionVersion: 1)

        let sendItem = try SendItem(sendDataModel: model)

        #expect(sendItem == SendItem(encryptionVersion: .v1, data: Cipher.fixture(id: "CIPHER_ID")))
    }

    /// `SendResponseModel(send:)` and `Send(sendResponseModel:)` keep the send's item data
    /// through a round trip.
    @Test
    func sendResponseModel_roundTrip_data() throws {
        let send = Send.fixture(data: SendItem(encryptionVersion: .v1, data: Cipher.fixture(id: "CIPHER_ID")))

        let model = try SendResponseModel(send: send)
        let encoded = try JSONEncoder.defaultEncoder.encode(model)
        let decoded = try SendResponseModel.decoder.decode(SendResponseModel.self, from: encoded)

        #expect(try Send(sendResponseModel: decoded) == send)
    }

    // MARK: Private

    /// Returns a cipher fixture encoded as the JSON string the API stores in an item send.
    private func cipherJSON() throws -> String? {
        let cipherResponseModel = try CipherDetailsResponseModel(cipher: Cipher.fixture(id: "CIPHER_ID"))
        let data = try JSONEncoder.defaultEncoder.encode(cipherResponseModel)
        return String(data: data, encoding: .utf8)
    }
}
