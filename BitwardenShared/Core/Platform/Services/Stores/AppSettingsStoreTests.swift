import XCTest

@testable import BitwardenShared

// MARK: - AppSettingsStoreTests

class AppSettingsStoreTests: BitwardenTestCase {
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
