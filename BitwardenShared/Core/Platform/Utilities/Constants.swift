import Foundation

typealias ClientType = String
typealias DeviceType = Int

// MARK: - Constants

/// Constant values reused throughout the app.
///
enum Constants {
    // MARK: Static Properties

    /// The client type corresponding to the app.
    static let clientType: ClientType = "mobile"

    /// The default generated username if there isn't enough information to generate a username.
    static let defaultGeneratedUsername = "-"

    /// The URL for the web vault if the user account doesn't have one specified.
    static let defaultWebVaultHost = "bitwarden.com"

    /// The device type, iOS = 1.
    static let deviceType: DeviceType = 1

    /// The length of a masked password.
    static let hiddenPasswordLength = 8

    /// A custom URL scheme to support action extension autofill from other apps.
    static let iOSAppProtocol = "iosapp://"

    /// A default value for the argon memory argument in the KDF algorithm.
    static let kdfArgonMemory = 64

    /// A default value for the argon parallelism argument in the KDF algorithm.
    static let kdfArgonParallelism = 4

    /// The number of minutes until a login request expires.
    static let loginRequestTimeoutMinutes = 15

    /// The maximum number of accounts permitted for a user.
    static let maxAccounts: Int = 5

    /// The maximum number of passwords stored in history.
    static let maxPasswordsInHistory = 100

    /// A default value for the minimum number of characters required when creating a password.
    static let minimumPasswordCharacters: Int = 12

    /// The default number of KDF iterations to perform.
    static let pbkdf2Iterations: Int = 600_000

    /// The default file name when the file name cannot be determined.
    static let unknownFileName: String = "unknown_file_name"
}
