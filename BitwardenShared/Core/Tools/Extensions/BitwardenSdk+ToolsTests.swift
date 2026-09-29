// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - BitwardenSdkToolsTests

class BitwardenSdkToolsTests: BitwardenTestCase {
    // MARK: Properties

    /// An item send's cipher, encoded by the SDK as JSON.
    let cipherJSON = """
    {
      "id": "CIPHER_ID",
      "organizationId": null,
      "folderId": null,
      "collectionIds": [],
      "key": null,
      "name": "encrypted name",
      "notes": "encrypted notes",
      "type": 2,
      "login": null,
      "identity": null,
      "card": null,
      "secureNote": { "type": 0 },
      "sshKey": null,
      "bankAccount": null,
      "driversLicense": null,
      "passport": null,
      "favorite": false,
      "reprompt": 0,
      "organizationUseTotp": false,
      "edit": true,
      "permissions": null,
      "viewPassword": true,
      "localData": null,
      "attachments": null,
      "fields": null,
      "passwordHistory": null,
      "creationDate": "2023-11-05T09:41:00Z",
      "deletedDate": null,
      "revisionDate": "2023-11-05T09:41:00Z",
      "archivedDate": null,
      "data": null
    }
    """

    // MARK: Tests

    /// `Send(sendResponseModel:)` maps the response's item data into the SDK send.
    func test_send_init_sendResponseModel_data() throws {
        let json: [String: Any] = [
            "accessCount": 0,
            "accessId": "ACCESS_ID",
            "deletionDate": "2024-01-01T00:00:00Z",
            "disabled": false,
            "hideEmail": false,
            "id": "SEND_ID",
            "key": "KEY",
            "name": "encrypted name",
            "revisionDate": "2024-01-01T00:00:00Z",
            "type": 0,
            "data": [
                "data": cipherJSON,
                "encryptionVersion": 1,
            ],
        ]
        let model = try SendResponseModel.decoder.decode(
            SendResponseModel.self,
            from: JSONSerialization.data(withJSONObject: json),
        )

        let send = try Send(sendResponseModel: model)

        XCTAssertEqual(
            send.data,
            SendItem(
                encryptionVersion: .v1,
                data: .fixture(
                    id: "CIPHER_ID",
                    name: "encrypted name",
                    notes: "encrypted notes",
                    secureNote: SecureNote(type: .generic),
                    type: .secureNote,
                ),
            ),
        )
    }

    /// `SendResponseModel(send:)` and `Send(sendResponseModel:)` keep the send's item data
    /// through a round trip.
    func test_sendResponseModel_roundTrip_data() throws {
        let send = Send.fixture(data: SendItem(encryptionVersion: .v1, data: .fixture(id: "CIPHER_ID")))

        let model = try SendResponseModel(send: send)
        let encoded = try JSONEncoder.defaultEncoder.encode(model)
        let decoded = try SendResponseModel.decoder.decode(SendResponseModel.self, from: encoded)

        XCTAssertEqual(try Send(sendResponseModel: decoded), send)
    }
}
