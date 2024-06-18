import Networking

// MARK: - ConfigRequest

/// Data model for fetching configuration values from the server.
///
struct ConfigRequest: Request {
    typealias Response = ConfigResponseModel

    let method = HTTPMethod.get

    let path = "/config"
}
