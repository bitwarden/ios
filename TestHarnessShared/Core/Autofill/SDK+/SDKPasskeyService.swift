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
    /// - Parameter rpId: The relying party identifier to assert a credential for.
    /// - Returns: The SDK's assertion result.
    ///
    func assertPasskey(rpId: String) async throws -> GetAssertionResult

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

/// The default `SDKPasskeyService` implementation. Bootstraps a single ephemeral
/// `BitwardenSdk.Client` per app session — with a freshly generated, never-persisted synthetic
/// identity, since this scenario has no real account or vault — and drives its Fido2
/// authenticator directly for both registration and assertion.
///
actor DefaultSDKPasskeyService: SDKPasskeyService {
    // MARK: Private Properties

    /// The number of PBKDF2 iterations used to derive this session's synthetic, ephemeral key.
    private static let kdfIterations: UInt32 = 600_000

    /// The lazily-initialized ephemeral SDK client for this session.
    private var client: BitwardenSdk.Client?

    /// The lazily-initialized credential store for this session, sharing the client's crypto
    /// state so credentials registered earlier remain visible to later assertions.
    private var credentialStore: SDKFido2CredentialStore?

    /// The user interface driving `checkUser`/credential-picking callbacks from the SDK.
    private let userInterface = SDKFido2UserInterface()

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

    func assertPasskey(rpId: String) async throws -> GetAssertionResult {
        let (client, credentialStore) = try await session()
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

    /// Lazily builds and crypto-initializes the ephemeral SDK client and credential store for
    /// this session, reusing them across calls so registered credentials remain visible to later
    /// assertions.
    private func session() async throws -> (BitwardenSdk.Client, SDKFido2CredentialStore) {
        if let client, let credentialStore {
            return (client, credentialStore)
        }

        let client = BitwardenSdk.Client(tokenProvider: SDKClientManagedTokensProvider(), settings: nil)
        let email = "sdk-passkey-playground@bitwarden.com"
        let password = UUID().uuidString
        let kdf = Kdf.pbkdf2(iterations: Self.kdfIterations)
        let keys = try client.auth().makeRegisterKeys(email: email, password: password, kdf: kdf)
        try await client.crypto().initializeUserCrypto(
            req: InitUserCryptoRequest(
                userId: UUID().uuidString,
                kdfParams: kdf,
                email: email,
                accountCryptographicState: .v1(privateKey: keys.keys.private),
                method: .masterPasswordUnlock(
                    password: password,
                    masterPasswordUnlock: MasterPasswordUnlockData(
                        kdf: kdf,
                        masterKeyWrappedUserKey: keys.encryptedUserKey,
                        salt: email,
                    ),
                ),
                upgradeToken: nil,
            ),
        )

        let credentialStore = SDKFido2CredentialStore(vaultClientService: client.vault())
        self.client = client
        self.credentialStore = credentialStore
        return (client, credentialStore)
    }
}
