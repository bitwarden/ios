import BitwardenKit
import BitwardenSdk
import CryptoKit
import Foundation

// MARK: - PasskeyService

// sourcery: AutoMockable
/// A service that performs passkey registration and authentication directly through
/// `BitwardenSdk`'s Fido2 client.
///
public protocol PasskeyService: AnyObject {
    /// Asserts a passkey for `rpId` against previously registered credentials.
    ///
    /// - Parameters:
    ///   - credentialId: A specific credential to assert, e.g. one the user selected from
    ///     `registeredCredentials()`. When provided, only this credential is considered,
    ///     regardless of how many others are registered for `rpId`. When `nil`, the first
    ///     unambiguous match for `rpId` is used.
    ///   - rpId: The relying party identifier to assert a credential for.
    /// - Returns: The SDK's assertion result.
    ///
    func assertPasskey(credentialId: Data?, rpId: String) async throws -> GetAssertionResult

    /// Lists the credentials registered so far, across app launches.
    ///
    /// - Returns: The registered credentials' autofill-ready metadata.
    ///
    func registeredCredentials() async throws -> [Fido2CredentialAutofillView]

    /// Registers a new passkey for `rpId`.
    ///
    /// - Parameters:
    ///   - rpId: The relying party identifier the credential is scoped to.
    ///   - userName: The username associated with the credential.
    ///   - displayName: The display name associated with the credential.
    /// - Returns: The SDK's registration result.
    ///
    func registerPasskey(rpId: String, userName: String, displayName: String) async throws -> MakeCredentialResult
}

// MARK: - HasPasskeyService

/// A protocol for an object that provides a `PasskeyService`.
protocol HasPasskeyService {
    /// The service used to perform passkey registration and authentication through the
    /// Bitwarden SDK.
    var passkeyService: PasskeyService { get }
}

// MARK: - DefaultPasskeyService

