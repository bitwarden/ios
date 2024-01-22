import Foundation
import Networking

/// API response model for the identity token request.
///
struct IdentityTokenResponseModel: Equatable, JSONResponse, KdfConfigProtocol {
    static var decoder = JSONDecoder.pascalOrSnakeCaseDecoder

    // MARK: Account Properties

    /// Whether the app needs to force a password reset.
    let forcePasswordReset: Bool

    /// The type of KDF algorithm to use.
    let kdf: KdfType

    /// The number of iterations to use when calculating a password hash.
    let kdfIterations: Int

    /// The amount of memory to use when calculating a password hash.
    let kdfMemory: Int?

    /// The number of threads to use when calculating a password hash.
    let kdfParallelism: Int?

    /// The user's key.
    let key: String

    /// Policies related to the user's master password.
    let masterPasswordPolicy: MasterPasswordPolicyResponseModel?

    /// The user's private key.
    let privateKey: String

    /// Whether the user's master password needs to be reset.
    let resetMasterPassword: Bool

    /// The two-factor authentication token.
    let twoFactorToken: String?

    /// Options for a user's decryption.
    let userDecryptionOptions: UserDecryptionOptions?

    // MARK: Token Properties

    /// The user's access token.
    let accessToken: String

    /// The number of seconds before the access token expires.
    let expiresIn: Int

    /// The type of token.
    let tokenType: String

    /// The user's refresh token.
    let refreshToken: String
}
