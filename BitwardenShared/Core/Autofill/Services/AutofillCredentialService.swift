import AuthenticationServices
import BitwardenKit
import BitwardenSdk
import CryptoKit
import OSLog

// swiftlint:disable file_length

/// A delegate to handle autofill credential service operations.
protocol AutofillCredentialServiceDelegate: AnyObject {
    /// Attempts to unlock the user's vault with the stored neverlock key
    func unlockVaultWithNeverlockKey() async throws
}

/// A service which manages the ciphers exposed to the system for AutoFill suggestions.
///
protocol AutofillCredentialService: AnyObject {
    /// Returns whether autofilling credentials via the extension is enabled.
    ///
    func isAutofillCredentialsEnabled() async -> Bool

    /// Returns a `ASPasswordCredential` that matches the user-requested credential which can be
    /// used for autofill.
    ///
    /// - Parameters:
    ///   - id: The identifier of the user-requested credential to return.
    ///   - autofillCredentialServiceDelegate: Delegate for autofill credential operations.
    ///   - repromptPasswordValidated: `true` if master password reprompt was required for the
    ///     cipher and the user's master password was validated.
    /// - Returns: A `ASPasswordCredential` that matches the user-requested credential which can be
    ///     used for autofill.
    ///
    func provideCredential(
        for id: String,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
        repromptPasswordValidated: Bool
    ) async throws -> ASPasswordCredential

    /// Provides a Fido2 credential for a passkey request
    /// - Parameters:
    ///   - passkeyRequest: Request to get the credential.
    ///   - autofillCredentialServiceDelegate: Delegate for autofill credential operations.
    ///   - fido2UserInterfaceHelperDelegate: Delegate for Fido2 user interface interaction.
    /// - Returns: The passkey credential for assertion.
    @available(iOS 17.0, *)
    func provideFido2Credential(
        for passkeyRequest: ASPasskeyCredentialRequest,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
        fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate
    ) async throws -> ASPasskeyAssertionCredential

    /// Provides a Fido2 credential for Fido2 request parameters.
    /// - Parameters:
    ///   - fido2RequestParameters: The Fido2 request parameters to ge the assertion credential.
    ///   - fido2UserInterfaceHelperDelegate: Delegate for Fido2 user interface interaction
    /// - Returns: The passkey credential for assertion
    @available(iOS 17.0, *)
    func provideFido2Credential(
        for fido2RequestParameters: PasskeyCredentialRequestParameters,
        fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate
    ) async throws -> ASPasskeyAssertionCredential

    /// Returns a `ASOneTimeCodeCredential` that matches the user-requested credential which can be
    /// used for autofill.
    ///
    /// - Parameters:
    ///   - id: The identifier of the user-requested credential to return.
    ///   - autofillCredentialServiceDelegate: Delegate for autofill credential operations.
    ///   - repromptPasswordValidated: `true` if master password reprompt was required for the
    ///     cipher and the user's master password was validated.
    /// - Returns: A `ASOneTimeCodeCredential` that matches the user-requested credential which can be
    ///     used for autofill.
    ///
    @available(iOS 18.0, *)
    func provideOTPCredential(
        for id: String,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
        repromptPasswordValidated: Bool
    ) async throws -> ASOneTimeCodeCredential
}

/// A default implementation of an `AutofillCredentialService`.
///
class DefaultAutofillCredentialService {
    // MARK: Private Properties

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The factory to create credential identities.
    private let credentialIdentityFactory: CredentialIdentityFactory

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service to manage events.
    private let eventService: EventService

    /// A store to be used on Fido2 flows to get/save credentials.
    private let fido2CredentialStore: Fido2CredentialStore

    /// A helper to be used on Fido2 flows that requires user interaction and extends the capabilities
    /// of the `Fido2UserInterface` from the SDK.
    private let fido2UserInterfaceHelper: Fido2UserInterfaceHelper

