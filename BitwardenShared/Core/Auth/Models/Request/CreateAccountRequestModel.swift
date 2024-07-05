import Foundation
import Networking

// MARK: - CreateAccountRequestModel

/// The data to include in the body of a `CreateAccountRequest`.
///
struct CreateAccountRequestModel: Equatable {
    // MARK: Properties

    /// The captcha response used in validating a user for this request.
    let captchaResponse: String?

    /// The user's email address.
    let email: String

    /// The token to verify the email address
    let emailVerificationToken: String?

    /// The type of kdf for this request.
    var kdf: KdfType?

    /// The number of kdf iterations performed in this request.
    var kdfIterations: Int?

    /// The kdf memory allocated for the computed password hash.
    var kdfMemory: Int?

    /// The number of threads upon which the kdf iterations are performed.
    var kdfParallelism: Int?

    /// The key used for this request.
    let key: String

    /// The keys used for this request.
    let keys: KeysRequestModel

    /// The master password hash used to authenticate a user.
    let masterPasswordHash: String

    /// The master password hint.
    let masterPasswordHint: String?

    /// The user's name.
    let name: String?

    /// The organization's user ID.
    let organizationUserId: String?

    /// The token used when making this request.
    let token: String?

    // MARK: Initialization

    /// Initializes a `CreateAccountRequestModel`.
    ///
    /// - Parameters:
    ///   - captchaResponse: The captcha response used in validating a user for this request.
    ///   - email: The user's email address.
    ///   - kdfConfig: A model for configuring KDF options.
    ///   - key: The key used for this request.
    ///   - keys: The keys used for this request.
    ///   - masterPasswordHash: The master password hash used to authenticate a user.
    ///   - masterPasswordHint: The master password hint.
    ///   - name: The user's name.
    ///   - organizationUserId: The organization's user ID.
    ///   - token: The token used when making this request.
    ///
    init(
        captchaResponse: String? = nil,
        email: String,
        emailVerificationToken: String? = nil,
        kdfConfig: KdfConfig,
        key: String,
        keys: KeysRequestModel,
        masterPasswordHash: String,
        masterPasswordHint: String?,
        name: String? = nil,
        organizationUserId: String? = nil,
        token: String? = nil
    ) {
        self.captchaResponse = captchaResponse
        self.email = email
        self.emailVerificationToken = emailVerificationToken
        kdf = kdfConfig.kdf
        kdfIterations = kdfConfig.kdfIterations
        kdfMemory = kdfConfig.kdfMemory
        kdfParallelism = kdfConfig.kdfParallelism
        kdfMemory = kdfConfig.kdfMemory
        self.key = key
        self.keys = keys
        self.masterPasswordHash = masterPasswordHash
        self.masterPasswordHint = masterPasswordHint
        self.name = name
        self.organizationUserId = organizationUserId
        self.token = token
    }
}

// MARK: JSONRequestBody

extension CreateAccountRequestModel: JSONRequestBody {
    static let encoder = JSONEncoder()
}
