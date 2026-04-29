// MARK: - IncomingLinksConstants

/// Links that are coming into our app via the "bitwarden://" deep link scheme.
///
enum BitwardenDeepLinkConstants {
    // MARK: Types

    /// Query parameter constants for the premium checkout result deep link.
    enum PremiumCheckoutResultQuery {
        /// The name of the query parameter that carries the checkout result.
        static let parameterName = "result"

        /// The value indicating the payment was completed successfully.
        static let successValue = "success"
    }

    // MARK: Properties

    /// Deep link to the Settings -> Account Security screen.
    static let accountSecurity = "bitwarden://settings/account_security"

    /// Deep link that tells the BWPM app to fetch a shared item from the Authenticator app and
    /// then present the Vault selection screen to save that item.
    static let authenticatorNewItem = "bitwarden://authenticator/newItem"

    /// The URL host for the premium checkout result deep link.
    static let premiumCheckoutResultHost = "premium-checkout-result"

    /// Base URL of the deep link used by the SSO cookie vendor flow. The browser redirects to this
    /// URL after acquiring cookies, passing each cookie as a URL query parameter.
    static let ssoCookieVendor = "bitwarden://sso-cookie-vendor"
}
