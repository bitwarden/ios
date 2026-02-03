import BitwardenKit
import Foundation

public class MockTimeProvider: TimeProvider {
    public enum TimeConfig {
        case currentTime
        case mockTime(Date)

        var date: Date {
            switch self {
            case .currentTime:
                .now
            case let .mockTime(fixedDate):
                fixedDate
            }
        }
    }

    public var timeConfig: TimeConfig
    public var monotonicTime: TimeInterval

    public var presentTime: Date {
        timeConfig.date
    }

    public init(_ timeConfig: TimeConfig, monotonicTime: TimeInterval = 0) {
        self.timeConfig = timeConfig
        self.monotonicTime = monotonicTime
    }

    public func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}

extension MockTimeProvider: Equatable {
    public static func == (_: MockTimeProvider, _: MockTimeProvider) -> Bool {
        true
    }
}
