import BitwardenKit
import BitwardenSdk
import Combine
import CryptoKit
import Foundation

// MARK: - DeviceAuthKeyService

/// Service to manage the device auth key.
protocol DeviceAuthKeyService { // sourcery: AutoMockable
    /// Signs a passkey assertion request with the device auth key, if it exists and matches the given
    /// ``recordIdentifier``.
    ///
    /// - Parameters:
    ///   - request: The passkey assertion request.
    ///   - recordIdentifier: The record identifier for the ``ASPasskeyCredentialIdentity`` related to the passkey
    ///     assertion request, which should be equal to the record identifier of the device auth key.
    ///   - userId: The user ID for the account to assert the device auth key for.
    /// - Returns: A ``DeviceAuthKeyGetAssertionResult``, or `nil` if the device auth key does not exist.
    ///
    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String?,
    ) async throws -> DeviceAuthKeyGetAssertionResult?

    /// Signs a WebAuthn login challenge from the server with the device auth key of a logged out
    /// user. This reads the device auth key from the keychain one time, which asks the user for
    /// biometrics.
    ///
    /// - Parameters:
    ///   - challenge: The base64url encoded challenge from the server's assertion options.
    ///   - rpId: The relying party ID from the server's assertion options, if any.
    ///   - email: The email of the user that logs in.
    /// - Returns: The assertion for the token request and the PRF key to unlock the vault after login.
    ///
    func assertDeviceAuthKeyForLogin(
        challenge: String,
        rpId: String?,
        email: String,
    ) async throws -> DeviceAuthKeyLoginAssertion

    /// Create device auth key with PRF encryption key.
    ///
    /// Before calling, the vault must be unlocked to wrap user encryption key.
    ///
    /// - Parameters:
    ///   - masterPassword: The user's master password (not the hash). The SDK derives the hash
    ///     that the server needs to verify the user.
    ///   - isPasswordlessAccount: Whether the device auth key is the account's primary way to log
    ///     in and unlock, because the user doesn't know the master password.
    ///   - overwrite: Whether to overwrite an existing value if a previous one is already found.
    ///   - userId: The user ID for the account to create the device auth key for.
    ///
    func createDeviceAuthKey(
        masterPassword: String,
        isPasswordlessAccount: Bool,
        overwrite: Bool,
        userId: String?,
    ) async throws

    /// Deletes the device auth key.
    ///
    /// - Parameters:
    ///   - userId: The user ID to delete the device auth key of.
    ///
    func deleteDeviceAuthKey(
        userId: String?,
    ) async throws

    /// Retrieve the metadata for the device auth key, if it exists.
    ///
    /// - Parameters:
    ///   - userId: The user ID for the account to get device auth key metadata for.
    ///
    func getDeviceAuthKeyMetadata(userId: String?) async throws -> DeviceAuthKeyKeychainMetadata?

    /// Gets the data needed to unlock the vault with the device auth key. This reads the device
    /// auth key from the keychain, which asks the user for biometrics.
    ///
    /// - Parameter userId: The user ID for the account to unlock.
    /// - Returns: The data to unlock the vault.
    ///
    func getDeviceAuthKeyUnlockData(userId: String?) async throws -> DeviceAuthKeyUnlockData

    /// Whether a device auth key exists on this device for a user with the given email. This
    /// works for logged out users.
    ///
    /// - Parameter email: The user's email.
    /// - Returns: Whether the user can log in with a device auth key.
    ///
    func hasDeviceAuthKey(email: String) async -> Bool

    /// Whether the account has a device auth key that can unlock the vault, and the user doesn't
    /// know the account's master password.
    ///
    /// - Parameter userId: The user ID for the account.
    /// - Returns: Whether the account is a device auth key account.
    ///
    func isPasswordlessAccount(userId: String?) async -> Bool

    /// Stores the PRF key set for the user's device auth key, which is needed to unlock the vault
    /// with the device auth key.
    ///
    /// - Parameters:
    ///   - encryptedPrivateKey: The private key of the key set, encrypted with the PRF key.
    ///   - encryptedUserKey: The user key, encapsulated with the public key of the key set.
    ///   - userId: The user ID for the account.
    ///
    func setDeviceAuthKeyPrfKeySet(
        encryptedPrivateKey: String,
        encryptedUserKey: String,
        userId: String?,
    ) async throws

    // MARK: Publishers

    /// A publisher for the device auth key
    func deviceAuthKeyPublisher() -> AnyPublisher<[String: Bool], Never>
}

