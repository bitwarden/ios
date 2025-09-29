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

    /// The minimum number of minutes before attempting a server config sync again.
    public static let minimumConfigSyncInterval: TimeInterval = 60 * 60 // 60 minutes

    /// The default file name when the file name cannot be determined.
    public static let unknownFileName = "unknown_file_name"
}
