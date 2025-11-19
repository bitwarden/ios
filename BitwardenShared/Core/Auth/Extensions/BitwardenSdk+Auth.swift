// swiftlint:disable:this file_name

import BitwardenSdk

extension BitwardenSdk.InitUserCryptoMethod {
    /// A safe string representation of the crypto method that excludes sensitive associated values.
    var methodType: String {
        switch self {
        case .authRequest:
            "Auth Request"
        case .decryptedKey:
            "Decrypted Key (Never Lock/Biometrics)"
        case .deviceKey:
            "Device Key"
        case .keyConnector:
            "Key Connector"
        case .masterPasswordUnlock:
            "Master Password Unlock"
        case .password:
            "Password"
        case .pin:
            "PIN"
        case .pinEnvelope:
            "PIN Envelope"
        }
    }
}

extension BitwardenSdk.MasterPasswordUnlockData {
    init(responseModel model: MasterPasswordUnlockResponseModel) {
        self.init(
            kdf: model.kdf.sdkKdf,
            masterKeyWrappedUserKey: model.masterKeyEncryptedUserKey,
            salt: model.salt,
        )
    }
}
