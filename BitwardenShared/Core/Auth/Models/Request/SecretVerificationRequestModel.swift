import Foundation
import Networking

/// A model that holds data proving that the client knows the user's secret.
struct SecretVerificationRequestModel: JSONRequestBody, Equatable {
    /// The type of secret verification being performed.
    enum SecretVerificationRequestType: Codable, Equatable, Hashable, Sendable {
        /// Verification using an authentication request access code.
        case authRequestAccessCode(String)

        /// Verification using the hash of the user's master password.
        case masterPasswordHash(String)

        /// Verification using a one-time password code.
        case otp(String)
    }

    // MARK: Properties

    /// The access code from an authentication request.
    let authRequestAccessCode: String?

    /// The hash of the user's master password.
    let masterPasswordHash: String?

    /// The one-time password code.
    let otp: String?

    // MARK: Initializers

    /// Creates a new secret verification request model from the specified verification type.
    ///
    /// - Parameters:
    ///   - type: The type of secret verification to perform.
    ///
    init(type: SecretVerificationRequestType) {
        switch type {
        case let .authRequestAccessCode(accessCode):
            authRequestAccessCode = accessCode
            masterPasswordHash = nil
            otp = nil
        case let .masterPasswordHash(passwordHash):
            authRequestAccessCode = nil
            masterPasswordHash = passwordHash
            otp = nil
        case let .otp(code):
            authRequestAccessCode = nil
            masterPasswordHash = nil
            otp = code
        }
    }
}
