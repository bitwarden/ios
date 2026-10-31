import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import AuthenticatorShared

class StateServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var dataStore: DataStore!
    var subject: DefaultStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        dataStore = DataStore(errorReporter: MockErrorReporter(), storeType: .memory)

        subject = DefaultStateService(
            appSettingsStore: appSettingsStore,
            dataStore: dataStore,
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        dataStore = nil
        subject = nil
    }

    // MARK: Tests

    /// `activeAccountIdPublisher()` publishes the local user ID.
    func test_activeAccountIdPublisher() async throws {
        var publisher = await subject.activeAccountIdPublisher().values.makeAsyncIterator()
        let userId = await publisher.next()
        XCTAssertEqual(userId, "localtest")
    }

    /// `getAllowUniversalClipboard(userId:)` returns the Universal Clipboard setting for the local user.
    func test_getAllowUniversalClipboard() async throws {
        appSettingsStore.allowUniversalClipboardByUserId["localtest"] = true
        let value = try await subject.getAllowUniversalClipboard(userId: nil)
        XCTAssertTrue(value)
    }

    /// `getAllowUniversalClipboard(userId:)` defaults to `false` if the user doesn't have a value set.
    func test_getAllowUniversalClipboard_notSet() async throws {
        let value = try await subject.getAllowUniversalClipboard(userId: nil)
        XCTAssertFalse(value)
    }

    /// `getClearClipboardValue(userId:)` returns the clear clipboard value for the local user.
    func test_getClearClipboardValue() async throws {
        appSettingsStore.clearClipboardValues["localtest"] = .twoMinutes
        let value = try await subject.getClearClipboardValue(userId: nil)
        XCTAssertEqual(value, .twoMinutes)
    }

    /// `getClearClipboardValue(userId:)` returns `.never` if the user doesn't have a value set.
    func test_getClearClipboardValue_notSet() async throws {
        let value = try await subject.getClearClipboardValue(userId: nil)
        XCTAssertEqual(value, .never)
    }

    /// `getFlightRecorderData()` returns the data for the flight recorder.
    func test_getFlightRecorderData() async throws {
        let storedFlightRecorderData = FlightRecorderData()
        appSettingsStore.flightRecorderData = storedFlightRecorderData

        let flightRecorderData = await subject.getFlightRecorderData()
        XCTAssertEqual(flightRecorderData, storedFlightRecorderData)
    }

    /// `getFlightRecorderData()` returns `nil` if there's no stored data for the flight recorder.
    func test_getFlightRecorderData_notSet() async throws {
        appSettingsStore.flightRecorderData = nil

        let flightRecorderData = await subject.getFlightRecorderData()
        XCTAssertNil(flightRecorderData)
    }

    /// `setAllowUniversalClipboard(_:userId:)` sets the Universal Clipboard setting for the local user.
    func test_setAllowUniversalClipboard() async throws {
        try await subject.setAllowUniversalClipboard(true, userId: nil)
        XCTAssertEqual(appSettingsStore.allowUniversalClipboardByUserId["localtest"], true)

        try await subject.setAllowUniversalClipboard(false, userId: nil)
        XCTAssertEqual(appSettingsStore.allowUniversalClipboardByUserId["localtest"], false)
    }

    /// `setClearClipboardValue(_:userId:)` sets the clear clipboard value for the local user.
    func test_setClearClipboardValue() async throws {
        try await subject.setClearClipboardValue(.thirtySeconds, userId: nil)
        XCTAssertEqual(appSettingsStore.clearClipboardValues["localtest"], .thirtySeconds)
    }

    /// `setFlightRecorderData(_:)` sets the data for the flight recorder.
    func test_setFlightRecorderData() async throws {
        let flightRecorderData = FlightRecorderData()
        await subject.setFlightRecorderData(flightRecorderData)
        XCTAssertEqual(appSettingsStore.flightRecorderData, flightRecorderData)
    }

    /// `setFlightRecorderData(_:)` clears the data when nil is passed.
    func test_setFlightRecorderData_nil() async throws {
        let flightRecorderData = FlightRecorderData()
        await subject.setFlightRecorderData(flightRecorderData)
        XCTAssertEqual(appSettingsStore.flightRecorderData, flightRecorderData)

        await subject.setFlightRecorderData(nil)
        XCTAssertNil(appSettingsStore.flightRecorderData)
    }
}
