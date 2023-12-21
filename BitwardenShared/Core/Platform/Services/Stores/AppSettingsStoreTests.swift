import XCTest

@testable import BitwardenShared

// MARK: - AppSettingsStoreTests

class AppSettingsStoreTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var subject: AppSettingsStore!
    var userDefaults: UserDefaults!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: "AppSettingsStoreTests")

        userDefaults.dictionaryRepresentation()
            .keys
            .filter { $0.hasPrefix("bwPreferencesStorage:") }
            .forEach { key in
                userDefaults.removeObject(forKey: key)
            }

        subject = DefaultAppSettingsStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
        userDefaults = nil
    }

    // MARK: Tests

    /// `appId` returns `nil` if there isn't a previously stored value.
    func test_appId_isInitiallyNil() {
        XCTAssertNil(subject.appId)
    }

    /// `appId` can be used to get and set the persisted value in user defaults.
    func test_appId_withValue() {
        subject.appId = "📱"
        XCTAssertEqual(subject.appId, "📱")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:appId"), "📱")

        subject.appId = "☎️"
        XCTAssertEqual(subject.appId, "☎️")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:appId"), "☎️")

        subject.appId = nil
        XCTAssertNil(subject.appId)
        XCTAssertNil(userDefaults.string(forKey: "bwPreferencesStorage:appId"))
    }

    /// `encryptedPrivateKey(userId:)` returns `nil` if there isn't a previously stored value.
    func test_encryptedPrivateKey_isInitiallyNil() {
        XCTAssertNil(subject.encryptedPrivateKey(userId: "-1"))
    }

    /// `encryptedPrivateKey(userId:)` can be used to get the encrypted private key for a user.
    func test_encryptedPrivateKey_withValue() {
        subject.setEncryptedPrivateKey(key: "1:PRIVATE_KEY", userId: "1")
        subject.setEncryptedPrivateKey(key: "2:PRIVATE_KEY", userId: "2")

        XCTAssertEqual(subject.encryptedPrivateKey(userId: "1"), "1:PRIVATE_KEY")
        XCTAssertEqual(subject.encryptedPrivateKey(userId: "2"), "2:PRIVATE_KEY")
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:encPrivateKey_1"),
            "1:PRIVATE_KEY"
        )
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:encPrivateKey_2"),
            "2:PRIVATE_KEY"
        )

        subject.setEncryptedPrivateKey(key: "1:PRIVATE_KEY_NEW", userId: "1")
        subject.setEncryptedPrivateKey(key: "2:PRIVATE_KEY_NEW", userId: "2")

        XCTAssertEqual(subject.encryptedPrivateKey(userId: "1"), "1:PRIVATE_KEY_NEW")
        XCTAssertEqual(subject.encryptedPrivateKey(userId: "2"), "2:PRIVATE_KEY_NEW")
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:encPrivateKey_1"),
            "1:PRIVATE_KEY_NEW"
        )
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:encPrivateKey_2"),
            "2:PRIVATE_KEY_NEW"
        )
    }

    /// `encryptedUserKey(userId:)` returns `nil` if there isn't a previously stored value.
    func test_encryptedUserKey_isInitiallyNil() {
        XCTAssertNil(subject.encryptedUserKey(userId: "-1"))
    }

    /// `encryptedUserKey(userId:)` can be used to get the encrypted user key for a user.
    func test_encryptedUserKey_withValue() {
        subject.setEncryptedUserKey(key: "1:USER_KEY", userId: "1")
        subject.setEncryptedUserKey(key: "2:USER_KEY", userId: "2")

        XCTAssertEqual(subject.encryptedUserKey(userId: "1"), "1:USER_KEY")
        XCTAssertEqual(subject.encryptedUserKey(userId: "2"), "2:USER_KEY")
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:masterKeyEncryptedUserKey_1"),
            "1:USER_KEY"
        )
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:masterKeyEncryptedUserKey_2"),
            "2:USER_KEY"
        )

        subject.setEncryptedUserKey(key: "1:USER_KEY_NEW", userId: "1")
        subject.setEncryptedUserKey(key: "2:USER_KEY_NEW", userId: "2")

        XCTAssertEqual(subject.encryptedUserKey(userId: "1"), "1:USER_KEY_NEW")
        XCTAssertEqual(subject.encryptedUserKey(userId: "2"), "2:USER_KEY_NEW")
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:masterKeyEncryptedUserKey_1"),
            "1:USER_KEY_NEW"
        )
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:masterKeyEncryptedUserKey_2"),
            "2:USER_KEY_NEW"
        )
    }

    /// `lastSyncTime(userId:)` returns `nil` if there isn't a previously stored value.
    func test_lastSyncTime_isInitiallyNil() {
        XCTAssertNil(subject.lastSyncTime(userId: "-1"))
    }

    /// `lastSyncTime(userId:)` can be used to get the last sync time for a user.
    func test_lastSyncTime_withValue() {
        let date1 = Date(year: 2023, month: 12, day: 1)
        let date2 = Date(year: 2023, month: 10, day: 2)

        subject.setLastSyncTime(date1, userId: "1")
        subject.setLastSyncTime(date2, userId: "2")

        XCTAssertEqual(subject.lastSyncTime(userId: "1"), date1)
        XCTAssertEqual(subject.lastSyncTime(userId: "2"), date2)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:lastSync_1"), 1_701_388_800.0)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:lastSync_2"), 1_696_204_800.0)

        let date3 = Date(year: 2023, month: 8, day: 1)
        let date4 = Date(year: 2023, month: 6, day: 2)

        subject.setLastSyncTime(date3, userId: "1")
        subject.setLastSyncTime(date4, userId: "2")

        XCTAssertEqual(subject.lastSyncTime(userId: "1"), date3)
        XCTAssertEqual(subject.lastSyncTime(userId: "2"), date4)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:lastSync_1"), 1_690_848_000.0)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:lastSync_2"), 1_685_664_000.0)
    }

    /// `masterPasswordHash(userId:)` returns `nil` if there isn't a previously stored value.
    func test_masterPasswordHash_isInitiallyNil() {
        XCTAssertNil(subject.masterPasswordHash(userId: "-1"))
    }

    /// `masterPasswordHash(userId:)` can be used to get the master password hash for a user.
    func test_masterPasswordHash_withValue() {
        subject.setMasterPasswordHash("1234", userId: "1")
        subject.setMasterPasswordHash("9876", userId: "2")

        XCTAssertEqual(subject.masterPasswordHash(userId: "1"), "1234")
        XCTAssertEqual(subject.masterPasswordHash(userId: "2"), "9876")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:keyHash_1"), "1234")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:keyHash_2"), "9876")

        subject.setMasterPasswordHash("abcd", userId: "1")
        subject.setMasterPasswordHash("zyxw", userId: "2")

        XCTAssertEqual(subject.masterPasswordHash(userId: "1"), "abcd")
        XCTAssertEqual(subject.masterPasswordHash(userId: "2"), "zyxw")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:keyHash_1"), "abcd")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:keyHash_2"), "zyxw")
    }

    /// `passwordGenerationOptions(userId:)` returns `nil` if there isn't a previously stored value.
    func test_passwordGenerationOptions_isInitiallyNil() {
        XCTAssertNil(subject.passwordGenerationOptions(userId: "-1"))
    }

    /// `passwordGenerationOptions(userId:)` can be used to get the password generation options for a user.
    func test_passwordGenerationOptions_withValue() {
        let options1 = PasswordGenerationOptions(length: 30, lowercase: true, type: .password, uppercase: true)
        let options2 = PasswordGenerationOptions(numWords: 5, type: .passphrase, wordSeparator: "-")

        subject.setPasswordGenerationOptions(options1, userId: "1")
        subject.setPasswordGenerationOptions(options2, userId: "2")

        try XCTAssertEqual(
            JSONDecoder().decode(
                PasswordGenerationOptions.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:passwordGenerationOptions_1")?
                        .data(using: .utf8)
                )
            ),
            options1
        )
        try XCTAssertEqual(
            JSONDecoder().decode(
                PasswordGenerationOptions.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:passwordGenerationOptions_2")?
                        .data(using: .utf8)
                )
            ),
            options2
        )

        XCTAssertEqual(subject.passwordGenerationOptions(userId: "1"), options1)
        XCTAssertEqual(subject.passwordGenerationOptions(userId: "2"), options2)
    }

    /// `preAuthEnvironmentUrls` returns `nil` if there isn't a previously stored value.
    func test_preAuthEnvironmentUrls_isInitiallyNil() {
        XCTAssertNil(subject.preAuthEnvironmentUrls)
    }

    /// `preAuthEnvironmentUrls` can be used to get and set the persisted value in user defaults.
    func test_preAuthEnvironmentUrls_withValue() {
        subject.preAuthEnvironmentUrls = .defaultUS
        XCTAssertEqual(subject.preAuthEnvironmentUrls, .defaultUS)
        try XCTAssertEqual(
            JSONDecoder().decode(
                EnvironmentUrlData.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:preAuthEnvironmentUrls")?
                        .data(using: .utf8)
                )
            ),
            .defaultUS
        )

        subject.preAuthEnvironmentUrls = .defaultEU
        XCTAssertEqual(subject.preAuthEnvironmentUrls, .defaultEU)
        try XCTAssertEqual(
            JSONDecoder().decode(
                EnvironmentUrlData.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:preAuthEnvironmentUrls")?
                        .data(using: .utf8)
                )
            ),
            .defaultEU
        )
    }

    /// `usernameGenerationOptions(userId:)` returns `nil` if there isn't a previously stored value.
    func test_usernameGenerationOptions_isInitiallyNil() {
        XCTAssertNil(subject.usernameGenerationOptions(userId: "-1"))
    }

    /// `usernameGenerationOptions(userId:)` can be used to get the username generation options for a user.
    func test_usernameGenerationOptions_withValue() {
        let options1 = UsernameGenerationOptions(plusAddressedEmail: "user@bitwarden.com")
        let options2 = UsernameGenerationOptions(catchAllEmailDomain: "bitwarden.com")

        subject.setUsernameGenerationOptions(options1, userId: "1")
        subject.setUsernameGenerationOptions(options2, userId: "2")

        try XCTAssertEqual(
            JSONDecoder().decode(
                UsernameGenerationOptions.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:usernameGenerationOptions_1")?
                        .data(using: .utf8)
                )
            ),
            options1
        )
        try XCTAssertEqual(
            JSONDecoder().decode(
                UsernameGenerationOptions.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:usernameGenerationOptions_2")?
                        .data(using: .utf8)
                )
            ),
            options2
        )

        XCTAssertEqual(subject.usernameGenerationOptions(userId: "1"), options1)
        XCTAssertEqual(subject.usernameGenerationOptions(userId: "2"), options2)
    }

    /// `rememberedEmail` returns `nil` if there isn't a previously stored value.
    func test_rememberedEmail_isInitiallyNil() {
        XCTAssertNil(subject.rememberedEmail)
    }

    /// `rememberedEmail` can be used to get and set the persisted value in user defaults.
    func test_rememberedEmail_withValue() {
        subject.rememberedEmail = "email@example.com"
        XCTAssertEqual(subject.rememberedEmail, "email@example.com")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:rememberedEmail"), "email@example.com")

        subject.rememberedEmail = nil
        XCTAssertNil(subject.rememberedEmail)
        XCTAssertNil(userDefaults.string(forKey: "bwPreferencesStorage:rememberedEmail"))
    }

    /// `state` returns `nil` if there isn't a previously stored value.
    func test_state_isInitiallyNil() {
        XCTAssertNil(subject.state)
    }

    /// `state` can be used to get and set the persisted value in user defaults.
    func test_state_withValue() throws {
        subject.state = State.fixture()
        XCTAssertEqual(subject.state, .fixture())
        XCTAssertEqual(
            try JSONDecoder().decode(
                State.self,
                from: Data(XCTUnwrap(userDefaults.string(forKey: "bwPreferencesStorage:state")).utf8)
            ),
            .fixture()
        )

        let stateMultipleAccounts = State.fixture(
            accounts: ["1": .fixture(), "2": .fixture()])
        subject.state = stateMultipleAccounts
        XCTAssertEqual(subject.state, stateMultipleAccounts)
        XCTAssertEqual(
            try JSONDecoder().decode(
                State.self,
                from: Data(XCTUnwrap(userDefaults.string(forKey: "bwPreferencesStorage:state")).utf8)
            ),
            stateMultipleAccounts
        )

        subject.state = nil
        XCTAssertNil(subject.state)
        XCTAssertNil(userDefaults.data(forKey: "bwPreferencesStorage:state"))
    }
}
