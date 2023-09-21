typealias ClientType = String
typealias DeviceType = Int

// MARK: - Constants

/// Constant values reused throughout the app.
///
enum Constants {
    // MARK: Static Properties

    /// The client type corresponding to the app.
    static let clientType: ClientType = "mobile"

    /// The device type, iOS = 1.
    static let deviceType: DeviceType = 1

    /// A default value for the minimum number of characters required when creating a password.
    static let minimumPasswordCharacters: Int = 12
}
