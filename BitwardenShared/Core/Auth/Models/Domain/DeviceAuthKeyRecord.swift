import Foundation

/// Stored key material needed to assert the device auth key passkey.
struct DeviceAuthKeyRecord: Codable {
    let cipherId: String
    let cipherName: String
    let credentialId: String
    let keyType: String
    let keyAlgorithm: String
    let keyCurve: String
    let keyValue: String
    let rpId: String
    let rpName: String?
    let userId: String?
    let userName: String?
    let userDisplayName: String?
    let counter: String
    let discoverable: String
    let hmacSecret: String?
    let creationDate: Date
}
