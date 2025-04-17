import XCTest

@testable import BitwardenShared

class FlightRecorderTests: BitwardenTestCase {
    // MARK: Properties

    var stateService: MockStateService!
    var subject: FlightRecorder!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2025, month: 1, day: 1)))

        subject = DefaultFlightRecorder(
            stateService: stateService,
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        stateService = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// `disableFlightRecorder()` disables the flight recorder.
    func test_disableFlightRecorder() async {
        var isEnabledValues = [Bool]()
        let publisher = await subject.isEnabledPublisher().sink { isEnabledValues.append($0) }
        defer { publisher.cancel() }

        await subject.enableFlightRecorder(duration: .twentyFourHours)
        await subject.disableFlightRecorder()

        XCTAssertEqual(isEnabledValues, [false, true, false])
    }

    /// `enableFlightRecorder(duration:)` enables the flight recorder for the specified duration.
    func test_enableFlightRecorder() async {
        var isEnabledValues = [Bool]()
        let publisher = await subject.isEnabledPublisher().sink { isEnabledValues.append($0) }
        defer { publisher.cancel() }

        await subject.enableFlightRecorder(duration: .twentyFourHours)

        XCTAssertEqual(isEnabledValues, [false, true])
    }

    /// `isEnabledPublisher()` publishes the enabled status of the flight recorder.
    func test_isEnabledPublisher() async throws {
        var isEnabled = false
        let publisher = await subject.isEnabledPublisher().sink { isEnabled = $0 }
        defer { publisher.cancel() }

        await subject.enableFlightRecorder(duration: .eightHours)
        XCTAssertTrue(isEnabled)

        await subject.disableFlightRecorder()
        XCTAssertFalse(isEnabled)
    }
}
