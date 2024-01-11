// MARK: - SingleSignOnEffect

/// Effects handled by the `SingleSignOnProcessor`.
///
enum SingleSignOnEffect {
    /// Load the single sign on details for the user.
    case loadSingleSignOnDetails

    /// The login button was tapped.
    case loginTapped
}
