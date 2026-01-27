/// Metadata needed for matching a request to the device passkey before decrypting the secret data.
struct DeviceAuthKeyMetadata: Decodable, Encodable {
    let credentialId: String
    let cipherId: String
    let rpId: String
    let userName: String
    let userHandle: String
}
