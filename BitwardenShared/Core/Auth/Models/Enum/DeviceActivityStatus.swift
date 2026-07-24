import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - DeviceActivityStatus

/// An enumeration representing the activity status of a device based on its last activity date.
///
enum DeviceActivityStatus: Equatable, Sendable {
    /// The device was active over 30 days ago.
    case overThirtyDaysAgo

    /// The device was active 7 to 13 days ago.
    case pastFourteenDays

    /// The device was active 1 to 6 days ago (but not today).
    case pastSevenDays

    /// The device was active 14 to 29 days ago.
    case pastThirtyDays

    /// The device was active today.
    case today

    /// The device's activity status is unknown.
    case unknown

    // MARK: Properties

    /// The localized display string for the activity status.
    var localizedString: String {
        switch self {
        case .overThirtyDaysAgo:
            Localizations.overThirtyDaysAgo
        case .pastFourteenDays:
            Localizations.pastFourteenDays
        case .pastSevenDays:
            Localizations.pastSevenDays
        case .pastThirtyDays:
            Localizations.pastThirtyDays
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

        switch daysDifference {
        case 0:
            self = .today
        case 1 ..< 7:
            self = .pastSevenDays
        case 7 ..< 14:
            self = .pastFourteenDays
        case 14 ..< 30:
            self = .pastThirtyDays
        default:
            self = .overThirtyDaysAgo
        }
    }
}
