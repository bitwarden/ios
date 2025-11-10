import BitwardenKit
import Foundation

// MARK: - ExternalLinksConstants

/// Links that are used throughout the app.
///
extension ExternalLinksConstants {
    // MARK: Properties

    /// A link to Apple's guide on backing up iPhone.
    static let backupInformation = URL(
        string: "https://support.apple.com/guide/iphone/back-up-iphone-iph3ecf67d29/ios",
    )!

    /// A link to the password manager app within the app store.
    static let passwordManagerLink = URL(string: "https://itunes.apple.com/app/id1137397744?mt=8")!

    /// A deeplink to the password manager app to open the BWPM app and let it know there's a new item to store.
    static let passwordManagerNewItem = URL(string: "bitwarden://authenticator/newItem")!

    /// The url scheme used by the password manager app
    static let passwordManagerScheme = URL(string: "bitwarden://")!

    /// A deeplink to the password manager app to open the options menu.
    static let passwordManagerSettings = URL(string: "bitwarden://settings/account_security")!

    /// A link to the Bitwarden Help Center page for syncing TOTP codes between PM and Authenticator.
    static let totpSyncHelp = URL(string: "https://bitwarden.com/help/totp-sync/")!
}
