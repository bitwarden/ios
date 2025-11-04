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

    /// `setFlightRecorderData(_:)` sets the data for the flight recorder.
    func test_setFlightRecorderData() async throws {
        let flightRecorderData = FlightRecorderData()
        await subject.setFlightRecorderData(flightRecorderData)
        XCTAssertEqual(appSettingsStore.flightRecorderData, flightRecorderData)
    }
}
