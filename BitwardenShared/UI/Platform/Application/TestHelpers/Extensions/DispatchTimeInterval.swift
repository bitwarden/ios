import Foundation

extension DispatchTimeInterval: Comparable {
    /// The total number of nanoseconds in this duration.
    var totalNanoseconds: Int64 {
        switch self {
        case let .nanoseconds(value):
            return Int64(value)
        case let .microseconds(value):
            return Int64(value) * 1000
        case let .milliseconds(value):
            return Int64(value) * 1_000_000
        case let .seconds(value):
            return Int64(value) * 1_000_000_000
        case .never:
            fatalError("Infinite nanoseconds")
        @unknown default:
            fatalError("Unhandled case in DispatchTimeInterval")
        }
    }

    /// The total number of seconds in this duration.
    var totalSeconds: Double {
        switch self {
        case let .nanoseconds(value):
            return Double(value) / 1_000_000_000
        case let .microseconds(value):
            return Double(value) / 1_000_000
        case let .milliseconds(value):
            return Double(value) / 1000
        case let .seconds(value):
            return Double(value)
        case .never:
            fatalError("Infinite seconds")
        @unknown default:
            fatalError("Unhandled case in DispatchTimeInterval")
        }
    }

    public static func < (lhs: DispatchTimeInterval, rhs: DispatchTimeInterval) -> Bool {
        if lhs == .never {
            return false
        }
        if rhs == .never {
            return true
        }
        return lhs.totalNanoseconds < rhs.totalNanoseconds
    }
}
