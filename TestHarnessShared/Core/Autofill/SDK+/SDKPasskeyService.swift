import BitwardenKit
import BitwardenSdk
import CryptoKit
import Foundation

// MARK: - SDKPasskeyService

// sourcery: AutoMockable
/// A service that performs passkey registration and authentication directly through
/// `BitwardenSdk`'s Fido2 client — the same way the main Bitwarden app and its AutoFill
/// extension do — without going through the OS's passkey UI or a real vault.
///
public protocol SDKPasskeyService: AnyObject {
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

    /// Deletes a previously registered credential.
    ///
    /// - Parameter cipherId: The ID of the cipher — from `Fido2CredentialAutofillView.cipherId` —
    ///   backing the credential to delete.
    ///
    func deleteCredential(cipherId: String) async throws

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

// MARK: - HasSDKPasskeyService

/// A protocol for an object that provides an `SDKPasskeyService`.
protocol HasSDKPasskeyService {
    /// The service used to perform passkey registration and authentication through the
    /// Bitwarden SDK.
    var sdkPasskeyService: SDKPasskeyService { get }
}

// MARK: - DefaultSDKPasskeyService

/// The default `SDKPasskeyService` implementation. Bootstraps a single `BitwardenSdk.Client` per
/// app session, backed by a synthetic identity — since this scenario has no real account or
/// vault — that's persisted in the keychain so the same crypto keys, and therefore any
/// previously-registered credentials, remain usable across app launches. Drives the client's
/// Fido2 authenticator directly for registration, assertion, and listing registered credentials.
///
actor DefaultSDKPasskeyService: SDKPasskeyService {
    // MARK: Private Properties

    /// The number of PBKDF2 iterations used to derive this session's synthetic identity's keys.
    private static let kdfIterations: UInt32 = 600_000

    /// Used to persist ciphers across app relaunches.
    private let cipherStorageService: SDKCipherStorageService

    /// The lazily-initialized SDK client for this session.
    private var client: BitwardenSdk.Client?

    /// The lazily-initialized credential store for this session, sharing the client's crypto
    /// state so credentials registered earlier remain visible to later assertions.
    private var credentialStore: SDKFido2CredentialStore?

    /// Used to persist and reload the synthetic identity across app launches.
    private let keychainServiceFacade: KeychainServiceFacade

    /// The user interface driving `checkUser`/credential-picking callbacks from the SDK.
    private let userInterface = SDKFido2UserInterface()

    // MARK: Initialization

    /// Initializes a `DefaultSDKPasskeyService`.
    ///
    /// - Parameters:
    ///   - cipherStorageService: Used to persist ciphers across app relaunches.
    ///   - keychainServiceFacade: Used to persist and reload the synthetic identity across app
    ///     launches.
    ///
    init(
        cipherStorageService: SDKCipherStorageService = DefaultSDKCipherStorageService(),
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
        await credentialStore.select(credentialId: credentialId)
        let request = GetAssertionRequest(
            rpId: rpId,
            clientDataHash: Self.clientDataHash(type: "webauthn.get", rpId: rpId),
            allowList: nil,
            options: Options(rk: false, uv: .preferred),
            extensions: nil,
        )
        return try await client.platform().fido2()
            .vaultAuthenticator(userInterface: userInterface, credentialStore: credentialStore)
            .getAssertion(request: request)
    }

    func deleteCredential(cipherId: String) async throws {
        let (_, credentialStore) = try await session()
        await credentialStore.deleteCredential(cipherId: cipherId)
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
    private func loadOrCreateIdentity() async throws -> SDKSyntheticIdentity {
        if let identity: SDKSyntheticIdentity = try? await keychainServiceFacade.getValue(
            for: SDKPasskeyKeychainItem.syntheticIdentity,
        ) {
            return identity
        }

        let client = BitwardenSdk.Client(tokenProvider: SDKClientManagedTokensProvider(), settings: nil)
        let email = "sdk-passkey-playground@bitwarden.com"
        let password = UUID().uuidString
        let keys = try client.auth().makeRegisterKeys(
            email: email,
            password: password,
            kdf: Kdf.pbkdf2(iterations: Self.kdfIterations),
        )
        let identity = SDKSyntheticIdentity(
            email: email,
            encryptedUserKey: keys.encryptedUserKey,
            kdfIterations: Self.kdfIterations,
            password: password,
            privateKey: keys.keys.private,
            userId: UUID().uuidString,
        )
        try await keychainServiceFacade.setValue(identity, for: SDKPasskeyKeychainItem.syntheticIdentity)
        return identity
    }

    /// Lazily builds and crypto-initializes the SDK client and credential store for this session,
    /// reusing them across calls so registered credentials remain visible to later assertions.
    private func session() async throws -> (BitwardenSdk.Client, SDKFido2CredentialStore) {
        if let client, let credentialStore {
            return (client, credentialStore)
        }

        let identity = try await loadOrCreateIdentity()
        let client = BitwardenSdk.Client(tokenProvider: SDKClientManagedTokensProvider(), settings: nil)
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

        let credentialStore = SDKFido2CredentialStore(
            cipherStorageService: cipherStorageService,
            vaultClientService: client.vault(),
        )
        self.client = client
        self.credentialStore = credentialStore
        return (client, credentialStore)
    }
}