// MARK: - Convenience Methods

extension DeviceAuthKeyService {
    /// Signs a passkey assertion request with the device auth key for the current user,
    /// if it exists and matches the given ``recordIdentifier``.
    ///
    /// - Parameters:
    ///   - request: The passkey assertion request.
    ///   - recordIdentifier: The record identifier for the ``ASPasskeyCredentialIdentity`` related to the passkey
    ///     assertion request, which should be equal to the record identifier of the device auth key.
    /// - Returns: A ``DeviceAuthKeyGetAssertionResult``, or `nil` if the device auth key does not exist.
    ///
    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
    ) async throws -> DeviceAuthKeyGetAssertionResult? {
        try await assertDeviceAuthKey(
            for: request,
            recordIdentifier: recordIdentifier,
            userId: nil,
        )
    }

    /// Deletes the device auth key for the current user.
    ///
    func deleteDeviceAuthKey() async throws {
        try await deleteDeviceAuthKey(userId: nil)
    }

    /// Retrieve the metadata for the device auth key for the current user, if it exists.
    ///
    func getDeviceAuthKeyMetadata() async throws -> DeviceAuthKeyKeychainMetadata? {
        try await getDeviceAuthKeyMetadata(userId: nil)
    }
}

// MARK: - DeviceAuthKeyLoginAssertion

/// The result of signing a WebAuthn login challenge with the device auth key.
///
struct DeviceAuthKeyLoginAssertion: Equatable, Sendable {
    /// The JSON encoded `AuthenticatorAssertionRawResponse` for the `deviceResponse` value of the
    /// identity token request.
    let deviceResponse: String

    /// The base64 encoded 64-byte symmetric key stretched from the device auth key's PRF output.
    let prfKey: String

    /// The ID of the user that owns the device auth key.
    let userId: String
}

// MARK: - DefaultDeviceAuthKeyService

/// Default implementation of DeviceAuthKeyService
struct DefaultDeviceAuthKeyService: DeviceAuthKeyService {
    // MARK: Properties

    /// The provider for the active account state.
    private let activeAccountStateProvider: ActiveAccountStateProvider

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// Repository for managing device auth keys in the keychain.
    private let deviceAuthKeychainRepository: DeviceAuthKeychainRepository

    /// A subject containing a userId and flag for the presence of the unlock passkey for logged in accounts.
    private let deviceAuthKeySubject = CurrentValueSubject<[String: Bool], Never>([:])

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The object used by the application to retrieve information about this device.
    private let systemDevice: SystemDevice

    // MARK: Initializers

    /// Creates a new instance of `DefaultDeviceAuthKeyService`.
    ///
    /// - Parameters:
    ///   - activeAccountStateProvider: The provider for the active account state.
    ///   - clientService: The service that handles common client functionality.
    ///   - deviceAuthKeychainRepository: The repository for managing device auth keys in the keychain.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    ///   - systemDevice: The object used by the application to retrieve information about this device.
    ///
    init(
        activeAccountStateProvider: ActiveAccountStateProvider,
        clientService: ClientService,
        deviceAuthKeychainRepository: DeviceAuthKeychainRepository,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        stateService: StateService,
        systemDevice: SystemDevice,
    ) {
        self.activeAccountStateProvider = activeAccountStateProvider
        self.clientService = clientService
        self.deviceAuthKeychainRepository = deviceAuthKeychainRepository
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.systemDevice = systemDevice
    }

