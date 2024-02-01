import Networking

// MARK: - AccountRevisionDateRequest

/// Data model for fetching the account's last revision date.
///
struct AccountRevisionDateRequest: Request {
    typealias Response = AccountRevisionDateResponseModel

    /// The HTTP method for this request.
    let method = HTTPMethod.get

    /// The URL path for this request.
    let path = "/accounts/revision-date"
}
