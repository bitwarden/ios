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

        subject = DefaultAppSettingsStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()

        userDefaults.removeObject(forKey: "bwPreferencesStorage:appId")
        userDefaults.removeObject(forKey: "bwPreferencesStorage:rememberedEmail")

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

    func test_rememberedEmail_isInitiallyNil() {
        XCTAssertNil(subject.rememberedEmail)
    }

    func test_rememberedEmail_withValue() {
        subject.rememberedEmail = "email@example.com"
        XCTAssertEqual(subject.rememberedEmail, "email@example.com")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:rememberedEmail"), "email@example.com")

        subject.rememberedEmail = nil
        XCTAssertNil(subject.rememberedEmail)
        XCTAssertNil(userDefaults.string(forKey: "bwPreferencesStorage:rememberedEmail"))
    }
}
