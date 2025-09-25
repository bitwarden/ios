// swiftlint:disable:this file_name

import BitwardenSdk

extension BitwardenSdk.InitUserCryptoMethod {
    /// A safe string representation of the crypto method that excludes sensitive associated values.
    var methodType: String {
        switch self {
        case .authRequest:
            return "authRequest"
        case .password:
            return "password"
        case .decryptedKey:
            return "decryptedKey"
        case .deviceKey:
            return "deviceKey"
        case .keyConnector:
            return "keyConnector"
        case .pin:
            return "pin"
        case .pinEnvelope:
            return "pinEnvelope"
        }
    }
}