    // MARK: Functions

    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String?,
    ) async throws -> DeviceAuthKeyGetAssertionResult? {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        guard let metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId),
              metadata.cipherId == recordIdentifier
        else {
            return nil
        }

        let store = DefaultDeviceAuthKeyStore(
            deviceAuthKeychainRepository: deviceAuthKeychainRepository,
            userId: resolvedUserId,
        )
        return try await clientService.platform(for: resolvedUserId, isPreAuth: false)
            .fido2()
            .deviceAuthKeyAuthenticator(credentialStore: store)
            .assertDeviceAuthKey(request: request)
    }

    func assertDeviceAuthKeyForLogin(
        challenge: String,
        rpId: String?,
        email: String,
    ) async throws -> DeviceAuthKeyLoginAssertion {
        guard let userId = try await deviceAuthKeychainRepository.getDeviceAuthKeyUserId(email: email) else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }
        // Read the record one time, so the user only gets one biometrics prompt for both the
        // assertion and the PRF key.
        guard let record = try await deviceAuthKeychainRepository.getDeviceAuthKey(userId: userId) else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }

        // The origin has to be the web vault's origin, which is what the server allows for WebAuthn
        // and what the SDK used in the `clientDataJSON` when it created the device auth key.
        let origin = try DeviceAuthKeyCrypto.webAuthnOrigin(for: environmentService.webVaultURL)
        let clientDataJson = Data(
            #"{"type":"webauthn.get","challenge":"\#(challenge)","origin":"\#(origin)","crossOrigin":false}"#.utf8,
        )

        let store = DefaultDeviceAuthKeyStore(
            cachedRecord: record,
            deviceAuthKeychainRepository: deviceAuthKeychainRepository,
            userId: userId,
        )
        let request = GetAssertionRequest(
            rpId: rpId ?? record.rpId,
            clientDataHash: Data(SHA256.hash(data: clientDataJson)),
            allowList: nil,
            options: Options(rk: false, uv: .required),
            // The PRF output from the SDK's assertion doesn't match the PRF output that the SDK used
            // when it created the key set, so the app derives the PRF key from the record instead.
            extensions: nil,
        )
        let assertion = try await clientService.platform(isPreAuth: true)
            .fido2()
            .deviceAuthKeyAuthenticator(credentialStore: store)
            .assertDeviceAuthKey(request: request)

        let deviceResponse = WebAuthnLoginAssertionDeviceResponse(
            id: assertion.credentialId.base64urlEncodedString(),
            rawId: assertion.credentialId.base64urlEncodedString(),
            response: WebAuthnLoginAssertionDeviceResponse.Response(
                authenticatorData: assertion.authenticatorData.base64urlEncodedString(),
                clientDataJSON: clientDataJson.base64urlEncodedString(),
                signature: assertion.signature.base64urlEncodedString(),
                userHandle: assertion.userHandle.base64urlEncodedString(),
            ),
        )
        let deviceResponseData = try JSONEncoder().encode(deviceResponse)

        return try DeviceAuthKeyLoginAssertion(
            deviceResponse: String(decoding: deviceResponseData, as: UTF8.self),
            prfKey: DeviceAuthKeyCrypto.prfKey(hmacSecret: record.hmacSecret),
            userId: userId,
        )
    }

    func createDeviceAuthKey(
        masterPassword: String,
        isPasswordlessAccount: Bool,
        overwrite: Bool,
        userId: String?,
    ) async throws {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        let account = try await stateService.getAccount(userId: resolvedUserId)

        if try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId) != nil {
            guard overwrite else { throw DeviceAuthKeyError.alreadyExists }
            try await deviceAuthKeychainRepository.deleteDeviceAuthKey(userId: resolvedUserId)
        }

        let store = DefaultDeviceAuthKeyStore(
            deviceAuthKeychainRepository: deviceAuthKeychainRepository,
            userId: resolvedUserId,
        )
        // The SDK creates the passkey, makes the PRF key set, registers both with the server, and
        // saves the record and its metadata through the store.
        try await clientService.platform(for: resolvedUserId, isPreAuth: false)
            .fido2()
            .deviceAuthKeyAuthenticator(credentialStore: store)
            .createDeviceAuthKey(
                clientName: "Bitwarden iOS (\(systemDevice.modelIdentifier))",
                webVaultUrl: environmentService.webVaultURL.absoluteString,
                email: account.profile.email,
                secretVerificationRequest: SecretVerificationRequest(masterPassword: masterPassword, otp: nil),
                kdf: account.kdf.sdkKdf,
            )

        // The SDK doesn't return the key set that it registered with the server. The record is
        // still in memory, so make a key set for this device from the same PRF output. This avoids
        // a biometrics prompt and a sync right after creation.
        guard let record = store.createdRecord,
              var metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId)
        else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }
        let keySet = try await clientService.crypto(for: resolvedUserId).makePrfUserKeySet(
            prf: DeviceAuthKeyCrypto.prfOutput(hmacSecret: record.hmacSecret).base64EncodedString(),
        )
        metadata.encryptedPrivateKey = keySet.encryptedDecapsulationKey
        metadata.encryptedUserKey = keySet.encapsulatedDownstreamKey
        metadata.isPasswordlessAccount = isPasswordlessAccount
        try await deviceAuthKeychainRepository.setDeviceAuthKeyMetadata(metadata, userId: resolvedUserId)
        try await deviceAuthKeychainRepository.setDeviceAuthKeyUserId(resolvedUserId, email: account.profile.email)

        var curVal = deviceAuthKeySubject.value
        curVal[resolvedUserId] = true
        deviceAuthKeySubject.send(curVal)
    }

    func deleteDeviceAuthKey(
        userId: String?,
    ) async throws {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        if let metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId) {
            try await deviceAuthKeychainRepository.setDeviceAuthKeyUserId(nil, email: metadata.userName)
        }
        try await deviceAuthKeychainRepository.deleteDeviceAuthKey(userId: resolvedUserId)

        var curVal = deviceAuthKeySubject.value
        curVal[resolvedUserId] = false
        deviceAuthKeySubject.send(curVal)
    }

    func getDeviceAuthKeyMetadata(userId: String?) async throws -> DeviceAuthKeyKeychainMetadata? {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        return try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId)
    }

    func getDeviceAuthKeyUnlockData(userId: String?) async throws -> DeviceAuthKeyUnlockData {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        guard let metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId),
              let encryptedPrivateKey = metadata.encryptedPrivateKey,
              let encryptedUserKey = metadata.encryptedUserKey
        else {
            throw DeviceAuthKeyError.missingPrfKeySet
        }
        // Reading the record asks the user for biometrics.
        guard let record = try await deviceAuthKeychainRepository.getDeviceAuthKey(userId: resolvedUserId) else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }
        return try DeviceAuthKeyUnlockData(
            encryptedPrivateKey: encryptedPrivateKey,
            encryptedUserKey: encryptedUserKey,
            prfKey: DeviceAuthKeyCrypto.prfKey(hmacSecret: record.hmacSecret),
        )
    }

    func hasDeviceAuthKey(email: String) async -> Bool {
        do {
            guard let userId = try await deviceAuthKeychainRepository.getDeviceAuthKeyUserId(email: email) else {
                return false
            }
            return try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: userId) != nil
        } catch {
            errorReporter.log(error: error)
            return false
        }
    }

    func isPasswordlessAccount(userId: String?) async -> Bool {
        do {
            let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
            let metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId)
            return metadata?.isPasswordlessAccount == true
        } catch {
            return false
        }
    }

    func setDeviceAuthKeyPrfKeySet(
        encryptedPrivateKey: String,
        encryptedUserKey: String,
        userId: String?,
    ) async throws {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        guard var metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId)
        else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }
        metadata.encryptedPrivateKey = encryptedPrivateKey
        metadata.encryptedUserKey = encryptedUserKey
        try await deviceAuthKeychainRepository.setDeviceAuthKeyMetadata(metadata, userId: resolvedUserId)
    }

    // MARK: Publishers

    func deviceAuthKeyPublisher() -> AnyPublisher<[String: Bool], Never> {
        deviceAuthKeySubject.eraseToAnyPublisher()
    }
}

