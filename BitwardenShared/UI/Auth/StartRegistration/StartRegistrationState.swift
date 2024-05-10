import SwiftUI

// MARK: - StartRegistrationState

/// An object that defines the current state of a `StartRegistrationView`.
///
struct StartRegistrationState: Equatable {
    // MARK: Properties

    /// The text in the email text field.
    var emailText: String = ""

    /// Whether the terms and privacy toggle is on.
    var isTermsAndPrivacyToggleOn: Bool = false

    /// The text in the name text field.
    var nameText: String = ""

    /// The region selected by the user.
    var region: RegionType = .europe

    /// A toast message to show in the view.
    var toast: Toast?
}
