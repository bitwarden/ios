import SwiftUI

// MARK: - StartRegistrationState

/// An object that defines the current state of a `StartRegistrationView`.
///
struct StartRegistrationState: Equatable {
    // MARK: Properties

    /// The text in the email text field.
    var emailText: String = ""

    /// Whether the terms and privacy toggle is on.
    var isReceiveMarketingToggleOn: Bool = false

    /// The text in the name text field.
    var nameText: String = ""

    /// The region selected by the user.
    var region: RegionType = .europe

    /// Terms and privacy disclaimer text
    var termsAndPrivacyDisclaimerText: String {
        Localizations.byContinuingYouAgreeToTheTermsOfServiceAndPrivacyPolicy
            .replacingOccurrences(
                of: Localizations.termsOfService,
                with: "**[\(Localizations.termsOfService)](\(ExternalLinksConstants.termsOfService))**"
            )
            .replacingOccurrences(
                of: Localizations.privacyPolicy,
                with: "**[\(Localizations.privacyPolicy)](\(ExternalLinksConstants.privacyPolicy))**"
            )
    }

    var receiveMarketingEmailsText: String {
        Localizations.getEmailsFromBitwardenForAnnouncementsAdviceAndResearchOpportunitiesUnsubscribeAtAnyTime
            .replacingOccurrences(
                of: Localizations.unsubscribe,
                with: "**[\(Localizations.unsubscribe)](\(ExternalLinksConstants.unsubscribe))**"
            )
    }

    /// A toast message to show in the view.
    var toast: Toast?
}
