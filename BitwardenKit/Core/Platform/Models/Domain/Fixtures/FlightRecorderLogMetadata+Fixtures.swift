import Foundation

@testable import BitwardenKit

public extension FlightRecorderLogMetadata {
    // swiftlint:disable:next missing_docs
    static func fixture(
        duration: FlightRecorderLoggingDuration = .twentyFourHours,
        endDate: Date = Date(year: 2025, month: 4, day: 4),
        expirationDate: Date = Date(year: 2025, month: 5, day: 4),
        fileSize: String = "8 KB",
        id: String = "1",
        isActiveLog: Bool = false,
        startDate: Date = Date(year: 2025, month: 4, day: 3),
        url: URL = URL(string: "https://example.com")!,
    ) -> FlightRecorderLogMetadata {
        FlightRecorderLogMetadata(
            duration: duration,
            endDate: endDate,
            expirationDate: expirationDate,
            fileSize: fileSize,
            id: id,
            isActiveLog: isActiveLog,
            startDate: startDate,
            url: url,
        )
    }
}
