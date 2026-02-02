import Foundation

// MARK: - DeviceAuthKeyMetadata

/// Metadata needed for matching a request to the device passkey before decrypting the secret data.
struct DeviceAuthKeyMetadata: Codable {
    let credentialId: Data
    let cipherId: String
    let rpId: String
    let userName: String
    let userHandle: Data
}
