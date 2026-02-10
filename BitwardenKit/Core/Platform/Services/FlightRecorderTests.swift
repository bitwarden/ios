import BitwardenKitMocks
import Foundation
import InlineSnapshotTesting
import TestHelpers
import XCTest

@testable import BitwardenKit

// swiftlint:disable file_length

class FlightRecorderTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appInfoService: MockAppInfoService!
    var errorReporter: MockErrorReporter!
    var fileManager: MockFileManager!
    var logURL: URL!
    var stateService: MockFlightRecorderStateService!
    var subject: FlightRecorder!
    var timeProvider: MockTimeProvider!

    let activeLog = FlightRecorderData.LogMetadata(
        duration: .eightHours,
        startDate: Date(year: 2025, month: 1, day: 1),
    )

    let inactiveLog1 = FlightRecorderData.LogMetadata(
        duration: .oneHour,
        startDate: Date(year: 2025, month: 1, day: 2),
    )

    let inactiveLog2 = FlightRecorderData.LogMetadata(
        duration: .oneWeek,
        startDate: Date(year: 2025, month: 1, day: 3),
    )

    // MARK: Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        appInfoService = MockAppInfoService()
        errorReporter = MockErrorReporter()
        fileManager = MockFileManager()
        stateService = MockFlightRecorderStateService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2025, month: 1, day: 1)))

        logURL = try flightRecorderLogURL().appendingPathComponent("flight_recorder_2025-01-01-00-00-00.txt")

        subject = makeSubject()
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

    /// Builds the `DefaultFlightRecorder` subject for testing.
    ///
    func makeSubject(disableLogLifecycleTimer: Bool = true) -> DefaultFlightRecorder {
        DefaultFlightRecorder(
            appInfoService: appInfoService,
            disableLogLifecycleTimerForTesting: disableLogLifecycleTimer,
            errorReporter: errorReporter,
            fileManager: fileManager,
            stateService: stateService,
            timeProvider: timeProvider,
        )
    }

    // MARK: Tests

    /// `activeLogPublisher()` publishes the active log of the flight recorder when there's an
    /// existing active log.
    func test_activeLogPublisher_existingActiveLog() async throws {
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)
        subject = makeSubject()

        var initialPublisher = await subject.activeLogPublisher().values.makeAsyncIterator()
        let firstLog = await initialPublisher.next()
        XCTAssertEqual(firstLog, activeLog)

        // Once the data is cached by the flight recorder, it isn't re-read from state service on
        // subsequent subscriptions. We can test this by modifying the flight recorder data in state
        // service and observing that the flight recorder is still enabled.
        stateService.flightRecorderData = nil

        var secondPublisher = await subject.activeLogPublisher().values.makeAsyncIterator()
        let secondLog = await secondPublisher.next()
        XCTAssertEqual(secondLog, activeLog)
    }

    /// `activeLogPublisher()` publishes the active log of the flight recorder when there's no
    /// existing flight recorder data.
    func test_activeLogPublisher_noFlightRecorderData() async throws {
        var publishedValues = [FlightRecorderData.LogMetadata?]()
        let publisher = await subject.activeLogPublisher().sink { publishedValues.append($0) }
        defer { publisher.cancel() }

        try await subject.enableFlightRecorder(duration: .eightHours)
        await subject.disableFlightRecorder()

        let inactiveLog = try XCTUnwrap(stateService.flightRecorderData?.inactiveLogs.first)
        XCTAssertEqual(publishedValues, [nil, inactiveLog, nil])
    }

    /// `deleteInactiveLogs()` deletes all of the inactive logs and associated metadata.
    func test_deleteInactiveLogs() async throws {
        stateService.flightRecorderData = FlightRecorderData(
            activeLog: activeLog,
            inactiveLogs: [inactiveLog1, inactiveLog2],
        )

        try await subject.deleteInactiveLogs()

        try XCTAssertEqual(
            fileManager.removeItemURLs,
            [
                flightRecorderLogURL().appendingPathComponent(inactiveLog1.fileName),
                flightRecorderLogURL().appendingPathComponent(inactiveLog2.fileName),
            ],
        )
        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(activeLog: activeLog))
    }

    /// `deleteInactiveLogs()` throws an error if removing the file results in an error.
    func test_deleteInactiveLogs_error() async throws {
        fileManager.removeItemResult = .failure(BitwardenTestError.example)
        stateService.flightRecorderData = FlightRecorderData(inactiveLogs: [inactiveLog1])

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.deleteInactiveLogs()
        }

        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(inactiveLogs: [inactiveLog1]))
    }

    /// `deleteInactiveLogs()` handles a file not existing and removes the metadata associated with it.
    func test_deleteInactiveLogs_errorNoSuchFile() async throws {
        fileManager.removeItemResult = .failure(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError))
        stateService.flightRecorderData = FlightRecorderData(inactiveLogs: [inactiveLog1])

        try await subject.deleteInactiveLogs()

        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(inactiveLogs: []))
    }

    /// `deleteInactiveLogs()` throws an error if there's no stored flight recorder data.
    func test_deleteInactiveLogs_noData() async {
        stateService.flightRecorderData = nil
        await assertAsyncThrows(error: FlightRecorderError.dataUnavailable) {
            try await subject.deleteInactiveLogs()
        }
    }

    /// `deleteLog(_:)` deletes the log and its metadata.
    func test_deleteLog() async throws {
        stateService.flightRecorderData = FlightRecorderData(
            activeLog: activeLog,
            inactiveLogs: [inactiveLog1, inactiveLog2],
        )

        try await subject.deleteLog(.fixture(id: inactiveLog1.id, url: logURL))

        XCTAssertEqual(fileManager.removeItemURLs, [logURL])
        XCTAssertEqual(
            stateService.flightRecorderData,
            FlightRecorderData(activeLog: activeLog, inactiveLogs: [inactiveLog2]),
        )
    }

    /// `deleteLog(_:)` throws an error if the log is the active log.
    func test_deleteLog_activeLog() async {
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)
        await assertAsyncThrows(error: FlightRecorderError.deletionNotPermitted) {
            try await subject.deleteLog(.fixture(id: activeLog.id))
        }
    }

    /// `deleteLog(_:)` throws an error if removing the file results in an error.
    func test_deleteLog_error() async throws {
        fileManager.removeItemResult = .failure(BitwardenTestError.example)
        stateService.flightRecorderData = FlightRecorderData(inactiveLogs: [inactiveLog1])

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.deleteLog(.fixture(id: inactiveLog1.id))
        }

        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(inactiveLogs: [inactiveLog1]))
    }

    /// `deleteLog(_:)` handles the file not existing and removes the metadata associated with it.
    func test_deleteLog_errorNoSuchFile() async throws {
        fileManager.removeItemResult = .failure(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError))
        stateService.flightRecorderData = FlightRecorderData(inactiveLogs: [inactiveLog1])

        try await subject.deleteLog(.fixture(id: inactiveLog1.id))

        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(inactiveLogs: []))
    }

    /// `deleteLog(_:)` throws an error if the log isn't in the flight recorder data.
    func test_deleteLog_logNotFound() async {
        stateService.flightRecorderData = FlightRecorderData()
        await assertAsyncThrows(error: FlightRecorderError.logNotFound) {
            try await subject.deleteLog(.fixture())
        }
    }

    /// `deleteLog(_:)` throws an error if there's no stored flight recorder data.
    func test_deleteLog_noData() async {
        stateService.flightRecorderData = nil
        await assertAsyncThrows(error: FlightRecorderError.dataUnavailable) {
            try await subject.deleteLog(.fixture())
        }
    }

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
            FlightRecorderData(inactiveLogs: [
                FlightRecorderData.LogMetadata(
                    duration: .twentyFourHours,
                    startDate: timeProvider.presentTime,
                ),
            ]),
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
                    startDate: timeProvider.presentTime,
                ),
            ),
        )

        XCTAssertEqual(fileManager.createDirectoryURL, logURL.deletingLastPathComponent())
        XCTAssertEqual(fileManager.createDirectoryCreateIntermediates, true)
        XCTAssertEqual(fileManager.setIsExcludedFromBackupURL, logURL)
        XCTAssertEqual(fileManager.setIsExcludedFromBackupValue, true)

        XCTAssertEqual(fileManager.writeDataURL, logURL)
        try assertInlineSnapshot(of: String(data: XCTUnwrap(fileManager.writeDataData), encoding: .utf8), as: .lines) {
            """
            Bitwarden iOS Flight Recorder
            🕒 Log Start: 2025-01-01T00:00:00Z
            ⏳ Log Duration: 24h
            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            👤 User ID: n/a


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

    /// `fetchLogs()` returns the list of flight recorder logs on the device.
    func test_fetchLogs() async throws {
        fileManager.attributesOfItemResult = .success([.size: Int64(123_000)])
        stateService.flightRecorderData = FlightRecorderData(
            activeLog: activeLog,
            inactiveLogs: [inactiveLog1, inactiveLog2],
        )

        let logs = try await subject.fetchLogs()

        try XCTAssertEqual(
            logs,
            [
                FlightRecorderLogMetadata.fixture(
                    duration: .eightHours,
                    endDate: Date(year: 2025, month: 1, day: 1, hour: 8),
                    expirationDate: Date(year: 2025, month: 1, day: 31, hour: 8),
                    fileSize: "120 KB",
                    id: activeLog.id,
                    isActiveLog: true,
                    startDate: Date(year: 2025, month: 1, day: 1),
                    url: flightRecorderLogURL().appendingPathComponent(activeLog.fileName),
                ),
                FlightRecorderLogMetadata.fixture(
                    duration: .oneHour,
                    endDate: Date(year: 2025, month: 1, day: 2, hour: 1),
                    expirationDate: Date(year: 2025, month: 2, day: 1, hour: 1),
                    fileSize: "120 KB",
                    id: inactiveLog1.id,
                    isActiveLog: false,
                    startDate: Date(year: 2025, month: 1, day: 2),
                    url: flightRecorderLogURL().appendingPathComponent(inactiveLog1.fileName),
                ),
                FlightRecorderLogMetadata.fixture(
                    duration: .oneWeek,
                    endDate: Date(year: 2025, month: 1, day: 10),
                    expirationDate: Date(year: 2025, month: 2, day: 9, hour: 0),
                    fileSize: "120 KB",
                    id: inactiveLog2.id,
                    isActiveLog: false,
                    startDate: Date(year: 2025, month: 1, day: 3),
                    url: flightRecorderLogURL().appendingPathComponent(inactiveLog2.fileName),
                ),
            ],
        )
    }

    /// `fetchLogs()` returns an empty list if there's no flight recorder logs on the device.
    func test_fetchLogs_empty() async throws {
        stateService.flightRecorderData = FlightRecorderData()
        let logs = try await subject.fetchLogs()
        XCTAssertTrue(logs.isEmpty)
    }

    /// `fetchLogs()` calculates a default file size if a file size attribute isn't returned.
    func test_fetchLogs_fileSize_nil() async throws {
        fileManager.attributesOfItemResult = .success([:])
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)

        let logs = try await subject.fetchLogs()

        XCTAssertEqual(logs[0].fileSize, "0 bytes")
    }

    /// `fetchLogs()` calculates the file size of the log for various file sizes.
    func test_fetchLogs_fileSizes() async throws {
        stateService.flightRecorderData = FlightRecorderData(
            activeLog: activeLog,
            inactiveLogs: [inactiveLog1, inactiveLog2],
        )

        fileManager.attributesOfItemResult = .success([.size: Int64(0)])
        var logs = try await subject.fetchLogs()
        XCTAssertEqual(logs[0].fileSize, "0 bytes")

        fileManager.attributesOfItemResult = .success([.size: Int64(1000)])
        logs = try await subject.fetchLogs()
        XCTAssertEqual(logs[0].fileSize, "1,000 bytes")

        fileManager.attributesOfItemResult = .success([.size: Int64(1024)])
        logs = try await subject.fetchLogs()
        XCTAssertEqual(logs[0].fileSize, "1 KB")

        fileManager.attributesOfItemResult = .success([.size: Int64(80000)])
        logs = try await subject.fetchLogs()
        XCTAssertEqual(logs[0].fileSize, "78 KB")

        fileManager.attributesOfItemResult = .success([.size: Int64(1024 * 1024)])
        logs = try await subject.fetchLogs()
        XCTAssertEqual(logs[0].fileSize, "1 MB")

        fileManager.attributesOfItemResult = .success([.size: Int64(123_000_000)])
        logs = try await subject.fetchLogs()
        XCTAssertEqual(logs[0].fileSize, "117.3 MB")

        fileManager.attributesOfItemResult = .success([.size: Int64(1024 * 1024 * 1024)])
        logs = try await subject.fetchLogs()
        XCTAssertEqual(logs[0].fileSize, "1 GB")
    }

    /// `fetchLogs()` returns an empty file size if the file wasn't found.
    func test_fetchLogs_fileSize_fileNotFound() async throws {
        fileManager.attributesOfItemResult = .failure(
            NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError),
        )
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)

        let logs = try await subject.fetchLogs()

        XCTAssertEqual(logs[0].fileSize, "")
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `fetchLogs()` returns an empty file size and logs an error if determining the file size fails.
    func test_fetchLogs_fileSize_error() async throws {
        fileManager.attributesOfItemResult = .failure(BitwardenTestError.example)
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)

        let logs = try await subject.fetchLogs()

        XCTAssertEqual(logs[0].fileSize, "")
        XCTAssertEqual(errorReporter.errors.count, 1)
        let error = try XCTUnwrap(errorReporter.errors.first as? FlightRecorderError)
        XCTAssertEqual(error, FlightRecorderError.fileSizeError(BitwardenTestError.example))
    }

    /// `fetchLogs()` return an empty list if there's no flight recorder data on the device.
    func test_fetchLogs_noData() async throws {
        stateService.flightRecorderData = nil
        let logs = try await subject.fetchLogs()
        XCTAssertTrue(logs.isEmpty)
    }

    /// `init()` starts the log lifecycle timer and ends the active log when its logging duration
    /// has elapsed.
    func test_init_logLifecycleTimer_activeLogEnds() async throws {
        timeProvider.timeConfig = .mockTime(Date(year: 2025, month: 1, day: 1, hour: 8))
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)
        subject = makeSubject(disableLogLifecycleTimer: false)

        var isEnabled: Bool?
        let publisher = await subject.isEnabledPublisher().sink { isEnabled = $0 }
        defer { publisher.cancel() }

        try await waitForAsync { isEnabled == false }

        // Active log is inactive.
        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(inactiveLogs: [activeLog]))
    }

    /// `init()` starts the log lifecycle timer and removes an expired active log.
    func test_init_logLifecycleTimer_activeLogExpires() async throws {
        timeProvider.timeConfig = .mockTime(Date(year: 2025, month: 2, day: 1))
        stateService.flightRecorderData = FlightRecorderData(
            activeLog: activeLog,
        )
        subject = makeSubject(disableLogLifecycleTimer: false)

        try await waitForAsync { self.stateService.flightRecorderData == FlightRecorderData() }

        // Expired active log is removed.
        try XCTAssertEqual(
            fileManager.removeItemURLs,
            [flightRecorderLogURL().appendingPathComponent(activeLog.fileName)],
        )
        XCTAssertEqual(
            stateService.flightRecorderData,
            FlightRecorderData(),
        )
    }

    /// `init()` starts the log lifecycle timer and removes any expired inactive logs.
    func test_init_logLifecycleTimer_inactiveLogExpires() async throws {
        let expiredLog = FlightRecorderData.LogMetadata(
            duration: .oneHour,
            startDate: Date(year: 2024, month: 11, day: 30),
        )
        timeProvider.timeConfig = .mockTime(Date(year: 2025, month: 1, day: 1, hour: 5))
        stateService.flightRecorderData = FlightRecorderData(
            activeLog: activeLog,
            inactiveLogs: [inactiveLog1, expiredLog],
        )
        subject = makeSubject(disableLogLifecycleTimer: false)

        var publisher = await subject.isEnabledPublisher().values.makeAsyncIterator()

        // Flight recorder is enabled due to active log.
        let isEnabled = await publisher.next()
        XCTAssertEqual(isEnabled, true)

        try await waitForAsync { self.stateService.flightRecorderData?.inactiveLogs.count == 1 }

        // Expired inactive log is removed.
        try XCTAssertEqual(
            fileManager.removeItemURLs,
            [flightRecorderLogURL().appendingPathComponent(expiredLog.fileName)],
        )
        XCTAssertEqual(
            stateService.flightRecorderData,
            FlightRecorderData(activeLog: activeLog, inactiveLogs: [inactiveLog1]),
        )
    }

    /// `init()` starts the log lifecycle timer and removes multiple expired inactive logs.
    func test_init_logLifecycleTimer_multipleInactiveLogsExpire() async throws {
        let expiredLog1 = FlightRecorderData.LogMetadata(
            duration: .oneHour,
            startDate: Date(year: 2024, month: 10, day: 30),
        )
        let expiredLog2 = FlightRecorderData.LogMetadata(
            duration: .oneHour,
            startDate: Date(year: 2024, month: 11, day: 1),
        )
        let expiredLog3 = FlightRecorderData.LogMetadata(
            duration: .oneHour,
            startDate: Date(year: 2024, month: 11, day: 15),
        )
        timeProvider.timeConfig = .mockTime(Date(year: 2025, month: 1, day: 1, hour: 5))
        stateService.flightRecorderData = FlightRecorderData(
            activeLog: activeLog,
            inactiveLogs: [expiredLog1, inactiveLog1, expiredLog2, inactiveLog2, expiredLog3],
        )
        subject = makeSubject(disableLogLifecycleTimer: false)

        var publisher = await subject.isEnabledPublisher().values.makeAsyncIterator()

        // Flight recorder is enabled due to active log.
        let isEnabled = await publisher.next()
        XCTAssertEqual(isEnabled, true)

        try await waitForAsync { self.stateService.flightRecorderData?.inactiveLogs.count == 2 }

        // All expired inactive logs are removed.
        try XCTAssertEqual(
            Set(fileManager.removeItemURLs),
            Set([
                flightRecorderLogURL().appendingPathComponent(expiredLog1.fileName),
                flightRecorderLogURL().appendingPathComponent(expiredLog2.fileName),
                flightRecorderLogURL().appendingPathComponent(expiredLog3.fileName),
            ]),
        )
        XCTAssertEqual(
            stateService.flightRecorderData,
            FlightRecorderData(activeLog: activeLog, inactiveLogs: [inactiveLog1, inactiveLog2]),
        )
    }

    /// `init()` starts the log lifecycle timer, which logs an error if removing a file for an
    /// expired log fails.
    func test_init_logLifecycleTimer_errorRemovingFile() async throws {
        timeProvider.timeConfig = .mockTime(Date(year: 2025, month: 3, day: 1))
        fileManager.removeItemResult = .failure(BitwardenTestError.example)
        stateService.flightRecorderData = FlightRecorderData(inactiveLogs: [inactiveLog1])
        subject = makeSubject(disableLogLifecycleTimer: false)

        try await waitForAsync { !self.errorReporter.errors.isEmpty }

        XCTAssertEqual(errorReporter.errors.count, 1)
        let error = try XCTUnwrap(errorReporter.errors.first as? FlightRecorderError)
        XCTAssertEqual(error, .removeExpiredLogError(BitwardenTestError.example))
        try XCTAssertEqual(
            fileManager.removeItemURLs,
            [flightRecorderLogURL().appendingPathComponent(inactiveLog1.fileName)],
        )
        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData())
    }

    /// `isEnabledPublisher()` publishes the enabled status of the flight recorder when there's an
    /// existing active log.
    func test_isEnabledPublisher_existingActiveLog() async throws {
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)
        subject = makeSubject()

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
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)
        subject = makeSubject()

        var isEnabled = false
        let publisher = await subject.isEnabledPublisher().sink { isEnabled = $0 }
        defer { publisher.cancel() }

        try await waitForAsync { isEnabled }
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
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)

        await subject.log("Hello world!")

        let appendedMessage = try String(data: XCTUnwrap(fileManager.appendDataData), encoding: .utf8)
        XCTAssertEqual(appendedMessage, "2025-01-01T00:00:00Z: Hello world!\n")
        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(activeLog: activeLog))
    }

    /// `log(_:)` logs an error and deactivates the flight recorder if appending the log to the file
    /// fails.
    func test_log_error() async throws {
        fileManager.appendDataResult = .failure(BitwardenTestError.example)
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)

        await subject.log("Hello world!")

        XCTAssertEqual(errorReporter.errors.count, 1)
        let error = try XCTUnwrap(errorReporter.errors.last as? FlightRecorderError)
        XCTAssertEqual(error, .writeMessageError(BitwardenTestError.example))
        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(inactiveLogs: [activeLog]))
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

    /// `setFlightRecorderBannerDismissed()` sets that the flight recorder banner was dismissed by
    /// the user.
    func test_setFlightRecorderBannerDismissed() async {
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)
        await subject.setFlightRecorderBannerDismissed()

        var activeLogWithDismissedBanner = activeLog
        activeLogWithDismissedBanner.isBannerDismissed = true
        XCTAssertEqual(
            stateService.flightRecorderData,
            FlightRecorderData(activeLog: activeLogWithDismissedBanner),
        )
    }

    /// `setFlightRecorderBannerDismissed()` doesn't modify the flight recorder data if there's no
    /// flight recorder data.
    func test_setFlightRecorderBannerDismissed_noFlightRecorderData() async {
        await subject.setFlightRecorderBannerDismissed()
        XCTAssertNil(stateService.flightRecorderData)
    }

    // MARK: DefaultFlightRecorder Tests

    /// `DefaultFlightRecorder` implements `BitwardenLogger.log()` which logs to the active log.
    func test_log_bitwardenLogger() throws {
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)

        (subject as? DefaultFlightRecorder)?.log("Hello world!")
        waitFor { self.fileManager.appendDataData != nil }

        let appendedMessage = try String(data: XCTUnwrap(fileManager.appendDataData), encoding: .utf8)
        XCTAssertEqual(appendedMessage, "2025-01-01T00:00:00Z: Hello world!\n")
        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(activeLog: activeLog))
    }

    // MARK: Private

    /// Returns an unwrapped URL to the directory containing flight recorder logs.
    private func flightRecorderLogURL() throws -> URL {
        try XCTUnwrap(FileManager.default.flightRecorderLogURL())
    }
}
