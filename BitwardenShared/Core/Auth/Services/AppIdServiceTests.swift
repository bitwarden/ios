import XCTest

@testable import BitwardenShared

class AppIdServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var subject: AppIdService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()

        subject = AppIdService(appSettingStore: appSettingsStore)
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        subject = nil
    }

    // MARK: Tests

    /// `getOrCreateAppId()` sets the initial app ID if one isn't already set.
    func test_getOrCreateAppId_createsInitialId() async {
        let initialId = await subject.getOrCreateAppId()
        XCTAssertEqual(initialId.count, 36)
        XCTAssertEqual(initialId, appSettingsStore.appId)
    }

    /// `getOrCreateAppId()` returns the app ID from the store once one has already been set.
    func test_getOrCreateAppId_returnsExistingId() async {
        appSettingsStore.appId = "📱"

        let appId = await subject.getOrCreateAppId()
        XCTAssertEqual(appId, "📱")
    }
}
