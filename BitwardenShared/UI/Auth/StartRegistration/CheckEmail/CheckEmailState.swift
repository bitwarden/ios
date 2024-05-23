import SwiftUI

// MARK: - CheckEmailState

/// An object that defines the current state of a `CheckEmailView`.
///
struct CheckEmailState: Equatable {
    // MARK: Properties

    /// User's email address.
    var email: String = ""

    // MARK: Computed Properties

    /// Text with words go back action highlighted
    var goBackText: String {
        let text = Localizations.noEmailGoBackToEditYourEmailAddress
        return text.replacingOccurrences(of: Localizations.goBack, with: "**[\(Localizations.goBack)](https://)**")
    }

    /// Text with user email in bold
    var headelineTextBoldEmail: String {
        Localizations.followTheInstructionsInTheEmailSentToXToContinueCreatingYourAccount("**\(email)**")
    }

    /// Text with words log in action highlighted
    var logInText: String {
        let text = Localizations.orLogInYouMayAlreadyHaveAnAccount
        return text.replacingOccurrences(of: Localizations.logIn, with: "**[\(Localizations.logIn)](https://)**")
    }
}