    /// The service used to manage the credentials available for AutoFill suggestions.
    private let identityStore: CredentialIdentityStore

    private let keychainRepository: KeychainRepository
    
    /// The last user ID that had their identities synced.
    private var lastSyncedUserId: String?

    /// The service used to manage copy/pasting from the device's clipboard.
    private let pasteboardService: PasteboardService

    /// Provides the present time.
    private let timeProvider: TimeProvider

    /// The service used by the application to validate TOTP keys and produce TOTP values
    private let totpService: TOTPService

    /// The service used by the application to manage account state.
    private let stateService: StateService
    
    /// A reference to the task used to sync the user's ciphers to the identity store. This allows
    /// the task to be cancelled and recreated when the user changes.
    private var syncTask: Task<Void, Never>?

    /// The service used to manage vault access.
    private let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize an `AutofillCredentialService`.
    ///
    /// - Parameters:
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - credentialIdentityFactory: The factory to create credential identities.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - eventService: The service to manage events.
    ///   - fido2UserInterfaceHelper: A helper to be used on Fido2 flows that requires user interaction
    ///   and extends the capabilities of the `Fido2UserInterface` from the SDK.
    ///   - fido2CredentialStore: A store to be used on Fido2 flows to get/save credentials.
    ///   - identityStore: The service used to manage the credentials available for AutoFill suggestions.
    ///   - keychainRepository: The service used to manage the credentials available for AutoFill suggestions.
    ///   - pasteboardService: The service used to manage copy/pasting from the device's clipboard.
    ///   - stateService: The service used by the application to manage account state.
    ///   - timeProvider: Provides the present time.
    ///   - totpService: The service used by the application to validate TOTP keys and produce TOTP values.
    ///   - vaultTimeoutService: The service used to manage vault access.
    ///
    init(
        cipherService: CipherService,
        clientService: ClientService,
        credentialIdentityFactory: CredentialIdentityFactory,
        errorReporter: ErrorReporter,
        eventService: EventService,
        fido2CredentialStore: Fido2CredentialStore,
        fido2UserInterfaceHelper: Fido2UserInterfaceHelper,
        identityStore: CredentialIdentityStore = ASCredentialIdentityStore.shared,
        keychainRepository: KeychainRepository,
        pasteboardService: PasteboardService,
        stateService: StateService,
        timeProvider: TimeProvider,
        totpService: TOTPService,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.cipherService = cipherService
        self.clientService = clientService
        self.credentialIdentityFactory = credentialIdentityFactory
        self.errorReporter = errorReporter
        self.eventService = eventService
        self.fido2CredentialStore = fido2CredentialStore
        self.fido2UserInterfaceHelper = fido2UserInterfaceHelper
        self.identityStore = identityStore
        self.keychainRepository = keychainRepository
        self.pasteboardService = pasteboardService
        self.stateService = stateService
        self.timeProvider = timeProvider
        self.totpService = totpService
        self.vaultTimeoutService = vaultTimeoutService

        Task {
            for await vaultLockStatus in await self.vaultTimeoutService.vaultLockStatusPublisher().values {
                syncIdentities(vaultLockStatus: vaultLockStatus)
            }
        }
    }

    // MARK: Private Methods

    /// Synchronizes the identities in the identity store for the user with the specified lock status.
    ///
    /// - If the user's vault is unlocked, identities in the store will be replaced by the user's identities.
    /// - If the user's vault is locked, there's no changes to the identity store.
    /// - If there's no active user, all identities are removed from the store.
    ///
    /// - Parameter vaultLockStatus: The locked status of the active user's vault, or `nil` if
    ///     there is no active user.
    ///
    private func syncIdentities(vaultLockStatus: VaultLockStatus?) {
        syncTask?.cancel()
        syncTask = Task {
            if let vaultLockStatus, !vaultLockStatus.isVaultLocked {
                do {
                    for try await _ in try await self.cipherService.ciphersPublisher().values {
                        await replaceAllIdentities(userId: vaultLockStatus.userId)
                    }
                } catch {
                    errorReporter.log(error: error)
                }
            } else if shouldRemoveAllIdentities(vaultLockStatus: vaultLockStatus) {
                await removeAllIdentities()
                lastSyncedUserId = nil
            }
        }
    }

