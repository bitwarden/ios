import SwiftUI

// MARK: - CheckEmailState

/// An object that defines the current state of a `CheckEmailView`.
///
struct CheckEmailState: Equatable {
    // MARK: Properties

    /// User's email address.
    var email: String = "example@email.com"

    var headelineTextBoldEmail: String {
        let text = Localizations.followTheInstructionsInTheEmailSentToXToContinueCreatingYourAccount(email)
        return text.replacingOccurrences(of: email, with: "**\(email)**")
    }

    var goBackText: String {
        let text = Localizations.noEmailGoBackToEditYourEmailAddress
        return text.replacingOccurrences(of: Localizations.goBack, with: "**[\(Localizations.goBack)](https://)**")
    }

    var logInText: String {
        let text = Localizations.orLogInYouMayAlreadyHaveAnAccount
        return text.replacingOccurrences(of: Localizations.logIn, with: "**[\(Localizations.logIn)](https://)**")
    }
}
