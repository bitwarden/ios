import Foundation

@testable import BitwardenShared

extension FlightRecorderLogMetadata {
    static func fixture(
        duration: FlightRecorderLoggingDuration,
        fileSize: String = "8 KB",
        id: String = "1",
        startDate: Date = Date(year: 2025, month: 4, day: 3)
    ) -> FlightRecorderLogMetadata {
        FlightRecorderLogMetadata(
            duration: duration,
            fileSize: fileSize,
            id: id,
            startDate: startDate
        )
    }
}
