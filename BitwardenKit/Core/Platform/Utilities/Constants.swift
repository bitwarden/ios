import Foundation

/// A type alias for the client type.
public typealias ClientType = String

/// A type alias for the device type.
public typealias DeviceType = Int

// MARK: - Constants

/// Constant values reused throughout the app.
///
public enum Constants {
    /// The client type corresponding to the app.
    public static let clientType: ClientType = "mobile"

    /// The device type, iOS = 1.
    public static let deviceType: DeviceType = 1

    /// The number of days that a flight recorder log will remain on the device after the end date
    /// before being automatically deleted.
    static let flightRecorderLogExpirationDays = 30

    /// The minimum number of minutes before attempting a server config sync again.
    public static let minimumConfigSyncInterval: TimeInterval = 60 * 60 // 60 minutes

    /// The search debounce time in nanoseconds.
    public static let searchDebounceTimeInNS: UInt64 = 200_000_000 // 200ms

    /// The default file name when the file name cannot be determined.
    public static let unknownFileName = "unknown_file_name"
}