    /// Removes all credential identities from the identity store.
    ///
    private func removeAllIdentities() async {
        guard await identityStore.state().isEnabled else { return }

        do {
            Logger.application.info("AutofillCredentialService: removing all credential identities")
            try await identityStore.removeAllCredentialIdentities()
        } catch {
            errorReporter.log(error: error)
        }
    }

    /// Replaces all credential identities in the identity store with the current list of ciphers
    /// for the user.
    ///
    /// - Parameter userId: The ID of the user whose ciphers should be added to the identity store.
    ///
    private func replaceAllIdentities(userId: String) async {
        guard await identityStore.state().isEnabled else { return }

        do {
            Logger.application.info("AutofillCredentialService: replacing all credential identities")

            let decryptedCiphers = try await cipherService.fetchAllCiphers()
                .filter { $0.type == .login && $0.deletedDate == nil }
                .asyncMap { cipher in
                    try await self.clientService.vault().ciphers().decrypt(cipher: cipher)
                }

            if #available(iOS 17, *) {
                var identities = [ASCredentialIdentity]()
                for cipher in decryptedCiphers {
                    let newIdentities = await credentialIdentityFactory.createCredentialIdentities(from: cipher)
                    identities.append(contentsOf: newIdentities)
                }

                let fido2Identities = try await clientService.platform().fido2()
                    .authenticator(
                        userInterface: fido2UserInterfaceHelper,
                        credentialStore: fido2CredentialStore
                    )
                    .credentialsForAutofill()
                    .compactMap { $0.toFido2CredentialIdentity() }
                identities.append(contentsOf: fido2Identities)

                try await identityStore.replaceCredentialIdentities(identities)
                Logger.application.info("AutofillCredentialService: replaced \(identities.count) credential identities")
            } else {
                let identities = decryptedCiphers.compactMap { cipher in
                    credentialIdentityFactory.tryCreatePasswordCredentialIdentity(from: cipher)
                }
                try await identityStore.replaceCredentialIdentities(with: identities)
                Logger.application.info("AutofillCredentialService: replaced \(identities.count) credential identities")
            }
            lastSyncedUserId = userId
        } catch {
            errorReporter.log(error: error)
        }
    }

    /// Determines whether all identities in store should be removed.
    /// - Parameter vaultLockStatus: The vault lock status from the publisher.
    /// - Returns: `true` if all identities should be removed, `false` otherwise.
    private func shouldRemoveAllIdentities(vaultLockStatus: VaultLockStatus?) -> Bool {
        guard let vaultLockStatus else {
            return true
        }

        guard let lastSyncedUserId else {
            return false
        }

        return vaultLockStatus.isVaultLocked && lastSyncedUserId != vaultLockStatus.userId
    }

    /// Attempts to unlock the user's vault if it can be done without user interaction (e.g. if
    /// the user uses never lock).
    ///
    /// - Parameter delegate: The delegate used for autofill credential operations.
    ///
    private func tryUnlockVaultWithoutUserInteraction(delegate: AutofillCredentialServiceDelegate) async throws {
        let userId = try await stateService.getActiveAccountId()
        let isLocked = await vaultTimeoutService.isLocked(userId: userId)
        let isManuallyLocked = await (try? stateService.getManuallyLockedAccount(userId: userId)) == true
        let vaultTimeout = try? await vaultTimeoutService.sessionTimeoutValue(userId: nil)
        guard vaultTimeout == .never, isLocked, !isManuallyLocked else {
            return
        }
        try await delegate.unlockVaultWithNeverlockKey()
    }
}

