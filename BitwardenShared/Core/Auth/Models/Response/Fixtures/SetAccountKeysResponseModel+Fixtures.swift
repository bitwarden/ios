@testable import BitwardenShared

extension SetAccountKeysResponseModel {
    static func fixture(
        accountKeys: PrivateKeysResponseModel? = nil,
        privateKey: String? = "PRIVATE_KEY",
        publicKey: String? = "PUBLIC_KEY",
    ) -> SetAccountKeysResponseModel {
        self.init(
            accountKeys: accountKeys,
            privateKey: privateKey,
            publicKey: publicKey,
        )
    }
}
