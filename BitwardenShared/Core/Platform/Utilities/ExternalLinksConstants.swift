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

    /// A link to Bitwarden's help page for learning more about the account fingerprint phrase.
    static let fingerprintPhrase = URL(string: "https://bitwarden.com/help/fingerprint-phrase/")!

    /// A link to Bitwarden's help page for generating username types.
    static let generatorUsernameTypes = URL(string: "https://bitwarden.com/help/generator/#username-types")!

    /// A link to Bitwarden's general help and feedback page.
    static let helpAndFeedback = URL(string: "http://bitwarden.com/help/")!

    /// A link to Bitwarden's import items help webpage.
    static let importItems = URL(string: "http://bitwarden.com/help/import-data/")!

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
