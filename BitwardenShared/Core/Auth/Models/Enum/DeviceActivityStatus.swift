import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - DeviceActivityStatus

/// An enumeration representing the activity status of a device based on its last activity date.
///
enum DeviceActivityStatus: Equatable, Sendable {
    /// The device was active last week.
    case lastWeek

    /// The device was active over 30 days ago.
    case overThirtyDaysAgo

    /// The device was active 14 to 29 days ago (but not this or last week).
    case thisMonth

    /// The device was active this week (but not today).
    case thisWeek

    /// The device was active today.
    case today

    /// The device's activity status is unknown.
    case unknown

    // MARK: Properties

    /// The localized display string for the activity status.
    var localizedString: String {
        switch self {
        case .lastWeek:
            Localizations.pastFourteenDays
        case .overThirtyDaysAgo:
            Localizations.overThirtyDaysAgo
        case .thisMonth:
            Localizations.pastThirtyDays
        case .thisWeek:
            Localizations.pastSevenDays
        case .today:
            Localizations.today
        case .unknown:
            Localizations.unknown
        }
    }

    // MARK: Initialization

    /// Initializes a `DeviceActivityStatus` from an optional date.
    ///
    /// - Parameters:
    ///   - date: The last activity date of the device.
    ///   - timeProvider: The time provider to use for calculating the status.
    ///
    init(from date: Date?, timeProvider: TimeProvider) {
        guard let date else {
            self = .unknown
            return
        }

        let now = timeProvider.presentTime

        guard date <= now else {
            self = .unknown
            return
        }

        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)
        let startOfToday = calendar.startOfDay(for: now)

        // `.day` is always non-nil when explicitly requested via `dateComponents([.day]:)`;
        // the guard is defensive.
        guard let daysDifference = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day else {
            self = .unknown
            return
        }

        // Bucket boundaries mirror the Android app's day-count logic exactly, so both platforms
        // show identical "last active" labels for the same date.
        switch daysDifference {
        case 0:
            self = .today
        case 1 ..< 7:
            self = .thisWeek
        case 7 ..< 14:
            self = .lastWeek
        case 14 ..< 30:
            self = .thisMonth
        default:
            self = .overThirtyDaysAgo
        }
    }
}
