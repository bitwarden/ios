import Combine
import Foundation

@testable import BitwardenShared

class MockAppSettingsStore: AppSettingsStore {
    var appId: String?
    var encryptedPrivateKeys = [String: String]()
    var encryptedUserKeys = [String: String]()
    var lastSyncTimeByUserId = [String: Date]()
    var passwordGenerationOptions = [String: PasswordGenerationOptions]()
    var preAuthEnvironmentUrls: EnvironmentUrlData?
    var rememberedEmail: String?
    var state: State? {
        didSet {
            activeIdSubject.send(state?.activeUserId)
        }
    }

    var usernameGenerationOptions = [String: UsernameGenerationOptions]()

    lazy var activeIdSubject = CurrentValueSubject<String?, Never>(self.state?.activeUserId)

    func encryptedPrivateKey(userId: String) -> String? {
        encryptedPrivateKeys[userId]
    }

    func encryptedUserKey(userId: String) -> String? {
        encryptedUserKeys[userId]
    }

    func lastSyncTime(userId: String) -> Date? {
        lastSyncTimeByUserId[userId]
    }

    func passwordGenerationOptions(userId: String) -> PasswordGenerationOptions? {
        passwordGenerationOptions[userId]
    }

    func usernameGenerationOptions(userId: String) -> UsernameGenerationOptions? {
        usernameGenerationOptions[userId]
    }

    func setEncryptedPrivateKey(key: String?, userId: String) {
        guard let key else {
            encryptedPrivateKeys.removeValue(forKey: userId)
            return
        }
        encryptedPrivateKeys[userId] = key
    }

    func setEncryptedUserKey(key: String?, userId: String) {
        guard let key else {
            encryptedUserKeys.removeValue(forKey: userId)
            return
        }
        encryptedUserKeys[userId] = key
    }

    func setLastSyncTime(_ date: Date?, userId: String) {
        lastSyncTimeByUserId[userId] = date
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String) {
        guard let options else {
            passwordGenerationOptions.removeValue(forKey: userId)
            return
        }
        passwordGenerationOptions[userId] = options
    }

    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String) {
        guard let options else {
            usernameGenerationOptions.removeValue(forKey: userId)
            return
        }
        usernameGenerationOptions[userId] = options
    }

    func activeAccountIdPublisher() -> AsyncPublisher<AnyPublisher<String?, Never>> {
        activeIdSubject
            .eraseToAnyPublisher()
            .values
    }
}
