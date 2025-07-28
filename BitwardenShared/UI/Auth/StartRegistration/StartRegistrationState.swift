import BitwardenKit
import BitwardenResources
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

    /// The text in the receive marketing emails toggle
    var receiveMarketingEmailsText: String {
        Localizations.getAdviceAnnouncementsAndResearchOpportunitiesFromBitwardenInYourInboxUnsubscribeAtAnyTime(
            ExternalLinksConstants.unsubscribeFromMarketingEmails
        )
    }

    /// The region selected by the user.
    var region: RegionType = .europe

    /// The value which determines if the toggle is shown
    var showReceiveMarketingToggle = true

    /// Terms and privacy disclaimer text
    var termsAndPrivacyDisclaimerText: String {
        Localizations.byContinuingYouAgreeToTheTermsOfServiceAndPrivacyPolicy(
            ExternalLinksConstants.termsOfService,
            ExternalLinksConstants.privacyPolicy
        )
    }

    /// A toast message to show in the view.
    var toast: Toast?
}
