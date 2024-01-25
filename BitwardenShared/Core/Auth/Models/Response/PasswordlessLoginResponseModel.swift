import Foundation
import Networking

// MARK: - PasswordlessLoginResponseModel

/// The response from a `PasswordlessLoginRequest`.
///
struct PasswordlessLoginResponseModel: Equatable, JSONResponse {
    // MARK: Static Properties

    static let decoder = JSONDecoder()

    /// The request creation date.
    var creationDate: String

    /// The response ID.
    var id: String

    /// The key returned from the request.
    var key: String?

    /// The public key returned from the request.
    var publicKey: String

    /// The master password hash.
    var masterPasswordHash: String?

    /// The request being sent.
    var object: String

    /// The domain of the authentication source.
    var origin: String

    /// The date of the response.
    var responseDate: String?

    /// Whether the request was approved.
    var requestApproved: Bool

    /// The type of device the request was made on.
    var requestDeviceType: String

    /// The IP address the request was made from.
    var requestIpAddress: String

    // MARK: Initialization

    /// Initialize a `PasswordlessLoginResponseModel`.
    ///
    /// - Parameters:
    ///   - object: The request being sent.
    ///   - id: The response ID.
    ///   - publicKey: The public key returned from the request.
    ///   - requestDeviceType: The type of device the request was made on.
    ///   - requestIpAddress: The IP address the request was made from.
    ///   - key: The key returned from the request.
    ///   - masterPasswordHash: The master password hash.
    ///   - creationDate: The request creation date.
    ///   - responseDate: The date of the response.
    ///   - requestApproved: Whether the request was approved.
    ///   - origin: The domain of the authentication source.
    ///
    init(
        object: String,
        id: String,
        publicKey: String,
        requestDeviceType: String,
        requestIpAddress: String,
        key: String?,
        masterPasswordHash: String?,
        creationDate: String,
        responseDate: String?,
        requestApproved: Bool,
        origin: String
    ) {
        self.creationDate = creationDate
        self.id = id
        self.key = key
        self.publicKey = publicKey
        self.masterPasswordHash = masterPasswordHash
        self.object = object
        self.origin = origin
        self.responseDate = responseDate
        self.requestApproved = requestApproved
        self.requestDeviceType = requestDeviceType
        self.requestIpAddress = requestIpAddress
    }
}
