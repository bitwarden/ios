import Networking

// MARK: - ConfigRequest

/// Data model for fetching the configuration for an account.
///
struct ConfigRequest: Request {
    typealias Response = ConfigResponseModel

    let method = HTTPMethod.get

    let path = "/config"
}
