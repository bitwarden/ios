import Foundation
import Networking

// MARK: - CreateAccountRequestModel

/// The data to include in the body of a `CreateAccountRequest`.
///
struct CreateAccountRequestModel: Equatable {
    // MARK: Properties

    /// The captcha response used in validating a user for this request.
    let captchaResponse: String? = nil

    /// The user's email address.
    let email: String

    /// The type of kdf for this request.
    let kdf: KdfType? = nil

    /// The number of kdf iterations performed in this request.
    let kdfIterations: Int? = nil

    /// The kdf memory allocated for the computed password hash.
    let kdfMemory: Int? = nil

    /// The number of threads upon which the kdf iterations are performed.
    let kdfParallelism: Int? = nil

    /// The key used for this request.
    let key: String? = nil

    /// The keys used for this request.
    let keys: KeysRequestModel? = nil

    /// The master password hash used to authenticate a user.
    let masterPasswordHash: String

    /// The master password hint.
    let masterPasswordHint: String? = nil

    /// The user's name.
    let name: String? = nil

    /// The organization's user ID.
    let organizationUserId: String? = nil

    /// The token used when making this request.
    let token: String? = nil
}

// MARK: JSONRequestBody

extension CreateAccountRequestModel: JSONRequestBody {
    static var encoder: JSONEncoder {
        JSONEncoder()
    }
}
