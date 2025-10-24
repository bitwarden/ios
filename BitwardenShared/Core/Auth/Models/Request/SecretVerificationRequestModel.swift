import Foundation
import Networking

struct SecretVerificationRequestModel: JSONRequestBody, Equatable {
    // MARK: Properties

    let authRequestAccessCode: String?
    let masterPasswordHash: String?
    let otp: String?

    // MARK: Initializers

    init(accessCode: String) {
        authRequestAccessCode = accessCode
        masterPasswordHash = nil
        otp = nil
    }

    init(otp: String) {
        masterPasswordHash = nil
        self.otp = otp
        authRequestAccessCode = nil
    }

    init(passwordHash: String) {
        authRequestAccessCode = nil
        masterPasswordHash = passwordHash
        otp = nil
    }
}
