import BitwardenKitMocks
import Foundation
import InlineSnapshotTesting
import TestHelpers
import XCTest

@testable import BitwardenShared

class FlightRecorderTests: BitwardenTestCase {
    // MARK: Properties

    var appInfoService: MockAppInfoService!
    var errorReporter: MockErrorReporter!
    var fileManager: MockFileManager!
    var logURL: URL!
    var stateService: MockStateService!
    var subject: FlightRecorder!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        appInfoService = MockAppInfoService()
        errorReporter = MockErrorReporter()
        fileManager = MockFileManager()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2025, month: 1, day: 1)))

        logURL = try XCTUnwrap(FileManager.default.flightRecorderLogURL()
            .appendingPathComponent("flight_recorder_2025-01-01-00-00-00.txt"))

        subject = DefaultFlightRecorder(
            appInfoService: appInfoService,
            errorReporter: errorReporter,
            fileManager: fileManager,
            stateService: stateService,
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        appInfoService = nil
        errorReporter = nil
        fileManager = nil
        logURL = nil
        stateService = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// `disableFlightRecorder()` disables the flight recorder.
    func test_disableFlightRecorder() async throws {
        var isEnabledValues = [Bool]()
        let publisher = await subject.isEnabledPublisher().sink { isEnabledValues.append($0) }
        defer { publisher.cancel() }

        try await subject.enableFlightRecorder(duration: .twentyFourHours)
        XCTAssertNotNil(stateService.flightRecorderData?.activeLog)

        await subject.disableFlightRecorder()

        XCTAssertEqual(isEnabledValues, [false, true, false])
        XCTAssertEqual(
            stateService.flightRecorderData,
            FlightRecorderData(archivedLogs: [
                FlightRecorderData.LogMetadata(
                    duration: .twentyFourHours,
                    startDate: timeProvider.presentTime
                ),
            ])
        )
    }

    /// `enableFlightRecorder(duration:)` enables the flight recorder for the specified duration.
    func test_enableFlightRecorder() async throws {
        var isEnabledValues = [Bool]()
        let publisher = await subject.isEnabledPublisher().sink { isEnabledValues.append($0) }
        defer { publisher.cancel() }

        try await subject.enableFlightRecorder(duration: .twentyFourHours)

        XCTAssertEqual(isEnabledValues, [false, true])
        XCTAssertEqual(
            stateService.flightRecorderData,
            FlightRecorderData(
                activeLog: FlightRecorderData.LogMetadata(
                    duration: .twentyFourHours,
                    startDate: timeProvider.presentTime
                )
            )
        )

        XCTAssertEqual(fileManager.createDirectoryURL, logURL.deletingLastPathComponent())
        XCTAssertEqual(fileManager.createDirectoryCreateIntermediates, true)
        XCTAssertEqual(fileManager.setIsExcludedFromBackupURL, logURL)
        XCTAssertEqual(fileManager.setIsExcludedFromBackupValue, true)

        XCTAssertEqual(fileManager.writeDataURL, logURL)
        try assertInlineSnapshot(of: String(data: XCTUnwrap(fileManager.writeDataData), encoding: .utf8), as: .lines) {
            """
            Bitwarden iOS Flight Recorder
            Log Start: 2025-01-01T00:00:00Z
            Log Duration: 24h
            Version: 1.0 (1)
            📱 iPhone14,2 🍏 iOS 16.4 📦 Production
            User ID: n/a


            """
        }
    }

    /// `enableFlightRecorder(duration:)` throws an error if creating the logs directory fails.
    func test_enableFlightRecorder_errorCreateDirectory() async throws {
        var isEnabled = false
        let publisher = await subject.isEnabledPublisher().sink { isEnabled = $0 }
        defer { publisher.cancel() }

        fileManager.createDirectoryResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.enableFlightRecorder(duration: .twentyFourHours)
        }

        XCTAssertNil(stateService.flightRecorderData)
        XCTAssertFalse(isEnabled)
    }

    /// `enableFlightRecorder(duration:)` throws an error if creating the log file fails.
    func test_enableFlightRecorder_errorWriteFile() async throws {
        var isEnabled = false
        let publisher = await subject.isEnabledPublisher().sink { isEnabled = $0 }
        defer { publisher.cancel() }

        fileManager.writeDataResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.enableFlightRecorder(duration: .twentyFourHours)
        }

        XCTAssertNil(stateService.flightRecorderData)
        XCTAssertFalse(isEnabled)
    }

    /// `isEnabledPublisher()` publishes the enabled status of the flight recorder when there's an
    /// existing active log.
    func test_isEnabledPublisher_existingActiveLog() async throws {
        let activeLog = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now)
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)

        var initialPublisher = await subject.isEnabledPublisher().values.makeAsyncIterator()
        let initialIsEnabled = await initialPublisher.next()
        XCTAssertEqual(initialIsEnabled, true)

        // Once the data is cached by the flight recorder, it isn't re-read from state service on
        // subsequent subscriptions. We can test this by modifying the flight recorder data in state
        // service and observing that the flight recorder is still enabled.
        stateService.flightRecorderData = nil

        var secondPublisher = await subject.isEnabledPublisher().values.makeAsyncIterator()
        let secondIsEnabled = await secondPublisher.next()
        XCTAssertEqual(secondIsEnabled, true)
    }

    /// `isEnabledPublisher()` publishes the enabled status of the flight recorder where there's an
    /// existing active log.
    func test_isEnabledPublisher_existingFlightRecorderData() async throws {
        let activeLog = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now)
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)

        var isEnabled = false
        let publisher = await subject.isEnabledPublisher().sink { isEnabled = $0 }
        defer { publisher.cancel() }

        XCTAssertTrue(isEnabled)
        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(activeLog: activeLog))
    }

    /// `isEnabledPublisher()` publishes the enabled status of the flight recorder when there's no
    /// existing flight recorder data.
    func test_isEnabledPublisher_noFlightRecorderData() async throws {
        var isEnabledValues = [Bool]()
        let publisher = await subject.isEnabledPublisher().sink { isEnabledValues.append($0) }
        defer { publisher.cancel() }

        try await subject.enableFlightRecorder(duration: .eightHours)
        await subject.disableFlightRecorder()

        XCTAssertEqual(isEnabledValues, [false, true, false])
    }

    /// `log(_:)` appends the timestamped message to the active log.
    func test_log() async throws {
        let activeLog = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now)
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)

        await subject.log("Hello world!")

        let appendedMessage = try String(data: XCTUnwrap(fileManager.appendDataData), encoding: .utf8)
        XCTAssertEqual(appendedMessage, "2025-01-01T00:00:00Z: Hello world!\n")
        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(activeLog: activeLog))
    }

    /// `log(_:)` logs an error if appending the log to the file fails.
    func test_log_error() async throws {
        let activeLog = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now)
        fileManager.appendDataResult = .failure(BitwardenTestError.example)
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)

        await subject.log("Hello world!")

        XCTAssertEqual(errorReporter.errors.count, 1)
        let error = try XCTUnwrap(errorReporter.errors.last as? NSError)
        XCTAssertEqual(error.code, BitwardenError.Code.generalError.rawValue)
        XCTAssertEqual(error.domain, "General Error: Flight Recorder Log Error")
    }

    /// `log(_:)` doesn't record the log if there's no active log.
    func test_log_noActiveLog() async {
        stateService.flightRecorderData = FlightRecorderData()
        await subject.log("Hello world!")
        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData())
    }

    /// `log(_:)` doesn't record the log if there's no flight recorder log data.
    func test_log_noLogData() async {
        stateService.flightRecorderData = nil
        await subject.log("Hello world!")
        XCTAssertNil(stateService.flightRecorderData)
    }
}