extension DefaultAutofillCredentialService: AutofillCredentialService {
    func isAutofillCredentialsEnabled() async -> Bool {
        await identityStore.isAutofillEnabled()
    }

    func provideCredential(
        for id: String,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
        repromptPasswordValidated: Bool
    ) async throws -> ASPasswordCredential {
        let cipher = try await checkUnlockAndGetCipherToProvideCredential(
            for: id,
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate
        )
        guard cipher.type == .login,
              cipher.login != nil,
              let username = cipher.login?.username,
              let password = cipher.login?.password
        else {
            throw ASExtensionError(.credentialIdentityNotFound)
        }

        guard cipher.reprompt == .none || repromptPasswordValidated else {
            throw ASExtensionError(.userInteractionRequired)
        }

        do {
            try await totpService.copyTotpIfPossible(cipher: cipher)
        } catch {
            errorReporter.log(error: error)
        }

        await eventService.collect(
            eventType: .cipherClientAutofilled,
            cipherId: cipher.id
        )

        return ASPasswordCredential(user: username, password: password)
    }

    @available(iOS 17.0, *)
    func provideFido2Credential(
        for passkeyRequest: ASPasskeyCredentialRequest,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
        fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate
    ) async throws -> ASPasskeyAssertionCredential {
        guard let credentialIdentity = passkeyRequest.credentialIdentity as? ASPasskeyCredentialIdentity else {
            throw AppProcessorError.invalidOperation
        }

        try await tryUnlockVaultWithoutUserInteraction(delegate: autofillCredentialServiceDelegate)
        guard try await !vaultTimeoutService.isLocked(userId: stateService.getActiveAccountId()) else {
            throw Fido2Error.userInteractionRequired
        }

        let request = GetAssertionRequest(
            passkeyRequest: passkeyRequest, credentialIdentity: credentialIdentity
        )
        
        return try await provideFido2Credential(
            with: request,
            fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate,
            rpId: credentialIdentity.relyingPartyIdentifier,
            clientDataHash: passkeyRequest.clientDataHash
        )
    }

    @available(iOS 17.0, *)
    func provideFido2Credential(
        for fido2RequestParameters: PasskeyCredentialRequestParameters,
        fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate
    ) async throws -> ASPasskeyAssertionCredential {
        try await provideFido2Credential(
            with: GetAssertionRequest(fido2RequestParameters: fido2RequestParameters),
            fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate,
            rpId: fido2RequestParameters.relyingPartyIdentifier,
            clientDataHash: fido2RequestParameters.clientDataHash
        )
    }

    @available(iOS 18.0, *)
    func provideOTPCredential(
        for id: String,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
        repromptPasswordValidated: Bool
    ) async throws -> ASOneTimeCodeCredential {
        let cipher = try await checkUnlockAndGetCipherToProvideCredential(
            for: id,
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate
        )
        guard cipher.type == .login, let totpKey = cipher.login?.totp else {
            throw ASExtensionError(.credentialIdentityNotFound)
        }

        guard cipher.reprompt == .none || repromptPasswordValidated else {
            throw ASExtensionError(.userInteractionRequired)
        }

        guard let vault = try? await clientService.vault(),
              let code = try? vault.generateTOTPCode(for: totpKey, date: timeProvider.presentTime) else {
            throw ASExtensionError(.credentialIdentityNotFound)
        }

        await eventService.collect(
            eventType: .cipherClientAutofilled,
            cipherId: cipher.id
        )

        return ASOneTimeCodeCredential(code: code.code)
    }

    // MARK: Private

