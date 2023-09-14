import XCTest

@testable import BitwardenShared

class AppSettingsStoreTests: BitwardenTestCase {
    var subject: AppSettingsStore!
    var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: "AppSettingsStoreTests")

        subject = DefaultAppSettingsStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()

        userDefaults.removeObject(forKey: "bwPreferencesStorage:appId")

        subject = nil
        userDefaults = nil
    }

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
}
