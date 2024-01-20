import Foundation
import Networking

// MARK: - LoginRequest

/// A data structure representing a login request.
///
public struct LoginRequest: JSONResponse, Equatable {
    public static var decoder = JSONDecoder.defaultDecoder

    // MARK: Properties

    /// The creation date of the login request.
    let creationDate: Date

    /// The fingerprint phrase of the login request.
    var fingerprintPhrase: String?

    /// The id of the login request.
    public let id: String

    /// The key of the login request.
    let key: String?

    /// The origin of the login request.
    let origin: String

    /// The public key of the login request.
    let publicKey: String

    /// The access code of the login request.
    let requestAccessCode: String?

    /// Whether the login request has been approved.
    let requestApproved: Bool?

    /// The device of the login request, eg 'iOS'.
    let requestDeviceType: String

    /// The IP address of the request.
    let requestIpAddress: String

    /// The response date, if the login request has already been approved or denied.
    let responseDate: Date?

    /// The master password hash of the login request.
    let masterPasswordHash: String?
}

extension LoginRequest: Identifiable {}

extension LoginRequest: Hashable {}