// MARK: - DeviceAuthKeyError

/// Errors that can occur when working with device auth keys.
enum DeviceAuthKeyError: Error, Equatable {
    /// A device auth key already exists for the user.
    case alreadyExists

    /// The web vault URL can't be used as a WebAuthn origin.
    case invalidWebVaultUrl

    /// The device auth key is missing or invalid.
    case missingOrInvalidKey

    /// The PRF key set that unlocks the vault with the device auth key is missing.
    case missingPrfKeySet

    /// The requested functionality has not yet been implemented.
    case notImplemented

    /// The server didn't return a PRF key set for the device auth key after login.
    case prfNotEnabledOnServer
}

// MARK: - DeviceAuthKeyCrypto

/// The PRF key derivation for the device auth key.
///
/// The SDK has no API to unlock the vault from a PRF output, and the PRF output from the SDK's
/// `assertDeviceAuthKey` doesn't match the PRF output that the SDK's `createDeviceAuthKey` used for
/// the key set (see NOTES.md, "PRF salt mismatch"). So the app repeats what creation did:
///
/// 1. PRF output = `HMAC-SHA256(key: hmacSecret, message: SHA256("passwordless-login"))`.
/// 2. PRF key = `HKDF-Expand(prk: output, info: "enc", 32) || HKDF-Expand(prk: output, info: "mac", 32)`,
///    which is the SDK's `derive_symmetric_key_from_prf`.
///
enum DeviceAuthKeyCrypto {
    /// The PRF salt input that the SDK hard-codes when it creates the device auth key.
    static let prfSaltInput = "passwordless-login"

