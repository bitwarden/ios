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

    /// Whether the account has been successfully created.
    var isAccountCreated: Bool = false

    /// The password field value.
    var password: String = ""

    /// The title of the screen.
    var title: String = Localizations.createAccountForm
}
