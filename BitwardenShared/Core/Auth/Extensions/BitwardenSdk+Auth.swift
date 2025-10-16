// swiftlint:disable:this file_name

import BitwardenSdk

extension BitwardenSdk.InitUserCryptoMethod {
    /// A safe string representation of the crypto method that excludes sensitive associated values.
    var methodType: String {
        switch self {
        case .authRequest:
            "Auth Request"
        case .password:
            "Password"
        case .decryptedKey:
            "Decrypted Key (Never Lock/Biometrics)"
        case .deviceKey:
            "Device Key"
        case .keyConnector:
            "Key Connector"
        case .pin:
            "PIN"
        case .pinEnvelope:
            "PIN Envelope"
        }
    }
}
