// MARK: - PasswordHintState

/// An object that defines the current state of a `PasswordHintView`.
///
struct PasswordHintState: Equatable {
    // MARK: Properties

    /// The email address provided by the user on the landing screen.
    var emailAddress: String = ""

    /// A flag indicating if the submit button is enabled or not.
    var isSubmitButtonEnabled: Bool { !emailAddress.isEmpty }
}
