import Networking

// MARK: - ConfigRequest

/// Data model for fetching configuration values from the server.
///
public struct ConfigRequest: Request {
    public typealias Response = ConfigResponseModel

    public let method = HTTPMethod.get

    public let path = "/config"

    public init() {}
}
