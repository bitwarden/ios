import Networking

// MARK: - PasswordHintRequest

/// A request for requesting a user's password hint.
struct PasswordHintRequest: Request {
    typealias Response = EmptyResponse

    let body: PasswordHintRequestModel?

    let method: HTTPMethod = .post

    let path = "/accounts/password-hint"
}
