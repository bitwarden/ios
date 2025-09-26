// swiftlint:disable:this file_name

import BitwardenSdk

extension BitwardenSdk.InitUserCryptoMethod {
    /// A safe string representation of the crypto method that excludes sensitive associated values.
    var methodType: String {
        switch self {
        case .authRequest:
            return "Auth Request"
        case .password:
            return "Password"
        case .decryptedKey:
            return "Decrypted Key (Never Lock/Biometrics)"
        case .deviceKey:
            return "Device Key"
        case .keyConnector:
            return "Key Connector"
        case .pin:
            return "PIN"
        case .pinEnvelope:
            return "PIN Envelope"
        }
    }
}
