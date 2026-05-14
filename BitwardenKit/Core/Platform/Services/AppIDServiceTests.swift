import BitwardenKit
import BitwardenKitMocks
import XCTest

class AppIDServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appIDSettingsStore: MockAppIDSettingsStore!
    var subject: AppIDService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appIDSettingsStore = MockAppIDSettingsStore()

        subject = AppIDService(appIDSettingsStore: appIDSettingsStore)
    }

    override func tearDown() {
        super.tearDown()

        appIDSettingsStore = nil
        subject = nil
    }

    // MARK: Tests

    /// `getOrCreateAppID()` sets the initial app ID if one isn't already set.
    func test_getOrCreateAppID_createsInitialID() async {
        let initialID = await subject.getOrCreateAppID()
        XCTAssertEqual(initialID.count, 36)
        XCTAssertEqual(initialID, appIDSettingsStore.appID)
    }

    /// `getOrCreateAppID()` returns the app ID from the store once one has already been set.
    func test_getOrCreateAppID_returnsExistingID() async {
        appIDSettingsStore.appID = "📱"

        let appID = await subject.getOrCreateAppID()
        XCTAssertEqual(appID, "📱")
    }
}
