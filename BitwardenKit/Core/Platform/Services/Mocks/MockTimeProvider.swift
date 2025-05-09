import BitwardenKit
import Foundation

public class MockTimeProvider {
    public enum TimeConfig {
        case currentTime
        case mockTime(Date)

        var date: Date {
            switch self {
            case .currentTime:
                return .now
            case let .mockTime(fixedDate):
                return fixedDate
            }
        }
    }

    public var timeConfig: TimeConfig

    public init(_ timeConfig: TimeConfig) {
        self.timeConfig = timeConfig
    }
}

extension MockTimeProvider: Equatable {
    public static func == (_: MockTimeProvider, _: MockTimeProvider) -> Bool {
        true
    }
}

extension MockTimeProvider: TimeProvider {
    public var presentTime: Date {
        timeConfig.date
    }

    public func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}
