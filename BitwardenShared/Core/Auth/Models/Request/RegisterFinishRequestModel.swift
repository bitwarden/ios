import Foundation
import Networking

// MARK: - RegisterFinishRequestModel

/// The data to include in the body of a `RegisterFinishRequest`.
///
struct RegisterFinishRequestModel: Equatable {
    // MARK: Properties

    /// The captcha response used in validating a user for this request.
    let captchaResponse: String?

    /// The user's email address.
    let email: String

    /// The token to verify the email address
    let emailVerificationToken: String

    /// The type of kdf for this request.
    var kdf: KdfType?

    /// The number of kdf iterations performed in this request.
    var kdfIterations: Int?

    /// The kdf memory allocated for the computed password hash.
    var kdfMemory: Int?

    /// The number of threads upon which the kdf iterations are performed.
    var kdfParallelism: Int?

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

    /// The user symmetric key used for this request.
    let userSymmetricKey: String?

    /// The user asymmetrickeys used for this request.
    let userAsymmetricKeys: KeysRequestModel?

    // MARK: Initialization

    /// Initializes a `RegisterFinishRequestModel`.
    ///
    /// - Parameters:
    ///   - captchaResponse: The captcha response used in validating a user for this request.
    ///   - email: The user's email address.
    ///   - kdfConfig: A model for configuring KDF options.
    ///   - masterPasswordHash: The master password hash used to authenticate a user.
    ///   - masterPasswordHint: The master password hint.
    ///   - name: The user's name.
    ///   - organizationUserId: The organization's user ID.
    ///   - token: The token used when making this request.
    ///   - userSymmetricKey: The key used for this request.
    ///   - userAsymmetricKeys: The keys used for this request.
    ///
    init(
        captchaResponse: String? = nil,
        email: String,
        emailVerificationToken: String,
        kdfConfig: KdfConfig,
        masterPasswordHash: String,
        masterPasswordHint: String?,
        name: String? = nil,
        organizationUserId: String? = nil,
        token: String? = nil,
        userSymmetricKey: String? = nil,
        userAsymmetricKeys: KeysRequestModel? = nil
    ) {
        self.captchaResponse = captchaResponse
        self.email = email
        self.emailVerificationToken = emailVerificationToken
        kdf = kdfConfig.kdf
        kdfIterations = kdfConfig.kdfIterations
        kdfMemory = kdfConfig.kdfMemory
        kdfParallelism = kdfConfig.kdfParallelism
        kdfMemory = kdfConfig.kdfMemory
        self.masterPasswordHash = masterPasswordHash
        self.masterPasswordHint = masterPasswordHint
        self.name = name
        self.organizationUserId = organizationUserId
        self.token = token
        self.userSymmetricKey = userSymmetricKey
        self.userAsymmetricKeys = userAsymmetricKeys
    }
}

// MARK: JSONRequestBody

extension RegisterFinishRequestModel: JSONRequestBody {
    static let encoder = JSONEncoder()
}
