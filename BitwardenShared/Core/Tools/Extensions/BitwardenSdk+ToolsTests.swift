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

    /// The opaque sealed cipher blob the API stores for an item send.
    let sealedBlob = "SEALED_CIPHER_BLOB"

    // MARK: Tests

    /// `Send(sendResponseModel:)` maps the response's item data into the SDK send.
    @Test
    func send_init_sendResponseModel_data() throws {
        let model = SendResponseModel.fixture(data: SendDataModel(data: sealedBlob, encryptionVersion: 1))

        let send = try Send(sendResponseModel: model)

        #expect(send.data == .fixture(data: sealedBlob, itemId: ""))
    }

    /// `Send(sendResponseModel:)` throws if the item data is missing.
    @Test
    func send_init_sendResponseModel_invalidData() {
        let model = SendResponseModel.fixture(data: SendDataModel(data: nil, encryptionVersion: 1))

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
    func send_init_sendResponseModel_unknownEncryptionVersion() throws {
        let model = SendResponseModel.fixture(data: SendDataModel(data: sealedBlob, encryptionVersion: 2))

        #expect(throws: DataMappingError.invalidData) {
            try Send(sendResponseModel: model)
        }
    }

    /// `SendDataModel(sendItem:)` carries over the item's sealed blob and encryption version.
    @Test
    func sendDataModel_init_sendItem() throws {
        let sendItem = SendItem.fixture(data: sealedBlob)

        let model = try SendDataModel(sendItem: sendItem)

        #expect(model.data == sealedBlob)
        #expect(model.encryptionVersion == 1)
    }

    /// `SendItem(sendDataModel:)` defaults to v1 if the encryption version is missing.
    @Test
    func sendItem_init_sendDataModel_missingEncryptionVersion() throws {
        let model = SendDataModel(data: sealedBlob, encryptionVersion: nil)

        let sendItem = try SendItem(sendDataModel: model)

        #expect(sendItem == .fixture(data: sealedBlob, itemId: ""))
    }

    /// `SendItem(sendDataModel:)` throws if the encryption version is outside the SDK's raw value range.
    @Test(arguments: [-1, 300])
    func sendItem_init_sendDataModel_outOfRangeEncryptionVersion(encryptionVersion: Int) throws {
        let model = SendDataModel(data: sealedBlob, encryptionVersion: encryptionVersion)

        #expect(throws: DataMappingError.invalidData) {
            try SendItem(sendDataModel: model)
        }
    }

    /// `SendItem(sendDataModel:)` throws if the encryption version is unknown.
    @Test
    func sendItem_init_sendDataModel_unknownEncryptionVersion() throws {
        let model = SendDataModel(data: sealedBlob, encryptionVersion: 2)

        #expect(throws: DataMappingError.invalidData) {
            try SendItem(sendDataModel: model)
        }
    }

    /// `SendItem(sendDataModel:)` maps a v1 encryption version and the item's sealed blob.
    @Test
    func sendItem_init_sendDataModel_v1EncryptionVersion() throws {
        let model = SendDataModel(data: sealedBlob, encryptionVersion: 1)

        let sendItem = try SendItem(sendDataModel: model)

        #expect(sendItem == .fixture(data: sealedBlob, itemId: ""))
    }

    /// `SendResponseModel(send:)` and `Send(sendResponseModel:)` keep the send's item data
    /// through a round trip. The item ID in the send item's metadata has no counterpart on the
    /// API model yet (PM-41094), so it isn't preserved.
    @Test
    func sendResponseModel_roundTrip_data() throws {
        let send = Send.fixture(data: .fixture(data: sealedBlob, itemId: "CIPHER_ID"))

        let model = try SendResponseModel(send: send)
        let encoded = try JSONEncoder.defaultEncoder.encode(model)
        let decoded = try SendResponseModel.decoder.decode(SendResponseModel.self, from: encoded)

        #expect(try Send(sendResponseModel: decoded) == Send.fixture(data: .fixture(data: sealedBlob, itemId: "")))
    }
}
