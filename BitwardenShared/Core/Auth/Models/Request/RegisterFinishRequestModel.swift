import Foundation
import Networking

// MARK: - RegisterFinishRequestModel

/// The data to include in the body of a `RegisterFinishRequest`.
///
struct RegisterFinishRequestModel: Equatable {
    // MARK: Properties

    /// The user's email address.
    let email: String

    /// The token to verify the email address
    let emailVerificationToken: String

    /// The user's master password authentication data.
    let masterPasswordAuthentication: MasterPasswordAuthenticationDataRequestModel

    /// The master password hint.
    let masterPasswordHint: String?

    /// The user's master password unlock data.
    let masterPasswordUnlock: MasterPasswordUnlockDataRequestModel

    /// The user's name.
    let name: String? = nil

    /// The organization's user ID.
    let organizationUserId: String? = nil

    /// The token used when making this request.
    let token: String? = nil

    /// The user asymmetric keys used for this request.
    let userAsymmetricKeys: KeysRequestModel?
}

// MARK: JSONRequestBody

extension RegisterFinishRequestModel: JSONRequestBody {
    static let encoder = JSONEncoder()
}
