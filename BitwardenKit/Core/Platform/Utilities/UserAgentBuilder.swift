import Foundation

/// Builds the standard Bitwarden user agent string from app and device information.
///
public struct UserAgentBuilder: Sendable {
    // MARK: Properties

    /// The app's name (e.g. `"Bitwarden_Mobile"`).
    let appName: String

    /// The app's version string.
    let appVersion: String

    /// The system device used to read OS and model info.
    let systemDevice: SystemDevice

    // MARK: Computed Properties

    /// The formatted user agent string.
    public var value: String {
        "\(appName)/\(appVersion)"
            + " (\(systemDevice.systemName) \(systemDevice.systemVersion);"
            + " Model \(systemDevice.model))"
    }

    // MARK: Initialization

    /// Initializes a `UserAgentBuilder`.
    ///
    /// - Parameters:
    ///   - appName: The app's name (e.g. `"Bitwarden_Mobile"`).
    ///   - appVersion: The app's version string.
    ///   - systemDevice: The system device used to read OS and model info.
    ///
    public init(appName: String, appVersion: String, systemDevice: SystemDevice) {
        self.appName = appName
        self.appVersion = appVersion
        self.systemDevice = systemDevice
    }
}
