// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BitwardenSdkToolsTests

struct BitwardenSdkToolsTests {
    // MARK: Properties

    /// The item send used in the tests.
    private var sendItem: SendItem {
        SendItem(encryptionVersion: .v1, data: "SEALED", metadata: SendItemMetadata(itemId: "CIPHER_ID"))
    }

    // MARK: Tests

    /// `Send(sendResponseModel:)` maps the response's item data into the SDK send.
    @Test
    func send_init_sendResponseModel_data() throws {
        let model = SendResponseModel.fixture(data: sendDataModel(encryptionVersion: 1))

        let send = try Send(sendResponseModel: model)

        #expect(send.data == sendItem)
    }

    /// `Send(sendResponseModel:)` throws if the item data has no metadata.
    @Test
    func send_init_sendResponseModel_missingMetadata() {
        let model = SendResponseModel.fixture(data: SendDataModel(data: "SEALED", encryptionVersion: 1))

        #expect(throws: DataMappingError.invalidData) {
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
    func send_init_sendResponseModel_unknownEncryptionVersion() {
        let model = SendResponseModel.fixture(data: sendDataModel(encryptionVersion: 2))

        #expect(throws: DataMappingError.invalidData) {
            try Send(sendResponseModel: model)
        }
    }

    /// `SendDataModel(sendItem:)` keeps the sealed blob, the encryption version and the item ID.
    @Test
    func sendDataModel_init_sendItem() {
        let model = SendDataModel(sendItem: sendItem)

        #expect(model == sendDataModel(encryptionVersion: 1))
    }

    /// `SendItem(sendDataModel:)` defaults to v1 if the encryption version is missing.
    @Test
    func sendItem_init_sendDataModel_missingEncryptionVersion() throws {
        let sendItem = try SendItem(sendDataModel: sendDataModel(encryptionVersion: nil))

        #expect(sendItem == self.sendItem)
    }

    /// `SendItem(sendDataModel:)` throws if the encryption version is outside the SDK's raw value range.
    @Test(arguments: [-1, 300])
    func sendItem_init_sendDataModel_outOfRangeEncryptionVersion(encryptionVersion: Int) {
        #expect(throws: DataMappingError.invalidData) {
            try SendItem(sendDataModel: sendDataModel(encryptionVersion: encryptionVersion))
        }
    }

    /// `SendItem(sendDataModel:)` throws if the encryption version is unknown.
    @Test
    func sendItem_init_sendDataModel_unknownEncryptionVersion() {
        #expect(throws: DataMappingError.invalidData) {
            try SendItem(sendDataModel: sendDataModel(encryptionVersion: 2))
        }
    }

    /// `SendItem(sendDataModel:)` throws if the sealed data is missing.
    @Test
    func sendItem_init_sendDataModel_missingData() {
        let model = SendDataModel(
            data: nil,
            encryptionVersion: 1,
            metadata: SendItemMetadataModel(itemId: "CIPHER_ID"),
        )

        #expect(throws: DataMappingError.invalidData) {
            try SendItem(sendDataModel: model)
        }
    }

    /// `SendItem(sendDataModel:)` maps a v1 encryption version, the sealed blob and the item ID.
    @Test
    func sendItem_init_sendDataModel_v1EncryptionVersion() throws {
        let sendItem = try SendItem(sendDataModel: sendDataModel(encryptionVersion: 1))

        #expect(sendItem == self.sendItem)
    }

    /// `SendResponseModel(send:)` and `Send(sendResponseModel:)` keep the send's item data
    /// through a round trip.
    @Test
    func sendResponseModel_roundTrip_data() throws {
        let send = Send.fixture(data: sendItem)

        let model = try SendResponseModel(send: send)
        let encoded = try JSONEncoder.defaultEncoder.encode(model)
        let decoded = try SendResponseModel.decoder.decode(SendResponseModel.self, from: encoded)

        #expect(try Send(sendResponseModel: decoded) == send)
    }

    // MARK: Private

    /// Returns the API model of the item send used in the tests.
    ///
    /// - Parameter encryptionVersion: The encryption version of the model.
    ///
    private func sendDataModel(encryptionVersion: Int?) -> SendDataModel {
        SendDataModel(
            data: "SEALED",
            encryptionVersion: encryptionVersion,
            metadata: SendItemMetadataModel(itemId: "CIPHER_ID"),
        )
    }
}
