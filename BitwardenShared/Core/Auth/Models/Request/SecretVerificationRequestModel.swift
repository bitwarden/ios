import Foundation
import Networking

/// A model that holds data proving that the client knows the user's secret.
struct SecretVerificationRequestModel: JSONRequestBody, Equatable {
    // MARK: Properties

    let authRequestAccessCode: String?
    let masterPasswordHash: String?
    let otp: String?

    // MARK: Initializers

    init(authRequestAccessCode accessCode: String) {
        authRequestAccessCode = accessCode
        masterPasswordHash = nil
        otp = nil
    }

    init(otp code: String) {
        authRequestAccessCode = nil
        masterPasswordHash = nil
        otp = code
    }

    init(masterPasswordHash passwordHash: String) {
        authRequestAccessCode = nil
        masterPasswordHash = passwordHash
        otp = nil
    }
}
