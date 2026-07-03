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

    /// The device was active this month (but not this or last week).
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
            Localizations.lastWeek
        case .overThirtyDaysAgo:
            Localizations.overThirtyDaysAgo
        case .thisMonth:
            Localizations.thisMonth
        case .thisWeek:
            Localizations.thisWeek
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

        // `.day` is always non-nil when explicitly requested via `dateComponents([.day]:)`;
        // the guard is defensive.
        guard let daysDifference = calendar.dateComponents([.day], from: date, to: now).day else {
            self = .unknown
            return
        }

        switch daysDifference {
        case 0:
            self = .today
        case 1 ... 7:
            self = .thisWeek
        case 8 ... 14:
            self = .lastWeek
        case 15 ... 30:
            self = .thisMonth
        default:
            self = .overThirtyDaysAgo
        }
    }
}