    /// Checks if the vault is locked, unlocking if never session timeout and gets the decrypted cipher
    /// to provider the credential out of it.
    /// - Parameters:
    ///   - id: The `id` of the credential to provide.
    ///   - autofillCredentialServiceDelegate: Delegate for autofill credential operations.
    /// - Returns: The decrypted cipher to provide the credential.
    private func checkUnlockAndGetCipherToProvideCredential(
        for id: String,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate
    ) async throws -> CipherView {
        try await tryUnlockVaultWithoutUserInteraction(delegate: autofillCredentialServiceDelegate)
        guard try await !vaultTimeoutService.isLocked(userId: stateService.getActiveAccountId()) else {
            throw ASExtensionError(.userInteractionRequired)
        }

        guard let encryptedCipher = try await cipherService.fetchCipher(withId: id) else {
            throw ASExtensionError(.credentialIdentityNotFound)
        }

        return try await clientService.vault().ciphers().decrypt(cipher: encryptedCipher)
    }

    /// Provides a Fido2 credential based for the given request.
    /// - Parameters:
    ///   - request: Request to get the assertion credential.
    ///   - fido2UserInterfaceHelperDelegate: Delegate for Fido2 user interface interaction.
    ///   - rpId: The relying party identifier of the request.
    ///   - clientDataHash: The client data hash of the request.
    /// - Returns: The passkey assertion credential for the request.
    @available(iOS 17.0, *)
    private func provideFido2Credential(
        with request: GetAssertionRequest,
        fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate,
        rpId: String,
        clientDataHash: Data
    ) async throws -> ASPasskeyAssertionCredential {
        let logger = Logger()
        logger.info("Starting provideFido2Credential")
        await fido2UserInterfaceHelper.setupDelegate(
            fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate
        )
        await fido2UserInterfaceHelper.setupCurrentUserVerificationPreference(
            userVerificationPreference: request.options.uv
        )

        #if DEBUG
        Fido2DebuggingReportBuilder.builder.withGetAssertionRequest(request)
        #endif

        do {
            let devicePasskeyResult = try await useDevicePasskey(for: request, rpId: rpId, clientDataHash: clientDataHash)
            let (assertionResult, prfResult): (GetAssertionResult, Data?) = if let devicePasskeyResult {
                devicePasskeyResult
            } else {
                (try await clientService.platform().fido2()
                    .authenticator(
                        userInterface: fido2UserInterfaceHelper,
                        credentialStore: fido2CredentialStore
                    )
                    .getAssertion(request: request)
                , nil as Data?)
            }
            
            print(request)
            logger.debug("clientDataHash: \(request.clientDataHash.base64EncodedString())")
            logger.debug("rpId: \(request.rpId)")
            logger.debug("Passkey result")
            logger.debug("authData: \(assertionResult.authenticatorData.base64EncodedString())")
            logger.debug("credId: \(assertionResult.credentialId.base64EncodedString())")
            logger.debug("signature: \(assertionResult.signature.base64EncodedString())")
            logger.debug("userHandle: \(assertionResult.userHandle.base64EncodedString())")
            logger.debug("prfResult: \(prfResult?.base64EncodedString() ?? "<null>")")

            #if DEBUG
            Fido2DebuggingReportBuilder.builder.withGetAssertionResult(.success(assertionResult))
            #endif

            do {
                try await totpService.copyTotpIfPossible(cipher: assertionResult.selectedCredential.cipher)
            } catch {
                errorReporter.log(error: error)
            }
            
            
            if #available(iOSApplicationExtension 18.0, *) {
                let extOutput = if let prfResult {
                    ASPasskeyAssertionCredentialExtensionOutput(
                        largeBlob: nil,
                        prf: ASAuthorizationPublicKeyCredentialPRFAssertionOutput(first: SymmetricKey(data: prfResult), second: nil))
                }
                else {
                    nil as ASPasskeyAssertionCredentialExtensionOutput?
                }
                return ASPasskeyAssertionCredential(
                    userHandle: assertionResult.userHandle,
                    relyingParty: rpId,
                    signature: assertionResult.signature,
                    clientDataHash: clientDataHash,
                    authenticatorData: assertionResult.authenticatorData,
                    credentialID: assertionResult.credentialId,
                    extensionOutput: extOutput,
                )
            }
            else {
                return ASPasskeyAssertionCredential(
                    userHandle: assertionResult.userHandle,
                    relyingParty: rpId,
                    signature: assertionResult.signature,
                    clientDataHash: clientDataHash,
                    authenticatorData: assertionResult.authenticatorData,
                    credentialID: assertionResult.credentialId,
                )
            }
        } catch {
            #if DEBUG
            Fido2DebuggingReportBuilder.builder.withGetAssertionResult(.failure(error))
            #endif
            throw error
        }
    }
    
    private func useDevicePasskey(for request: GetAssertionRequest, rpId: String, clientDataHash: Data) async throws -> (GetAssertionResult, Data?)? {
        // let webVaultRpId = services.environmentService.webVaultURL.domain
        let webVaultRpId = "localhost"
        guard webVaultRpId == rpId else { return nil }
        guard let json = try await keychainRepository.getDevicePasskey(userId: stateService.getActiveAccountId()) else {
            print("Matched Bitwarden Web Vault rpID, but no device passkey found. Forwarding to main implementation")
            return nil
        }
        
        let decoder = JSONDecoder()
        let loginWithPrfSalt = Data(SHA256.hash(data: "passwordless-login".data(using: .utf8)!))
        let saltInput1 = try getPrfInput(extensionsInput: request.extensions) ?? loginWithPrfSalt
        let record: DevicePasskeyRecord = try decoder.decode(DevicePasskeyRecord.self, from: json.data(using: .utf8)!)
        
        // extensions
        // prf
        let prfSeed = Data(base64Encoded: record.prfSeed)!
        let saltPrefix = "WebAuthn PRF\0".data(using: .utf8)!
        // hard-coding instead of parsing extensions from request
        let salt1 = saltPrefix + saltInput1
        // This should be encrypted with a shared secret between the client and authenticator so that the RP doesn't see the PRF output. Skipping that for now.
        let prfResult = Data(HMAC<SHA256>.authenticationCode(for: salt1, using: SymmetricKey(data: prfSeed)))
        var extensions = Data()
        /*
        extensions.append(contentsOf:[
            0xA1, // map, length 1
              0x63, 0x70, 0x72, 0x66, // string, len 3 "prf"
                0xA1, // map, length 1
                  0x67, 0x72, 0x65, 0x73, 0x75, 0x6c, 0x74, 0x73, // text, length 7 "results
                    0xA1, // map, length 1
                      0x65, 0x66, 0x69, 0x72, 0x73, 0x74, // text, length 5, "first"
                        0x58, 0x20, // bytes, length 32
        ])
        extensions.append(contentsOf: prfResult)
         */

        // authenticatorData
        let rpIdHash = Data(SHA256.hash(data: rpId.data(using: .utf8)!))
        let flags = 0b0001_1101 // UV, UP, BE and BS also set because macOS requires it :(
        let signCount = UInt32(0)
        let authData = rpIdHash + UInt8(flags).bytes + signCount.bytes // + extensions
        
        // signature
        let payload = authData + request.clientDataHash
        let privKey = try P256.Signing.PrivateKey(rawRepresentation: Data(base64Encoded: record.privKey)!)
        let sig = try privKey.signature(for: payload).derRepresentation
        
        // attestation object
        var attObj = Data()
        attObj.append(contentsOf: [
            0xA3, // map, length 3
              0x63, 0x66, 0x6d, 0x74, // string, len 3 "fmt"
                0x66, 0x70, 0x61, 0x63, 0x6b, 0x65, 0x64, // string, len 6, "packed"
              0x67, 0x61, 0x74, 0x74, 0x53, 0x74, 0x6d, 0x74, // string, len 7, "attStmt"
                0xA2, // map, length 2
                  0x63, 0x61, 0x6c, 0x67, // string, len 3, "alg"
                    0x26, // -7 (P256)
                  0x63, 0x73, 0x69, 0x67, // string, len 3, "sig"
                  0x58, // bytes, length specified in following byte
        ])
        attObj.append(contentsOf: UInt8(sig.count).bytes)
        attObj.append(contentsOf: sig)
        attObj.append(contentsOf:[
              0x68, 0x61, 0x75, 0x74, 0x68, 0x44, 0x61, 0x74, 0x61, // string, len 8, "authData"
                0x58, // bytes, length specified in following byte.
        ])
        attObj.append(contentsOf: UInt8(authData.count).bytes)
        attObj.append(contentsOf: authData)
        let fido2View = Fido2CredentialView(
            credentialId: record.credId,
            keyType: "public-key",
            keyAlgorithm: "ECDSA",
            keyCurve: "P-256",
            keyValue: EncString(),
            rpId: record.rpId,
            userHandle: nil,
            userName: nil,
            counter: "0",
            rpName: nil,
            userDisplayName: nil,
            discoverable: "true",
            creationDate: record.creationDate,
        )
        let fido2NewView = Fido2CredentialNewView(
            credentialId: record.credId,
            keyType: "public-key",
            keyAlgorithm: "ECDSA",
            keyCurve: "P-256",
            rpId: record.rpId,
            userHandle: nil,
            userName: nil,
            counter: "0",
            rpName: nil,
            userDisplayName: nil,
            creationDate: record.creationDate,
        )
        let credId = Data(base64Encoded: record.credId)!
        let userHandle = Data(base64Encoded: record.userId!)!
        let result = GetAssertionResult(
            credentialId: credId,
            authenticatorData: authData,
            signature: sig,
            userHandle: userHandle,
            selectedCredential: SelectedCredential(cipher: CipherView(fido2CredentialNewView: fido2NewView, timeProvider: CurrentTime()), credential: fido2View),
        )
        return (result, prfResult)
        // Even though prfResult is included in extensions, we'd have to parse CBOR, so just including it for now
        // return DevicePasskeyResult(credential: result, privKey: privKey, prfSeed: prfSeed, prfResult: prfResult)
    }
}

