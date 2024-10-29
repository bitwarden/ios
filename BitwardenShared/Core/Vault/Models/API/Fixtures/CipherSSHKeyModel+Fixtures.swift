import Foundation

@testable import BitwardenShared

extension CipherSSHKeyModel {
    static func fixture(
        publicKey: String? = "publicKey",
        privateKey: String? = "privateKey",
        keyFingerprint: String? = "keyFingerprint"
    ) -> CipherSSHKeyModel {
        self.init(
            publicKey: publicKey,
            privateKey: privateKey,
            keyFingerprint: keyFingerprint
        )
    }
}
