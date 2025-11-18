import XCTest

@testable import BitwardenKit

class FlightRecorderDataTests: BitwardenTestCase {
    // MARK: Tests

    /// `allLogs` returns a list of all logs when there are no logs.
    func test_allLogs_empty() {
        let subject = FlightRecorderData()
        XCTAssertEqual(subject.allLogs, [])
    }

    /// `allLogs` returns a list of all logs when there's active and inactive logs.
    func test_allLogs_activeAndInactiveLogs() {
        let activeLog = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now)
        let inactiveLogs = [
            FlightRecorderData.LogMetadata(duration: .oneHour, startDate: .now),
            FlightRecorderData.LogMetadata(duration: .oneWeek, startDate: .now),
        ]
        let subject = FlightRecorderData(activeLog: activeLog, inactiveLogs: inactiveLogs)
        XCTAssertEqual(subject.allLogs, [activeLog] + inactiveLogs)
    }

    /// `allLogs` returns a list of all logs when there's an active log.
    func test_allLogs_activeLog() {
        let log = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now)
        let subject = FlightRecorderData(activeLog: log)
        XCTAssertEqual(subject.allLogs, [log])
    }

    /// `allLogs` returns a list of all logs when there are inactive logs.
    func test_allLogs_inactiveLogs() {
        let logs = [
            FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now),
            FlightRecorderData.LogMetadata(duration: .oneHour, startDate: .now),
            FlightRecorderData.LogMetadata(duration: .oneWeek, startDate: .now),
        ]
        let subject = FlightRecorderData(inactiveLogs: logs)
        XCTAssertEqual(subject.allLogs, logs)
    }

    /// `nextLogLifecycleDate` returns the date in which the active log ends logging if that's before
    /// any of the inactive logs expire.
    func test_nextLogLifecycleDate_activeLog() {
        let subject = FlightRecorderData(
            activeLog: FlightRecorderData.LogMetadata(
                duration: .eightHours,
                startDate: Date(year: 2025, month: 4, day: 1),
            ),
            inactiveLogs: [
                FlightRecorderData.LogMetadata(duration: .eightHours, startDate: Date(year: 2025, month: 3, day: 20)),
                FlightRecorderData.LogMetadata(duration: .eightHours, startDate: Date(year: 2025, month: 3, day: 25)),
            ],
        )
        XCTAssertEqual(subject.nextLogLifecycleDate, Date(year: 2025, month: 4, day: 1, hour: 8))
    }

    /// `nextLogLifecycleDate` returns the date in which the first inactive log expires if that's
    /// before the active log needs to end logging.
    func test_nextLogLifecycleDate_inactiveLog() {
        let subject = FlightRecorderData(
            activeLog: FlightRecorderData.LogMetadata(
                duration: .eightHours,
                startDate: Date(year: 2025, month: 4, day: 1),
            ),
            inactiveLogs: [
                FlightRecorderData.LogMetadata(duration: .eightHours, startDate: Date(year: 2025, month: 1, day: 2)),
                FlightRecorderData.LogMetadata(duration: .eightHours, startDate: Date(year: 2025, month: 3, day: 4)),
            ],
        )
        XCTAssertEqual(subject.nextLogLifecycleDate, Date(year: 2025, month: 2, day: 1, hour: 8))
    }

    /// `nextLogLifecycleDate` returns an empty array if there's no logs.
    func test_nextLogLifecycleDate_noLogs() {
        let subject = FlightRecorderData()
        XCTAssertNil(subject.nextLogLifecycleDate)
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
        let log1 = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: Date(year: 2025, month: 1, day: 1))
        let log2 = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: Date(year: 2025, month: 1, day: 2))
        var subject = FlightRecorderData(activeLog: log2, inactiveLogs: [log1])

        let log3 = FlightRecorderData.LogMetadata(duration: .oneWeek, startDate: Date(year: 2025, month: 1, day: 3))
        subject.activeLog = log3

        XCTAssertEqual(subject, FlightRecorderData(activeLog: log3, inactiveLogs: [log2, log1]))
    }

    /// Using `activeLog` to modify a property of the active log doesn't make the log inactive.
    func test_setActiveLog_modifyExistingLogProperty() {
        var subject = FlightRecorderData()
        var log = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now)
        subject.activeLog = log

        subject.activeLog?.isBannerDismissed = true

        log.isBannerDismissed = true
        XCTAssertEqual(subject, FlightRecorderData(activeLog: log))
    }

    // MARK: FlightRecorderData.LogMetadata Tests

    /// `expirationDate` returns the date when the log will expire and be deleted.
    func test_logMetadata_expirationData() {
        XCTAssertEqual(
            FlightRecorderData.LogMetadata(
                duration: .oneHour,
                startDate: Date(year: 2025, month: 4, day: 3, hour: 10, minute: 30),
            ).expirationDate,
            Date(year: 2025, month: 5, day: 3, hour: 11, minute: 30),
        )
        XCTAssertEqual(
            FlightRecorderData.LogMetadata(
                duration: .eightHours,
                startDate: Date(year: 2025, month: 4, day: 3, hour: 10, minute: 30),
            ).expirationDate,
            Date(year: 2025, month: 5, day: 3, hour: 18, minute: 30),
        )
    }

    /// `formattedEndDate` returns the log's formatted end date.
    func test_logMetadata_formattedEndDate() {
        XCTAssertEqual(
            FlightRecorderData.LogMetadata(
                duration: .oneHour,
                startDate: Date(year: 2025, month: 4, day: 3, hour: 10, minute: 30),
            ).formattedEndDate,
            "4/3/25",
        )
        XCTAssertEqual(
            FlightRecorderData.LogMetadata(
                duration: .eightHours,
                startDate: Date(year: 2025, month: 4, day: 8, hour: 10, minute: 30),
            ).formattedEndDate,
            "4/8/25",
        )
    }

    /// `formattedEndDate` returns the log's formatted end time.
    func test_logMetadata_formattedEndTime() {
        XCTAssertEqual(
            FlightRecorderData.LogMetadata(
                duration: .oneHour,
                startDate: Date(year: 2025, month: 4, day: 8, hour: 10, minute: 30),
            ).formattedEndTime,
            "11:30 AM",
        )
        XCTAssertEqual(
            FlightRecorderData.LogMetadata(
                duration: .eightHours,
                startDate: Date(year: 2025, month: 4, day: 8, hour: 10, minute: 30),
            ).formattedEndTime,
            "6:30 PM",
        )
    }

    /// `id` returns the log's file name as a unique identifier.
    func test_logMetadata_id() {
        let log1 = FlightRecorderData.LogMetadata(duration: .oneHour, startDate: .now)
        XCTAssertEqual(log1.id, log1.fileName)

        let log2 = FlightRecorderData.LogMetadata(duration: .oneWeek, startDate: .now)
        XCTAssertEqual(log2.id, log2.fileName)
    }

    /// `init(duration:startDate:)` calculates the end date based on the start date and duration.
    func test_logMetadata_init_endDate() {
        let log1 = FlightRecorderData.LogMetadata(
            duration: .oneHour,
            startDate: Date(year: 2025, month: 4, day: 11, hour: 10, minute: 30, second: 20),
        )
        XCTAssertEqual(log1.endDate, Date(year: 2025, month: 4, day: 11, hour: 11, minute: 30, second: 20))

        let log2 = FlightRecorderData.LogMetadata(
            duration: .oneWeek,
            startDate: Date(year: 2025, month: 1, day: 2, hour: 3, minute: 4, second: 5),
        )
        XCTAssertEqual(log2.endDate, Date(year: 2025, month: 1, day: 9, hour: 3, minute: 4, second: 5))
    }

    /// `init(duration:startDate:)` creates a file name for the log based on the start date.
    func test_logMetadata_init_fileName() {
        let log1 = FlightRecorderData.LogMetadata(
            duration: .oneHour,
            startDate: Date(year: 2025, month: 4, day: 11, hour: 10, minute: 30, second: 20),
        )
        XCTAssertEqual(log1.fileName, "flight_recorder_2025-04-11-10-30-20.txt")

        let log2 = FlightRecorderData.LogMetadata(
            duration: .oneWeek,
            startDate: Date(year: 2025, month: 1, day: 2, hour: 3, minute: 4, second: 5),
        )
        XCTAssertEqual(log2.fileName, "flight_recorder_2025-01-02-03-04-05.txt")
    }
}
