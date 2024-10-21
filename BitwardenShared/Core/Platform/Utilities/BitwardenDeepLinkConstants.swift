// MARK: - IncomingLinksConstants

/// Links that are coming into our app via the "bitwarden://" deep link scheme.
///
enum BitwardenDeepLinkConstants {
    // MARK: Properties

    /// Deep link to the Settings -> Account Security screen.
    static let accountSecurity = "bitwarden://settings/account_security"

    /// Deep link that tells the PM app to fetch a shared item from the Authenticator app and
    /// then present the Vault selection screen to save that item.
    static let authenticatorNewItem = "bitwarden://authenticator/newItem"
}