/// The default `PasskeyService` implementation. Bootstraps a single `BitwardenSdk.Client` per
/// app session, backed by a synthetic identity — since this scenario has no real account or
/// vault — that's persisted in the keychain so the same crypto keys, and therefore any
/// previously-registered credentials, remain usable across app launches. Drives the client's
/// Fido2 authenticator directly for registration, assertion, and listing registered credentials.
///
actor DefaultPasskeyService: PasskeyService {
    // MARK: Private Properties

    /// The number of PBKDF2 iterations used to derive this session's synthetic identity's keys.
    private static let kdfIterations: UInt32 = 600_000

    /// Used to persist ciphers across app relaunches.
    private let cipherStorageService: CipherStorageService

    /// Used to persist and reload the synthetic identity across app launches.
    private let keychainServiceFacade: KeychainServiceFacade

    /// The in-flight or completed session bootstrap, cached so concurrent callers share a single
    /// client and credential store instead of each bootstrapping their own.
    private var sessionTask: Task<(BitwardenSdk.Client, DefaultFido2CredentialStore), Error>?

    /// The user interface driving `checkUser`/credential-picking callbacks from the SDK.
    private let userInterface = DefaultFido2UserInterface()

    // MARK: Initialization

    /// Initializes a `DefaultPasskeyService`.
    ///
    /// - Parameters:
    ///   - cipherStorageService: Used to persist ciphers across app relaunches.
    ///   - keychainServiceFacade: Used to persist and reload the synthetic identity across app
    ///     launches.
    ///
    init(
        cipherStorageService: CipherStorageService = DefaultCipherStorageService(),
        keychainServiceFacade: KeychainServiceFacade = DefaultKeychainServiceFacade(
            appSecAttrAccessGroup: Bundle.main.groupIdentifier,
            keychainService: DefaultKeychainService(),
            namespacing: .shared,
        ),
    ) {
        self.cipherStorageService = cipherStorageService
        self.keychainServiceFacade = keychainServiceFacade
    }

    // MARK: Static Methods

    /// Builds a synthetic WebAuthn `clientDataJSON` for `type`/`rpId` and returns its SHA-256
    /// hash, since these scenarios simulate the relying party's browser step in-process rather
    /// than delegating to a real one.
    private static func clientDataHash(type: String, rpId: String) -> Data {
        let challenge = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        let clientData = [
            "type": type,
            "challenge": challenge.base64EncodedString(),
            "origin": "https://\(rpId)",
        ]
        let clientDataJSON = (try? JSONSerialization.data(withJSONObject: clientData, options: [.sortedKeys])) ?? Data()
        return Data(SHA256.hash(data: clientDataJSON))
    }

    // MARK: Methods

    func assertPasskey(credentialId: Data?, rpId: String) async throws -> GetAssertionResult {
        let (client, credentialStore) = try await session()
        let allowList = credentialId.map { [PublicKeyCredentialDescriptor(ty: "public-key", id: $0, transports: nil)] }
        let request = GetAssertionRequest(
            rpId: rpId,
            clientDataHash: Self.clientDataHash(type: "webauthn.get", rpId: rpId),
            allowList: allowList,
            options: Options(rk: false, uv: .preferred),
            extensions: nil,
        )
        return try await client.platform().fido2()
            .vaultAuthenticator(userInterface: userInterface, credentialStore: credentialStore)
            .getAssertion(request: request)
    }

    func registeredCredentials() async throws -> [Fido2CredentialAutofillView] {
        let (client, credentialStore) = try await session()
        return try await client.platform().fido2()
            .vaultAuthenticator(userInterface: userInterface, credentialStore: credentialStore)
            .credentialsForAutofill()
    }

    func registerPasskey(rpId: String, userName: String, displayName: String) async throws -> MakeCredentialResult {
        let (client, credentialStore) = try await session()
        let request = MakeCredentialRequest(
            clientDataHash: Self.clientDataHash(type: "webauthn.create", rpId: rpId),
            rp: PublicKeyCredentialRpEntity(id: rpId, name: rpId),
            user: PublicKeyCredentialUserEntity(
                id: Data(UUID().uuidString.utf8),
                displayName: displayName.isEmpty ? userName : displayName,
                name: userName,
            ),
            pubKeyCredParams: [PublicKeyCredentialParameters(ty: "public-key", alg: -7)],
            excludeList: nil,
            options: Options(rk: true, uv: .preferred),
            extensions: nil,
        )
        return try await client.platform().fido2()
            .vaultAuthenticator(userInterface: userInterface, credentialStore: credentialStore)
            .makeCredential(request: request)
    }

    // MARK: Private

    /// Loads the synthetic identity persisted from a previous launch, or generates and persists a
    /// new one via the SDK's local-only key-generation primitive if none exists yet.
    private func loadOrCreateIdentity() async throws -> SyntheticIdentity {
        if let identity: SyntheticIdentity = try? await keychainServiceFacade.getValue(
            for: PasskeyKeychainItem.syntheticIdentity,
        ) {
            return identity
        }

        let client = BitwardenSdk.Client(tokenProvider: ClientManagedTokensProvider(), settings: nil)
        let email = "sdk-passkey-playground@bitwarden.com"
        let password = UUID().uuidString
        let keys = try client.auth().makeRegisterKeys(
            email: email,
            password: password,
            kdf: Kdf.pbkdf2(iterations: Self.kdfIterations),
        )
        let identity = SyntheticIdentity(
            email: email,
            encryptedUserKey: keys.encryptedUserKey,
            kdfIterations: Self.kdfIterations,
            password: password,
            privateKey: keys.keys.private,
            userId: UUID().uuidString,
        )
        try await keychainServiceFacade.setValue(identity, for: PasskeyKeychainItem.syntheticIdentity)
        // The new identity's key can't decrypt anything persisted under the previous one.
        cipherStorageService.save(ciphers: [])
        return identity
    }

    /// Lazily builds and crypto-initializes the SDK client and credential store for this session,
    /// reusing them across calls so registered credentials remain visible to later assertions.
    /// Caches the bootstrap as a `Task` so concurrent callers await the same work instead of each
    /// racing their own bootstrap.
    private func session() async throws -> (BitwardenSdk.Client, DefaultFido2CredentialStore) {
        if let sessionTask {
            return try await sessionTask.value
        }

        let task = Task { try await makeSession() }
        sessionTask = task
        do {
            return try await task.value
        } catch {
            sessionTask = nil
            throw error
        }
    }

    /// Builds and crypto-initializes the SDK client and credential store for this session.
    private func makeSession() async throws -> (BitwardenSdk.Client, DefaultFido2CredentialStore) {
        let identity = try await loadOrCreateIdentity()
        let client = BitwardenSdk.Client(tokenProvider: ClientManagedTokensProvider(), settings: nil)
        let kdf = Kdf.pbkdf2(iterations: identity.kdfIterations)
        try await client.crypto().initializeUserCrypto(
            req: InitUserCryptoRequest(
                userId: identity.userId,
                kdfParams: kdf,
                email: identity.email,
                accountCryptographicState: .v1(privateKey: identity.privateKey),
                method: .masterPasswordUnlock(
                    password: identity.password,
                    masterPasswordUnlock: MasterPasswordUnlockData(
                        kdf: kdf,
                        masterKeyWrappedUserKey: identity.encryptedUserKey,
                        salt: identity.email,
                    ),
                ),
                upgradeToken: nil,
            ),
        )

        let credentialStore = DefaultFido2CredentialStore(
            cipherStorageService: cipherStorageService,
            platformClientService: client.platform(),
            vaultClientService: client.vault(),
        )
        return (client, credentialStore)
    }
}
