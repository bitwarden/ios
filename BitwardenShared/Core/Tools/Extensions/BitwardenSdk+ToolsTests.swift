// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BitwardenSdkToolsTests

class BitwardenSdkToolsTests: BitwardenTestCase {
    // MARK: Tests

    /// `Send(sendResponseModel:)` maps the response's item data into the SDK send.
    func test_send_init_sendResponseModel_data() throws {
        let cipher = Cipher.fixture(id: "CIPHER_ID")
        let cipherResponseModel = try CipherDetailsResponseModel(cipher: cipher)
        let cipherJSON = try JSONEncoder.defaultEncoder.encode(cipherResponseModel)
        let model = SendResponseModel.fixture(
            data: SendDataModel(data: String(data: cipherJSON, encoding: .utf8)),
        )

        let send = try Send(sendResponseModel: model)

        XCTAssertEqual(send.data, SendItem(encryptionVersion: .v1, data: cipher))
    }

    /// `Send(sendResponseModel:)` maps a missing item data to `nil`.
    func test_send_init_sendResponseModel_noData() throws {
        let model = SendResponseModel.fixture(data: nil)

        let send = try Send(sendResponseModel: model)

        XCTAssertNil(send.data)
    }

    /// `Send(sendResponseModel:)` throws if the item data can't be decoded.
    func test_send_init_sendResponseModel_invalidData() {
        let model = SendResponseModel.fixture(data: SendDataModel(data: "not valid json"))

        XCTAssertThrowsError(try Send(sendResponseModel: model))
    }

    /// `SendResponseModel(send:)` and `Send(sendResponseModel:)` keep the send's item data
    /// through a round trip.
    func test_sendResponseModel_roundTrip_data() throws {
        let send = Send.fixture(data: SendItem(encryptionVersion: .v1, data: Cipher.fixture(id: "CIPHER_ID")))

        let model = try SendResponseModel(send: send)
        let encoded = try JSONEncoder.defaultEncoder.encode(model)
        let decoded = try SendResponseModel.decoder.decode(SendResponseModel.self, from: encoded)

        XCTAssertEqual(try Send(sendResponseModel: decoded), send)
    }
}
