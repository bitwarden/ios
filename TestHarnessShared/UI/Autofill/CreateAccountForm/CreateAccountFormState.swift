import Foundation

/// The state for the create account form test screen.
///
struct CreateAccountFormState: Equatable {
    // MARK: Properties

    /// The confirm password field value.
    var confirmPassword: String = ""

    /// The email field value.
    var email: String = ""

    /// An error message to display when form validation fails.
    var errorMessage: String?

    /// Increments on each successful account creation. Observed by the view to resign focus and
    /// trigger the credential-provider save prompt on every submission, not just the first.
    var accountCreationCount: Int = 0

    /// Whether the account has been successfully created at least once.
    var isAccountCreated: Bool { accountCreationCount > 0 }

    /// The password field value.
    var password: String = ""

    /// The title of the screen.
    var title: String = Localizations.createAccountForm
}
