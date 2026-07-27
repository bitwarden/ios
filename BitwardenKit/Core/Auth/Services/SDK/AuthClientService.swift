import BitwardenSdk
import Foundation

/// A protocol for a service that handles auth tasks. This is similar to `AuthClientProtocol` but
/// returns protocols so they can be mocked for testing.
///
public protocol AuthClientService: AnyObject, Sendable { // sourcery: AutoMockable
    /// Approve an auth request.
    ///
    func approveAuthRequest(publicKey: String) throws -> UnsignedSharedKey

    /// Hash the user password.
    ///
    func hashPassword(email: String, password: String, kdfParams: Kdf, purpose: HashPurpose) async throws -> String

    /// Generate keys needed to onboard a new user without master key to key connector.
    ///
    func makeKeyConnectorKeys() throws -> KeyConnectorResponse

    /// Generate keys needed for registration process.
    ///
    func makeRegisterKeys(email: String, password: String, kdf: Kdf) throws -> RegisterKeyResponse

    /// Generate keys needed for TDE process.
    ///
    func makeRegisterTdeKeys(
        email: String,
        orgPublicKey: String,
        rememberDevice: Bool,
    ) async throws -> RegisterTdeKeyResponse

    /// Initialize a new auth request.
    ///
    func newAuthRequest(email: String) throws -> AuthRequestResponse

    /// Calculate password strength.
    ///
    func passwordStrength(password: String, email: String, additionalInputs: [String]) -> UInt8

    /// Returns the client for initializing user account cryptography and unlock methods after JIT provisioning.
    ///
    func registration() -> RegistrationClientProtocol

    /// Evaluate if the provided password satisfies the provided policy.
    ///
    func satisfiesPolicy(password: String, strength: UInt8, policy: MasterPasswordPolicyOptions) -> Bool

    /// Trust the current device.
    ///
    func trustDevice() throws -> TrustDeviceResponse

    /// Validate the user password.
    ///
    func validatePassword(password: String, passwordHash: String) async throws -> Bool

    /// Validate the user password without knowing the password hash.
    ///
    func validatePasswordUserKey(password: String, encryptedUserKey: String) async throws -> String

    /// Validates a PIN against a PIN-protected user key envelope.
    ///
    func validatePinProtectedUserKeyEnvelope(
        pin: String,
        pinProtectedUserKeyEnvelope: PasswordProtectedKeyEnvelope,
    ) -> Bool
}

// MARK: - AuthClient

extension AuthClient: AuthClientService {
    public func registration() -> RegistrationClientProtocol {
        registration() as RegistrationClient
    }
}
