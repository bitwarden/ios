import XCTest

@testable import BitwardenShared

class FlightRecorderDataTests: BitwardenTestCase {
    // MARK: Tests

    /// `allLogs` returns a list of all logs when there are no logs.
    func test_allLogs_empty() {
        let subject = FlightRecorderData()
        XCTAssertEqual(subject.allLogs, [])
    }

    /// `allLogs` returns a list of all logs when there's active and archived logs.
    func test_allLogs_activeAndArchivedLogs() {
        let activeLog = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now)
        let archivedLogs = [
            FlightRecorderData.LogMetadata(duration: .oneHour, startDate: .now),
            FlightRecorderData.LogMetadata(duration: .oneWeek, startDate: .now),
        ]
        let subject = FlightRecorderData(activeLog: activeLog, archivedLogs: archivedLogs)
        XCTAssertEqual(subject.allLogs, [activeLog] + archivedLogs)
    }

    /// `allLogs` returns a list of all logs when there's an active log.
    func test_allLogs_activeLog() {
        let log = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now)
        let subject = FlightRecorderData(activeLog: log)
        XCTAssertEqual(subject.allLogs, [log])
    }

    /// `allLogs` returns a list of all logs when there are archived logs.
    func test_allLogs_archivedLogs() {
        let logs = [
            FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now),
            FlightRecorderData.LogMetadata(duration: .oneHour, startDate: .now),
            FlightRecorderData.LogMetadata(duration: .oneWeek, startDate: .now),
        ]
        let subject = FlightRecorderData(archivedLogs: logs)
        XCTAssertEqual(subject.allLogs, logs)
    }

    /// `activeLog` sets the active log.
    func test_setActiveLog() {
        var subject = FlightRecorderData()
        let log = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now)
        subject.activeLog = log

        XCTAssertEqual(subject, FlightRecorderData(activeLog: log))
    }

    /// `activeLog` sets the active log, archiving an existing log if there's already one active.
    func test_setActiveLog_existingLog() {
        let log1 = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now)
        var subject = FlightRecorderData(activeLog: log1)

        let log2 = FlightRecorderData.LogMetadata(duration: .oneWeek, startDate: .now)
        subject.activeLog = log2

        XCTAssertEqual(subject, FlightRecorderData(activeLog: log2, archivedLogs: [log1]))
    }

    // MARK: FlightRecorderData.LogMetadata Tests

    /// `id` returns the log's file name as a unique identifier.
    func test_logMetadata_id() {
        let log1 = FlightRecorderData.LogMetadata(duration: .oneHour, startDate: .now)
        XCTAssertEqual(log1.id, log1.fileName)

        let log2 = FlightRecorderData.LogMetadata(duration: .oneWeek, startDate: .now)
        XCTAssertEqual(log2.id, log2.fileName)
    }

    /// `init(duration:startDate:)` creates a file name for the log based on the start date.
    func test_logMetadata_init_fileName() {
        let log1 = FlightRecorderData.LogMetadata(
            duration: .oneHour,
            startDate: Date(year: 2025, month: 4, day: 11, hour: 10, minute: 30, second: 20)
        )
        XCTAssertEqual(log1.fileName, "flight_recorder_2025-04-11-10-30-20.txt")

        let log2 = FlightRecorderData.LogMetadata(
            duration: .oneWeek,
            startDate: Date(year: 2025, month: 1, day: 2, hour: 3, minute: 4, second: 5)
        )
        XCTAssertEqual(log2.fileName, "flight_recorder_2025-01-02-03-04-05.txt")
    }
}
