import Networking

// MARK: - PasswordHintRequestError

/// Errors that can occur when sending a `DeleteAccountRequest`.
enum PasswordHintRequestError: Error, Equatable {
    /// A validation error occurred when requesting a user's password hint.
    ///
    /// - Parameter errorResponse: The error response returned from the server.
    case serverError(_ errorResponse: ErrorResponseModel)
}

// MARK: - PasswordHintRequest

/// A request for requesting a user's password hint.
struct PasswordHintRequest: Request {
    typealias Response = EmptyResponse

    let body: PasswordHintRequestModel?

    let method: HTTPMethod = .post

    let path = "/accounts/password-hint"

    // MARK: Methods

    func validate(_ response: HTTPResponse) throws {
        switch response.statusCode {
        case 400 ..< 500:
            guard let errorResponse = try? ErrorResponseModel(response: response) else { return }
            throw PasswordHintRequestError.serverError(errorResponse)
        default:
            return
        }
    }
}
