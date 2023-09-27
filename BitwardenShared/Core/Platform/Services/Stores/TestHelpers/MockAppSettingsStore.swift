@testable import BitwardenShared

class MockAppSettingsStore: AppSettingsStore {
    var appId: String?
    var encryptedPrivateKeys = [String: String]()
    var encryptedUserKeys = [String: String]()
    var rememberedEmail: String?
    var state: State?

    func encryptedPrivateKey(userId: String) -> String? {
        encryptedPrivateKeys[userId]
    }

    func encryptedUserKey(userId: String) -> String? {
        encryptedUserKeys[userId]
    }

    func setEncryptedPrivateKey(key: String, userId: String) {
        encryptedPrivateKeys[userId] = key
    }

    func setEncryptedUserKey(key: String, userId: String) {
        encryptedUserKeys[userId] = key
    }
}