private func getPrfInput(extensionsInput extensions: String?) throws -> Data? {
    guard let extensions else { return nil }
    let decoder = JSONDecoder()
    let extInputs = try decoder.decode(AuthenticationExtensionsClientInputs.self, from: extensions.data(using: .utf8)!)
    guard let first = extInputs.prf?.eval?.first else { return nil }
    return Data(base64Encoded: first)
}

// MARK: - CredentialIdentityStore

/// A protocol for a store which makes credential identities available via the AutoFill suggestions.
///
protocol CredentialIdentityStore {
    /// Removes all existing credential identities from the store.
    ///
    func removeAllCredentialIdentities() async throws

    /// Replaces existing credential identities with new credential identities.
    ///
    /// - Parameter newCredentialIdentities: The new credential identities.
    ///
    @available(iOS 17, *)
    func replaceCredentialIdentities(_ newCredentialIdentities: [ASCredentialIdentity]) async throws

    /// Replaces existing credential identities with new credential identities.
    ///
    /// - Parameter newCredentialIdentities: The new credential identities.
    ///
    func replaceCredentialIdentities(with newCredentialIdentities: [ASPasswordCredentialIdentity]) async throws

    /// Gets the state of the credential identity store.
    ///
    /// - Returns: The state of the credential identity store.
    ///
    func state() async -> ASCredentialIdentityStoreState
}

extension CredentialIdentityStore {
    /// Returns whether autofilling credentials via the extension is enabled.
    ///
    func isAutofillEnabled() async -> Bool {
        await state().isEnabled
    }
}

// MARK: - ASCredentialIdentityStore+CredentialIdentityStore

extension ASCredentialIdentityStore: CredentialIdentityStore {}
