import BitwardenKitMocks
import Foundation
import InlineSnapshotTesting
import TestHelpers
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

class FlightRecorderTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appInfoService: MockAppInfoService!
    var errorReporter: MockErrorReporter!
    var fileManager: MockFileManager!
    var logURL: URL!
    var stateService: MockStateService!
    var subject: FlightRecorder!
    var timeProvider: MockTimeProvider!

    let activeLog = FlightRecorderData.LogMetadata(
        duration: .eightHours,
        startDate: Date(year: 2025, month: 1, day: 1)
    )

    let archivedLog1 = FlightRecorderData.LogMetadata(
        duration: .oneHour,
        startDate: Date(year: 2025, month: 1, day: 2)
    )

    let archivedLog2 = FlightRecorderData.LogMetadata(
        duration: .oneWeek,
        startDate: Date(year: 2025, month: 1, day: 3)
    )

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

    /// `deleteArchivedLogs()` deletes all of the archived logs and associated metadata.
    func test_deleteArchivedLogs() async throws {
        stateService.flightRecorderData = FlightRecorderData(
            activeLog: activeLog,
            archivedLogs: [archivedLog1, archivedLog2]
        )

        try await subject.deleteArchivedLogs()

        try XCTAssertEqual(
            fileManager.removeItemURLs,
            [
                FileManager.default.flightRecorderLogURL().appendingPathComponent(archivedLog1.fileName),
                FileManager.default.flightRecorderLogURL().appendingPathComponent(archivedLog2.fileName),
            ]
        )
        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(activeLog: activeLog))
    }

    /// `deleteArchivedLogs()` throws an error if removing the file results in an error.
    func test_deleteArchivedLogs_error() async throws {
        fileManager.removeItemResult = .failure(BitwardenTestError.example)
        stateService.flightRecorderData = FlightRecorderData(archivedLogs: [archivedLog1])

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.deleteArchivedLogs()
        }

        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(archivedLogs: [archivedLog1]))
    }

    /// `deleteArchivedLogs()` handles a file not existing and removes the metadata associated with it.
    func test_deleteArchivedLogs_errorNoSuchFile() async throws {
        fileManager.removeItemResult = .failure(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError))
        stateService.flightRecorderData = FlightRecorderData(archivedLogs: [archivedLog1])

        try await subject.deleteArchivedLogs()

        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(archivedLogs: []))
    }

    /// `deleteArchivedLogs()` throws an error if there's no stored flight recorder data.
    func test_deleteArchivedLogs_noData() async {
        stateService.flightRecorderData = nil
        await assertAsyncThrows(error: FlightRecorderError.dataUnavailable) {
            try await subject.deleteArchivedLogs()
        }
    }

    /// `deleteLog(_:)` deletes the log and its metadata.
    func test_deleteLog() async throws {
        stateService.flightRecorderData = FlightRecorderData(
            activeLog: activeLog,
            archivedLogs: [archivedLog1, archivedLog2]
        )

        try await subject.deleteLog(.fixture(id: archivedLog1.id, url: logURL))

        XCTAssertEqual(fileManager.removeItemURLs, [logURL])
        XCTAssertEqual(
            stateService.flightRecorderData,
            FlightRecorderData(activeLog: activeLog, archivedLogs: [archivedLog2])
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
        stateService.flightRecorderData = FlightRecorderData(archivedLogs: [archivedLog1])

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.deleteLog(.fixture(id: archivedLog1.id))
        }

        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(archivedLogs: [archivedLog1]))
    }

    /// `deleteLog(_:)` handles the file not existing and removes the metadata associated with it.
    func test_deleteLog_errorNoSuchFile() async throws {
        fileManager.removeItemResult = .failure(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError))
        stateService.flightRecorderData = FlightRecorderData(archivedLogs: [archivedLog1])

        try await subject.deleteLog(.fixture(id: archivedLog1.id))

        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(archivedLogs: []))
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

    /// `fetchLogs()` returns the list of flight recorder logs on the device.
    func test_fetchLogs() async throws {
        fileManager.attributesOfItemResult = .success([.size: Int64(123_000)])
        stateService.flightRecorderData = FlightRecorderData(
            activeLog: activeLog,
            archivedLogs: [archivedLog1, archivedLog2]
        )
        let flightRecorderLogURL = try FileManager.default.flightRecorderLogURL()

        let logs = try await subject.fetchLogs()

        XCTAssertEqual(
            logs,
            [
                FlightRecorderLogMetadata.fixture(
                    duration: .eightHours,
                    endDate: Date(year: 2025, month: 1, day: 1, hour: 8),
                    fileSize: "120 KB",
                    id: activeLog.id,
                    isActiveLog: true,
                    startDate: Date(year: 2025, month: 1, day: 1),
                    url: flightRecorderLogURL.appendingPathComponent(activeLog.fileName)
                ),
                FlightRecorderLogMetadata.fixture(
                    duration: .oneHour,
                    endDate: Date(year: 2025, month: 1, day: 2, hour: 1),
                    fileSize: "120 KB",
                    id: archivedLog1.id,
                    isActiveLog: false,
                    startDate: Date(year: 2025, month: 1, day: 2),
                    url: flightRecorderLogURL.appendingPathComponent(archivedLog1.fileName)
                ),
                FlightRecorderLogMetadata.fixture(
                    duration: .oneWeek,
                    endDate: Date(year: 2025, month: 1, day: 10),
                    fileSize: "120 KB",
                    id: archivedLog2.id,
                    isActiveLog: false,
                    startDate: Date(year: 2025, month: 1, day: 3),
                    url: flightRecorderLogURL.appendingPathComponent(archivedLog2.fileName)
                ),
            ]
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
            archivedLogs: [archivedLog1, archivedLog2]
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
            NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError)
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
        let error = try XCTUnwrap(errorReporter.errors.first as? NSError)
        XCTAssertEqual(error.domain, "General Error: Flight Recorder File Size Error")
        XCTAssertEqual(error.code, BitwardenError.Code.generalError.rawValue)
    }

    /// `fetchLogs()` return an empty list if there's no flight recorder data on the device.
    func test_fetchLogs_noData() async throws {
        stateService.flightRecorderData = nil
        let logs = try await subject.fetchLogs()
        XCTAssertTrue(logs.isEmpty)
    }

    /// `isEnabledPublisher()` publishes the enabled status of the flight recorder when there's an
    /// existing active log.
    func test_isEnabledPublisher_existingActiveLog() async throws {
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
        stateService.flightRecorderData = FlightRecorderData(activeLog: activeLog)

        await subject.log("Hello world!")

        let appendedMessage = try String(data: XCTUnwrap(fileManager.appendDataData), encoding: .utf8)
        XCTAssertEqual(appendedMessage, "2025-01-01T00:00:00Z: Hello world!\n")
        XCTAssertEqual(stateService.flightRecorderData, FlightRecorderData(activeLog: activeLog))
    }

    /// `log(_:)` logs an error if appending the log to the file fails.
    func test_log_error() async throws {
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
