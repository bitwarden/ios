import Foundation

// MARK: - ExternalLinksConstants

/// Links that are used throughout the app.
///
enum ExternalLinksConstants {
    // MARK: Properties

    /// A link to Bitwarden's organizations information webpage.
    static let aboutOrganizations = URL(string: "https://bitwarden.com/help/about-organizations")!

    /// A deep link to the Bitwarden app.
    static let appDeepLink = URL(string: "bitwarden://")!

    /// A link to the app review page within the app store.
    static let appReview = URL(string: "https://itunes.apple.com/us/app/id1137397744?action=write-review")

    /// A link to the auto fill help page.
    static let autofillHelp = URL(string: "https://bitwarden.com/help/auto-fill-ios/#keyboard-auto-fill")!

    /// A link to Bitwarden's help page for learning more about the account fingerprint phrase.
    static let fingerprintPhrase = URL(string: "https://bitwarden.com/help/fingerprint-phrase/")!

    /// A link the Bitwarden's help page for the flight recorder.
    static let flightRecorderHelp = URL(string: "https://bitwarden.com/help/flight-recorder")!

    /// A link to Bitwarden's help page for generating username types.
    static let generatorUsernameTypes = URL(string: "https://bitwarden.com/help/generator/#username-types")!

    /// A link to Bitwarden's general help and feedback page.
    static let helpAndFeedback = URL(string: "https://bitwarden.com/help/")!

    /// A link to the import logins help page.
    static let importHelp = URL(string: "https://bitwarden.com/help/import-data/")!

    /// A link to the new device verification help page.
    static let newDeviceVerification = URL(string: "https://bitwarden.com/help/new-device-verification/")!

    /// A link to the password options within the passwords section of the settings menu.
    static let passwordOptions = URL(string: "App-prefs:PASSWORDS&path=PASSWORD_OPTIONS")!

    /// A markdown link to Bitwarden's privacy policy.
    static let privacyPolicy = URL(string: "https://bitwarden.com/privacy/")!

    /// A markdown link to Bitwarden's help page about protecting individual items.
    static let protectIndividualItems = URL(
        string: "https://bitwarden.com/help/managing-items/#protect-individual-items"
    )!

    /// A link to Bitwarden's product page for Sends.
    static let sendInfo = URL(string: "https://bitwarden.com/products/send/")!

    /// A markdown link to Bitwarden's terms of service.
    static let termsOfService = URL(string: "https://bitwarden.com/terms/")!

    /// A markdown link to Bitwarden's markting email preferences.
    static let unsubscribeFromMarketingEmails = URL(string: "https://bitwarden.com/email-preferences/")!

    /// A link to Bitwarden's help page for showing website icons.
    static let websiteIconsHelp = URL(string: "https://bitwarden.com/help/website-icons/")!
}
