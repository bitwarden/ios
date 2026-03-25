import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - DeviceActivityStatus

/// An enumeration representing the activity status of a device based on its last activity date.
///
enum DeviceActivityStatus: Equatable, Sendable {
    /// The device was active today.
    case today

    /// The device was active this week (but not today).
    case thisWeek

    /// The device was active last week.
    case lastWeek

    /// The device was active this month (but not this or last week).
    case thisMonth

    /// The device was active over 30 days ago.
    case overThirtyDaysAgo

    /// The device's activity status is unknown.
    case unknown

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
        let calendar = Calendar.current

        guard let daysDifference = calendar.dateComponents([.day], from: date, to: now).day else {
            self = .unknown
            return
        }

        switch daysDifference {
        case ...0:
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

    // MARK: Properties

    /// The localized display string for the activity status.
    var localizedString: String {
        switch self {
        case .today:
            Localizations.today
        case .thisWeek:
            Localizations.thisWeek
        case .lastWeek:
            Localizations.lastWeek
        case .thisMonth:
            Localizations.thisMonth
        case .overThirtyDaysAgo:
            Localizations.overThirtyDaysAgo
        case .unknown:
            Localizations.unknown
        }
    }
}
