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
        let cipher = Cipher.fixture(id: "CIPHER_ID")
        let cipherResponseModel = try CipherDetailsResponseModel(cipher: cipher)
        let cipherJSON = try JSONEncoder.defaultEncoder.encode(cipherResponseModel)
        let model = SendResponseModel.fixture(
            data: SendDataModel(data: String(data: cipherJSON, encoding: .utf8), encryptionVersion: .v1),
        )

        let send = try Send(sendResponseModel: model)

        #expect(send.data == SendItem(encryptionVersion: .v1, data: cipher))
    }

    /// `Send(sendResponseModel:)` throws if the item data can't be decoded.
    @Test
    func send_init_sendResponseModel_invalidData() {
        let model = SendResponseModel.fixture(data: SendDataModel(data: "not valid json", encryptionVersion: .v1))

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
        let cipherResponseModel = try CipherDetailsResponseModel(cipher: Cipher.fixture(id: "CIPHER_ID"))
        let cipherJSON = try JSONEncoder.defaultEncoder.encode(cipherResponseModel)
        let model = SendResponseModel.fixture(
            data: SendDataModel(data: String(data: cipherJSON, encoding: .utf8), encryptionVersion: .unknown),
        )

        #expect(throws: DataMappingError.invalidData) {
            try Send(sendResponseModel: model)
        }
    }

    /// `SendItem(sendDataModel:)` throws if the encryption version is unknown.
    @Test
    func sendItem_init_sendDataModel_unknownEncryptionVersion() throws {
        let cipherResponseModel = try CipherDetailsResponseModel(cipher: Cipher.fixture(id: "CIPHER_ID"))
        let cipherJSON = try JSONEncoder.defaultEncoder.encode(cipherResponseModel)
        let model = SendDataModel(data: String(data: cipherJSON, encoding: .utf8), encryptionVersion: .unknown)

        #expect(throws: DataMappingError.invalidData) {
            try SendItem(sendDataModel: model)
        }
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
}
