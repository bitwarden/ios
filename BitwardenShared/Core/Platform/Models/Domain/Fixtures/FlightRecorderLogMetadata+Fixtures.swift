import Foundation

@testable import BitwardenShared

extension FlightRecorderLogMetadata {
    static func fixture(
        duration: FlightRecorderLoggingDuration = .twentyFourHours,
        endDate: Date = Date(year: 2025, month: 4, day: 3, hour: 1),
        fileSize: String = "8 KB",
        id: String = "1",
        isActiveLog: Bool = false,
        startDate: Date = Date(year: 2025, month: 4, day: 3),
        url: URL = URL(string: "https://example.com")!
    ) -> FlightRecorderLogMetadata {
        FlightRecorderLogMetadata(
            duration: duration,
            endDate: endDate,
            fileSize: fileSize,
            id: id,
            isActiveLog: isActiveLog,
            startDate: startDate,
            url: url
        )
    }
}
