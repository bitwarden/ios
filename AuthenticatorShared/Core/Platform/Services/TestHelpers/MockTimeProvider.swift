import Foundation

@testable import AuthenticatorShared

class MockTimeProvider {
    enum TimeConfig {
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

    var timeConfig: TimeConfig

    init(_ timeConfig: TimeConfig) {
        self.timeConfig = timeConfig
    }
}

extension MockTimeProvider: Equatable {
    static func == (_: MockTimeProvider, _: MockTimeProvider) -> Bool {
        true
    }
}

extension MockTimeProvider: TimeProvider {
    var presentTime: Date {
        timeConfig.date
    }

    func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}
