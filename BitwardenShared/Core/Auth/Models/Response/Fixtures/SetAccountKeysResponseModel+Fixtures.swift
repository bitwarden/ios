@testable import BitwardenShared

extension SetAccountKeysResponseModel {
    static func fixture(
        accountKeys: PrivateKeysResponseModel? = nil,
        key: String? = nil,
        privateKey: String? = "PRIVATE_KEY",
        publicKey: String? = "PUBLIC_KEY",
    ) -> SetAccountKeysResponseModel {
        self.init(
            accountKeys: accountKeys,
            key: key,
            privateKey: privateKey,
            publicKey: publicKey,
        )
    }
}
