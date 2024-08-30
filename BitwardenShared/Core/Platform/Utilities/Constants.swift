import Foundation

typealias ClientType = String
typealias DeviceType = Int

// MARK: - Constants

/// Constant values reused throughout the app.
///
enum Constants {
    // MARK: Static Properties

    /// The minimum server version required to have cipher key encryption on.
    static let cipherKeyEncryptionMinServerVersion = "2024.2.0"

    /// The client type corresponding to the app.
    static let clientType: ClientType = "mobile"

    /// The default type for a Fido2 public key credential.
    static let defaultFido2PublicKeyCredentialType = "public-key"

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

    /// The value representing 10 MB of data.
    static let largeFileSize = 10_485_760

    /// The number of minutes until a login request expires.
    static let loginRequestTimeoutMinutes = 15

    /// The maximum number of accounts permitted for a user.
    static let maxAccounts = 5

    /// The maximum amount of KDF memory that can be used to unlock the user's vault in an app
    /// extension before the app should warn the user that the extension may hit its memory limit.
    static let maxArgon2IdMemoryBeforeExtensionCrashing = 64

    /// The value representing 100 MB of data.
    static let maxFileSize = 104_857_600

    /// The maximum number of passwords stored in history.
    static let maxPasswordsInHistory = 100

    /// The maximum size of files for upload.
    static let maxFileSizeBytes = 104_857_600

    /// The maximum number of unsuccessful attempts the user can make to unlock
    static let maxUnlockUnsuccessfulAttempts = 5

    /// THe minimum number of minutes before attempting a server config sync again.
    static let minimumConfigSyncInterval: TimeInterval = 60 * 60 // 60 minutes

    /// A default value for the minimum number of characters required when creating a password.
    static let minimumPasswordCharacters = 12

    /// The minimum number of minutes before allowing the vault to sync again.
    static let minimumSyncInterval: TimeInterval = 30 * 60 // 30 minutes

    /// The minimum number of cipher items without folder
    static let noFolderListSize = 100

    /// The default number of KDF iterations to perform.
    static let pbkdf2Iterations = 600_000

    /// The default file name when the file name cannot be determined.
    static let unknownFileName = "unknown_file_name"
}

// MARK: Extension Constants

extension Constants {
    /// Uniform type identifier constants used by the app.
    ///
    enum UTType {
        /// A type identifier for the app extension change password action.
        static let appExtensionChangePasswordAction = "org.appextension.change-password-action"

        /// A type identifier for the app extension fill browser action.
        static let appExtensionFillBrowserAction = "org.appextension.fill-browser-action"

        /// A type identifier for the app extension fill webview action.
        static let appExtensionFillWebViewAction = "org.appextension.fill-webview-action"

        /// A type identifier for the app extension find login action.
        static let appExtensionFindLoginAction = "org.appextension.find-login-action"

        /// A type identifier for the app extension save login action.
        static let appExtensionSaveLogin = "org.appextension.save-login-action"

        /// A type identifier for the app extension setup.
        static let appExtensionSetup = "com.8bit.bitwarden.extension-setup"
    }

    /// An app extension key for notes for a login.
    static let appExtensionNotesKey = "notes"

    /// An app extension key for the previous password when changing a password.
    static let appExtensionOldPasswordKey = "old_password"

    /// An app extension key for password generator options.
    static let appExtensionPasswordGeneratorOptionsKey = "password_generator_options"

    /// An app extension key for a password.
    static let appExtensionPasswordKey = "password"

    /// An app extension key for a login title.
    static let appExtensionTitleKey = "login_title"

    /// An app extension key for the autofill URL.
    static let appExtensionUrlStringKey = "url_string"

    /// An app extension key for a username.
    static let appExtensionUsernameKey = "username"

    /// An app extension key for the page details JSON.
    static let appExtensionWebViewPageDetails = "pageDetails"

    /// An app extension key for the fill script JSON.
    static let appExtensionWebViewPageFillScript = "fillScript"
}