    /// Computes the PRF output that the SDK used to make the key set when it created the device auth key.
    ///
    /// - Parameter hmacSecret: The HMAC secret (`CredRandom`) from the device auth key record.
    /// - Returns: The 32-byte PRF output.
    ///
    static func prfOutput(hmacSecret: Data) -> Data {
        let salt = Data(SHA256.hash(data: Data(prfSaltInput.utf8)))
        let output = HMAC<SHA256>.authenticationCode(for: salt, using: SymmetricKey(data: hmacSecret))
        return Data(output)
    }

    /// Computes the stretched symmetric key that wraps the private key of the PRF key set.
    ///
    /// - Parameter hmacSecret: The HMAC secret (`CredRandom`) from the device auth key record.
    /// - Returns: The base64 encoded 64-byte key (32-byte encryption key, then 32-byte MAC key).
    ///
    static func prfKey(hmacSecret: Data) throws -> String {
        guard !hmacSecret.isEmpty else { throw DeviceAuthKeyError.missingOrInvalidKey }
        let prk = SymmetricKey(data: prfOutput(hmacSecret: hmacSecret))
        let encKey = HKDF<SHA256>.expand(pseudoRandomKey: prk, info: Data("enc".utf8), outputByteCount: 32)
        let macKey = HKDF<SHA256>.expand(pseudoRandomKey: prk, info: Data("mac".utf8), outputByteCount: 32)
        let key = encKey.withUnsafeBytes { Data($0) } + macKey.withUnsafeBytes { Data($0) }
        return key.base64EncodedString()
    }

    /// Builds the WebAuthn origin for a web vault URL the same way the SDK does: scheme, host and
    /// the port if it isn't the default port for the scheme.
    ///
    /// - Parameter webVaultURL: The web vault URL of the environment.
    /// - Returns: The origin for the `clientDataJSON`.
    ///
    static func webAuthnOrigin(for webVaultURL: URL) throws -> String {
        guard let scheme = webVaultURL.scheme?.lowercased(), let host = webVaultURL.host?.lowercased() else {
            throw DeviceAuthKeyError.invalidWebVaultUrl
        }
        var origin = "\(scheme)://\(host)"
        if let port = webVaultURL.port {
            let isDefaultPort = (scheme == "https" && port == 443) || (scheme == "http" && port == 80)
            if !isDefaultPort {
                origin += ":\(port)"
            }
        }
        return origin
    }
}

// MARK: - WebAuthnLoginAssertionDeviceResponse

/// The `AuthenticatorAssertionRawResponse` that the server expects in the `deviceResponse` value of
/// a `webauthn` grant token request. All binary values are base64url encoded.
///
struct WebAuthnLoginAssertionDeviceResponse: Encodable, Equatable {
    // MARK: Types

    /// The authenticator's response to the assertion request.
    struct Response: Encodable, Equatable {
        /// The authenticator data.
        let authenticatorData: String

        /// The client data JSON that the signature covers.
        let clientDataJSON: String

        /// The signature over the authenticator data and the client data hash.
        let signature: String

        /// The WebAuthn user handle.
        let userHandle: String
    }

    // MARK: Properties

    /// The client extension results. These are always empty, the PRF output never leaves the device.
    let extensions = [String: String]()

