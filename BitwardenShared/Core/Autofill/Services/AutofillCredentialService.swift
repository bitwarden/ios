import AuthenticationServices
import BitwardenSdk
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
}

/// A default implementation of an `AutofillCredentialService`.
///
class DefaultAutofillCredentialService {
    // MARK: Private Properties

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

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

    /// The last user ID that had their identities synced.
    private var lastSyncedUserId: String?

    /// The service used to manage copy/pasting from the device's clipboard.
    private let pasteboardService: PasteboardService

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
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - eventService: The service to manage events.
    ///   - fido2UserInterfaceHelper: A helper to be used on Fido2 flows that requires user interaction
    ///   and extends the capabilities of the `Fido2UserInterface` from the SDK.
    ///   - fido2CredentialStore: A store to be used on Fido2 flows to get/save credentials.
    ///   - identityStore: The service used to manage the credentials available for AutoFill suggestions.
    ///   - pasteboardService: The service used to manage copy/pasting from the device's clipboard.
    ///   - stateService: The service used by the application to manage account state.
    ///   - vaultTimeoutService: The service used to manage vault access.
    ///
    init(
        cipherService: CipherService,
        clientService: ClientService,
        errorReporter: ErrorReporter,
        eventService: EventService,
        fido2CredentialStore: Fido2CredentialStore,
        fido2UserInterfaceHelper: Fido2UserInterfaceHelper,
        identityStore: CredentialIdentityStore = ASCredentialIdentityStore.shared,
        pasteboardService: PasteboardService,
        stateService: StateService,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.cipherService = cipherService
        self.clientService = clientService
        self.errorReporter = errorReporter
        self.eventService = eventService
        self.fido2CredentialStore = fido2CredentialStore
        self.fido2UserInterfaceHelper = fido2UserInterfaceHelper
        self.identityStore = identityStore
        self.pasteboardService = pasteboardService
        self.stateService = stateService
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
                let identities = decryptedCiphers.compactMap(\.credentialIdentity)
                let fido2Identities = try await clientService.platform().fido2()
                    .authenticator(
                        userInterface: fido2UserInterfaceHelper,
                        credentialStore: fido2CredentialStore
                    )
                    .credentialsForAutofill()
                    .compactMap { $0.toFido2CredentialIdentity() }

                try await identityStore.replaceCredentialIdentities(identities + fido2Identities)
                Logger.application.info("AutofillCredentialService: replaced \(identities.count) credential identities")
            } else {
                let identities = decryptedCiphers.compactMap(\.passwordCredentialIdentity)
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
        let isLocked = vaultTimeoutService.isLocked(userId: userId)
        let vaultTimeout = try? await vaultTimeoutService.sessionTimeoutValue(userId: nil)
        guard vaultTimeout == .never, isLocked else { return }
        try await delegate.unlockVaultWithNeverlockKey()
    }
}

extension DefaultAutofillCredentialService: AutofillCredentialService {
    func provideCredential(
        for id: String,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
        repromptPasswordValidated: Bool
    ) async throws -> ASPasswordCredential {
        try await tryUnlockVaultWithoutUserInteraction(delegate: autofillCredentialServiceDelegate)
        guard try await !vaultTimeoutService.isLocked(userId: stateService.getActiveAccountId()) else {
            throw ASExtensionError(.userInteractionRequired)
        }

        guard let encryptedCipher = try await cipherService.fetchCipher(withId: id) else {
            throw ASExtensionError(.credentialIdentityNotFound)
        }

        let cipher = try await clientService.vault().ciphers().decrypt(cipher: encryptedCipher)
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

        let disableAutoTotpCopy = try await stateService.getDisableAutoTotpCopy()
        let accountHasPremium = try await stateService.doesActiveAccountHavePremium()
        if !disableAutoTotpCopy,
           let totp = cipher.login?.totp,
           cipher.organizationUseTotp || accountHasPremium {
            let codeModel = try await clientService.vault().generateTOTPCode(for: totp, date: nil)
            pasteboardService.copy(codeModel.code)
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

    // MARK: Private

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
        fido2UserInterfaceHelper.setupDelegate(
            fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate
        )
        fido2UserInterfaceHelper.setupCurrentUserVerificationPreference(
            userVerificationPreference: request.options.uv
        )

        #if DEBUG
        Fido2DebuggingReportBuilder.builder.withGetAssertionRequest(request)
        #endif

        do {
            let assertionResult = try await clientService.platform().fido2()
                .authenticator(
                    userInterface: fido2UserInterfaceHelper,
                    credentialStore: fido2CredentialStore
                )
                .getAssertion(request: request)

            #if DEBUG
            Fido2DebuggingReportBuilder.builder.withGetAssertionResult(.success(assertionResult))
            #endif

            return ASPasskeyAssertionCredential(
                userHandle: assertionResult.userHandle,
                relyingParty: rpId,
                signature: assertionResult.signature,
                clientDataHash: clientDataHash,
                authenticatorData: assertionResult.authenticatorData,
                credentialID: assertionResult.credentialId
            )
        } catch {
            #if DEBUG
            Fido2DebuggingReportBuilder.builder.withGetAssertionResult(.failure(error))
            #endif
            throw error
        }
    }
}

// MARK: - CipherView

private extension CipherView {
    @available(iOS 17, *)
    var credentialIdentity: (any ASCredentialIdentity)? {
        guard shouldGetPasswordCredentialIdentity else {
            return nil
        }
        return passwordCredentialIdentity
    }

    var passwordCredentialIdentity: ASPasswordCredentialIdentity? {
        let uris = login?.uris?.filter { $0.match != .never && $0.uri.isEmptyOrNil == false }
        guard let uri = uris?.first?.uri,
              let username = login?.username, !username.isEmpty
        else {
            return nil
        }

        let serviceIdentifier = ASCredentialServiceIdentifier(identifier: uri, type: .URL)
        return ASPasswordCredentialIdentity(
            serviceIdentifier: serviceIdentifier,
            user: username,
            recordIdentifier: id
        )
    }

    /// Whether the `ASPasswordCredentialIdentity` should be gotten.
    /// Otherwise a passkey identity will be provided.
    var shouldGetPasswordCredentialIdentity: Bool {
        !hasFido2Credentials || login?.password != nil
    }
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

// MARK: - ASCredentialIdentityStore+CredentialIdentityStore

extension ASCredentialIdentityStore: CredentialIdentityStore {}
