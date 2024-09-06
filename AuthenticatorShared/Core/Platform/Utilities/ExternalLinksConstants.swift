import Foundation

// MARK: - ExternalLinksConstants

/// Links that are used throughout the app.
///
enum ExternalLinksConstants {
    // MARK: Properties

    /// A link to Bitwarden's organizations information webpage.
    static let aboutOrganizations = URL(string: "https://bitwarden.com/help/about-organizations")!

    /// A link to the app review page within the app store.
    static let appReview = URL(string: "https://itunes.apple.com/us/app/id1137397744?action=write-review")

    static let backupInformation = URL(string: "https://support.apple.com/guide/iphone/back-up-iphone-iph3ecf67d29/ios")

    /// A link to Bitwarden's help page for learning more about the account fingerprint phrase.
    static let fingerprintPhrase = URL(string: "https://bitwarden.com/help/fingerprint-phrase/")!

    /// A link to Bitwarden's help page for generating username types.
    static let generatorUsernameTypes = URL(string: "https://bitwarden.com/help/generator/#username-types")!

    /// A link for beta users to provide feedback.
    static let giveFeedback = URL(string: "https://livefrontinc.typeform.com/to/irgrRu4a")

    /// A link to Bitwarden's general help and feedback page.
    static let helpAndFeedback = URL(string: "http://bitwarden.com/help/")!

    /// A link to Bitwarden's import items help webpage.
    static let importItems = URL(string: "http://bitwarden.com/help/import-data/")!

    /// A link to the password manager app within the app store.
    static let passwordManagerLink = URL(string: "https://itunes.apple.com/app/id1137397744?mt=8")!

    /// The url scheme used by the password manager app
    static let passwordManagerScheme = URL(string: "bitwarden://")!

    /// A deeplink used by the password manager app to open the options menu.
    static let passwordManagerSettings = URL(string: "bitwarden://sync_authenticator?options=true")!

    /// A markdown link to Bitwarden's privacy policy.
    static let privacyPolicy = URL(string: "https://bitwarden.com/privacy/")!

    /// A markdown link to Bitwarden's help page about protecting individual items.
    static let protectIndividualItems = URL(
        string: "https://bitwarden.com/help/managing-items/#protect-individual-items"
    )!

    /// A link to Bitwarden's recovery code help page.
    static let recoveryCode = URL(string: "https://bitwarden.com/help/lost-two-step-device/")!

    /// A link to Bitwarden's product page for Sends.
    static let sendInfo = URL(string: "https://bitwarden.com/products/send/")!

    /// A markdown link to Bitwarden's terms of service.
    static let termsOfService = URL(string: "https://bitwarden.com/terms/")!
}