    /// The base64url encoded credential ID.
    let id: String

    /// The base64url encoded credential ID.
    let rawId: String

    /// The authenticator's response to the assertion request.
    let response: Response

    /// The credential type.
    let type = "public-key"
}

// MARK: - DefaultDeviceAuthKeyStore

/// The store that the SDK uses to save and load the device auth key. It's backed by the keychain.
///
final class DefaultDeviceAuthKeyStore: DeviceAuthKeyStore, @unchecked Sendable {
    // MARK: Properties

    /// A record that was already read from the keychain, to avoid a second biometrics prompt.
    private let cachedRecord: DeviceAuthKeyKeychainRecord?

    /// The record that the SDK created through this store, if any.
    private(set) var createdRecord: DeviceAuthKeyKeychainRecord?

    /// Repository for managing device auth keys in the keychain.
    private let deviceAuthKeychainRepository: DeviceAuthKeychainRepository

    /// The ID of the user that owns the device auth key.
    private let userId: String

    // MARK: Initialization

    /// Creates a new `DefaultDeviceAuthKeyStore`.
    ///
    /// - Parameters:
    ///   - cachedRecord: A record that was already read from the keychain.
    ///   - deviceAuthKeychainRepository: Repository for managing device auth keys in the keychain.
    ///   - userId: The ID of the user that owns the device auth key.
    ///
    init(
        cachedRecord: DeviceAuthKeyKeychainRecord? = nil,
        deviceAuthKeychainRepository: DeviceAuthKeychainRepository,
        userId: String,
    ) {
        self.cachedRecord = cachedRecord
        self.deviceAuthKeychainRepository = deviceAuthKeychainRepository
        self.userId = userId
    }

    // MARK: DeviceAuthKeyStore

    func createRecord(record: DeviceAuthKeyRecord) async throws {
        let keychainRecord = DeviceAuthKeyKeychainRecord(
            counter: record.counter,
            credentialId: record.credentialId,
            hmacSecret: record.hmacSecret,
            key: record.key,
            rpId: record.rpId,
            userId: record.userId,
        )
        try await deviceAuthKeychainRepository.setDeviceAuthKeyRecord(keychainRecord, userId: userId)
        createdRecord = keychainRecord
    }

    func createMetadata(metadata: DeviceAuthKeyMetadata) async throws {
        try await deviceAuthKeychainRepository.setDeviceAuthKeyMetadata(
            DeviceAuthKeyKeychainMetadata(
                cipherId: metadata.recordIdentifier,
                creationDate: metadata.creationDate,
                credentialId: metadata.credentialId,
                rpId: metadata.rpId,
                userDisplayName: metadata.userDisplayName,
                userHandle: metadata.userHandle,
                userName: metadata.userName,
            ),
            userId: userId,
        )
    }

    func getMetadata() async throws -> DeviceAuthKeyMetadata? {
        guard let metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: userId) else {
            return nil
        }
        return DeviceAuthKeyMetadata(
            recordIdentifier: metadata.cipherId,
            creationDate: metadata.creationDate ?? .distantPast,
            credentialId: metadata.credentialId,
            rpId: metadata.rpId,
            userName: metadata.userName,
            userHandle: metadata.userHandle,
            userDisplayName: metadata.userDisplayName ?? metadata.userName,
        )
    }

    func getRecord() async throws -> DeviceAuthKeyRecord? {
        let keychainRecord: DeviceAuthKeyKeychainRecord? = if let record = cachedRecord ?? createdRecord {
            record
        } else {
            try await deviceAuthKeychainRepository.getDeviceAuthKey(userId: userId)
        }
        guard let keychainRecord else { return nil }
        return DeviceAuthKeyRecord(
            credentialId: keychainRecord.credentialId,
            key: keychainRecord.key,
            rpId: keychainRecord.rpId,
            userId: keychainRecord.userId,
            // The SDK's store can't update the counter, and an assertion with a counter fails in
            // the SDK. The device auth key doesn't use signature counters.
            counter: nil,
            hmacSecret: keychainRecord.hmacSecret,
        )
    }

    func deleteRecordAndMetadata() async throws {
        try await deviceAuthKeychainRepository.deleteDeviceAuthKey(userId: userId)
    }
}
