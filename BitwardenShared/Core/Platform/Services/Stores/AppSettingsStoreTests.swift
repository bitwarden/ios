import XCTest

@testable import BitwardenShared

class AppSettingsStoreTests: BitwardenTestCase {
    var subject: AppSettingsStore!
    var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: "AppSettingsStoreTests")

        for key in DefaultAppSettingsStore.Keys.allCases {
            userDefaults.removeObject(forKey: key.storageKey)
        }

        subject = DefaultAppSettingsStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()

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
