import BitwardenKit
import Foundation

public class MockTimeProvider: TimeProvider {
    public enum TimeConfig {
        case currentTime
        case mockTime(Date, TimeInterval = 0)

        var date: Date {
            switch self {
            case .currentTime:
                .now
            case let .mockTime(fixedDate, _):
                fixedDate
            }
        }

        var monotonicTime: TimeInterval {
            switch self {
            case .currentTime:
                0
            case let .mockTime(_, fixedMonotonicTime):
                fixedMonotonicTime
            }
        }
    }

    public var calculateTamperResistantElapsedTimeResult = TamperResistantTimeResult(
        // swiftlint:disable:previous identifier_name
        divergence: 0,
        effectiveElapsed: 10,
        elapsedMonotonic: 10,
        elapsedWallClock: 10,
        tamperingDetected: false,
    )

    public var monotonicTime: TimeInterval {
        timeConfig.monotonicTime
    }

    public var timeConfig: TimeConfig

    public var presentTime: Date {
        timeConfig.date
    }

    public init(_ timeConfig: TimeConfig) {
        self.timeConfig = timeConfig
    }

    public func calculateTamperResistantElapsedTime(
        lastMonotonicTime: TimeInterval,
        lastWallClockTime: Date,
        divergenceThreshold: TimeInterval,
    ) -> TamperResistantTimeResult {
        calculateTamperResistantElapsedTimeResult
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
