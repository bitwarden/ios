import Foundation
import TestHelpers

// swiftlint:disable missing_docs

public extension APITestData {
    // MARK: Known Device

    static let knownDeviceTrue = APITestData(data: Data("true".utf8))
    static let knownDeviceFalse = APITestData(data: Data("false".utf8))

    // MARK: Current Device

    static let currentDevice = APITestData(data: Data(
        """
        {
            "id": "device-id-1",
            "name": "iPhone 15 Pro",
            "identifier": "device-identifier-1",
            "type": 1,
            "creationDate": "2024-01-01T00:00:00.000Z",
            "isTrusted": true,
            "lastActivityDate": "2024-06-15T10:30:00.000Z"
        }
        """.utf8,
    ))

    // MARK: Devices List

    static let devicesList = APITestData(data: Data(
        """
        {
            "data": [
                {
                    "id": "device-id-1",
                    "name": "iPhone 15 Pro",
                    "identifier": "device-identifier-1",
                    "type": 1,
                    "creationDate": "2024-01-01T00:00:00.000Z",
                    "isTrusted": true,
                    "lastActivityDate": "2024-06-15T10:30:00.000Z"
                },
                {
                    "id": "device-id-2",
                    "name": "Chrome Extension",
                    "identifier": "device-identifier-2",
                    "type": 2,
                    "creationDate": "2024-02-01T00:00:00.000Z",
                    "isTrusted": false,
                    "lastActivityDate": null
                }
            ]
        }
        """.utf8,
    ))
}

// swiftlint:enable missing_docs
