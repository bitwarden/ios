// MARK: - LoginRequestState

/// The state used to present the `LoginRequestView`.
struct LoginRequestState: Equatable {
    /// The user's email.
    var email: String?

    /// The login request to display.
    var request: LoginRequest
}
