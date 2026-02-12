import AuthenticationServices
import BitwardenKit
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
        repromptPasswordValidated: Bool,
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
        fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate,
    ) async throws -> ASPasskeyAssertionCredential

    /// Provides a Fido2 credential for Fido2 request parameters.
    /// - Parameters:
    ///   - fido2RequestParameters: The Fido2 request parameters to ge the assertion credential.
    ///   - fido2UserInterfaceHelperDelegate: Delegate for Fido2 user interface interaction
    /// - Returns: The passkey credential for assertion
    @available(iOS 17.0, *)
    func provideFido2Credential(
        for fido2RequestParameters: PasskeyCredentialRequestParameters,
        fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate,
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
        repromptPasswordValidated: Bool,
    ) async throws -> ASOneTimeCodeCredential

    /// Updates all credential identities in the identity store with the current list of ciphers
    /// for the current user.
    ///
    func updateCredentialsInStore() async
}

/// A default implementation of an `AutofillCredentialService`.
///
class DefaultAutofillCredentialService {
    // MARK: Computed properties

    /// Whether the cipher changes publisher has been subscribed to. This is useful for tests.
    var hasCipherChangesSubscription: Bool {
        cipherChangesSubscriptionTask != nil && !(cipherChangesSubscriptionTask?.isCancelled ?? true)
    }

    // MARK: Private Properties

    /// Helper to know about the app context.
    private let appContextHelper: AppContextHelper

    /// A reference to the task used to track cipher changes.
    private var cipherChangesSubscriptionTask: Task<Void, Never>?

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service to get server-specified configuration.
    private let configService: ConfigService

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

    /// The service used by the application for recording temporary debug logs.
    private let flightRecorder: FlightRecorder

    /// The service used to manage the credentials available for AutoFill suggestions.
    private let identityStore: CredentialIdentityStore

    /// The last user ID that had their identities synced.
    private(set) var lastSyncedUserId: String?

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
    ///   - appContextHelper: The helper to know about the app context.
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - configService: The service to get server-specified configuration.
    ///   - credentialIdentityFactory: The factory to create credential identities.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - eventService: The service to manage events.
    ///   - fido2UserInterfaceHelper: A helper to be used on Fido2 flows that requires user interaction
    ///   and extends the capabilities of the `Fido2UserInterface` from the SDK.
    ///   - fido2CredentialStore: A store to be used on Fido2 flows to get/save credentials.
    ///   - flightRecorder: The service used by the application for recording temporary debug logs.
    ///   - identityStore: The service used to manage the credentials available for AutoFill suggestions.
    ///   - pasteboardService: The service used to manage copy/pasting from the device's clipboard.
    ///   - stateService: The service used by the application to manage account state.
    ///   - timeProvider: Provides the present time.
    ///   - totpService: The service used by the application to validate TOTP keys and produce TOTP values.
    ///   - vaultTimeoutService: The service used to manage vault access.
    ///
    init(
        appContextHelper: AppContextHelper,
        cipherService: CipherService,
        clientService: ClientService,
        configService: ConfigService,
        credentialIdentityFactory: CredentialIdentityFactory,
        errorReporter: ErrorReporter,
        eventService: EventService,
        fido2CredentialStore: Fido2CredentialStore,
        fido2UserInterfaceHelper: Fido2UserInterfaceHelper,
        flightRecorder: FlightRecorder,
        identityStore: CredentialIdentityStore = ASCredentialIdentityStore.shared,
        pasteboardService: PasteboardService,
        stateService: StateService,
        timeProvider: TimeProvider,
        totpService: TOTPService,
        vaultTimeoutService: VaultTimeoutService,
    ) {
        self.appContextHelper = appContextHelper
        self.cipherService = cipherService
        self.clientService = clientService
        self.configService = configService
        self.credentialIdentityFactory = credentialIdentityFactory
        self.errorReporter = errorReporter
        self.eventService = eventService
        self.fido2CredentialStore = fido2CredentialStore
        self.fido2UserInterfaceHelper = fido2UserInterfaceHelper
        self.flightRecorder = flightRecorder
        self.identityStore = identityStore
        self.pasteboardService = pasteboardService
        self.stateService = stateService
        self.timeProvider = timeProvider
        self.totpService = totpService
        self.vaultTimeoutService = vaultTimeoutService

        guard appContextHelper.appContext == .mainApp else {
            // NOTE: [PM-28855] when in the context of iOS extensions
            // subscribe to individual cipher changes to update the local OS store
            // to improve memory performance and avoid crashes by not loading
            // nor potentially decrypting the whole vault.
            subscribeToCipherChanges()
            return
        }

        Task {
            for await vaultLockStatus in await self.vaultTimeoutService.vaultLockStatusPublisher().values {
                syncIdentities(vaultLockStatus: vaultLockStatus)
            }
        }
    }

    /// Deinitializes this service.
    deinit {
        cipherChangesSubscriptionTask?.cancel()
        cipherChangesSubscriptionTask = nil
    }

    // MARK: Private Methods

    /// Subscribes to cipher changes to update the internal `ASCredentialIdentityStore`.
    private func subscribeToCipherChanges() {
        cipherChangesSubscriptionTask?.cancel()
        cipherChangesSubscriptionTask = Task { [weak self] in
            guard let self, #available(iOS 17.0, *) else {
                return
            }

            do {
                for try await cipherChange in try await cipherService.cipherChangesPublisher().values {
                    await flightRecorder.log(
                        "[AutofillCredentialService] Received cipher change \(cipherChange.debugDescription)",
                    )
                    switch cipherChange {
                    case let .deleted(cipher):
                        await removeCredentialsInStore(for: cipher)
                    case let .upserted(cipher):
                        await upsertCredentialsInStore(for: cipher)
                    case .replacedAll:
                        // NOTE: [PM-28855] Since the cipher changes subscription is only used in the
                        // extension, don't replace all credentials since it can be memory intensive.
                        break
                    }
                }
            } catch {
                errorReporter.log(error: error)
            }
        }
    }

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
            await flightRecorder.log("[AutofillCredentialService] Removing all credential identities")
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
            await flightRecorder.log("[AutofillCredentialService] Replacing all credential identities")

            let archiveItemsFeatureFlagEnabled: Bool = await configService.getFeatureFlag(.archiveVaultItems)

            let decryptedCiphers = try await cipherService.fetchAllCiphers()
                .filter { $0.type == .login && !$0.isHiddenWithArchiveFF(flag: archiveItemsFeatureFlagEnabled) }
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
                    .vaultAuthenticator(
                        userInterface: fido2UserInterfaceHelper,
                        credentialStore: fido2CredentialStore,
                    )
                    .credentialsForAutofill()
                    .compactMap { $0.toFido2CredentialIdentity() }
                identities.append(contentsOf: fido2Identities)

                try await identityStore.replaceCredentialIdentities(identities)
                await flightRecorder.log(
                    "[AutofillCredentialService] Replaced \(identities.count) credential identities",
                )
            } else {
                let identities = decryptedCiphers.compactMap { cipher in
                    credentialIdentityFactory.tryCreatePasswordCredentialIdentity(from: cipher)
                }
                try await identityStore.replaceCredentialIdentities(with: identities)
                await flightRecorder.log(
                    "[AutofillCredentialService] Replaced \(identities.count) credential identities",
                )
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
        repromptPasswordValidated: Bool,
    ) async throws -> ASPasswordCredential {
        let cipher = try await checkUnlockAndGetCipherToProvideCredential(
            for: id,
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
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
            cipherId: cipher.id,
        )

        return ASPasswordCredential(user: username, password: password)
    }

    @available(iOS 17.0, *)
    func provideFido2Credential(
        for passkeyRequest: ASPasskeyCredentialRequest,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
        fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate,
    ) async throws -> ASPasskeyAssertionCredential {
        guard let credentialIdentity = passkeyRequest.credentialIdentity as? ASPasskeyCredentialIdentity else {
            throw AppProcessorError.invalidOperation
        }

        try await tryUnlockVaultWithoutUserInteraction(delegate: autofillCredentialServiceDelegate)
        guard try await !vaultTimeoutService.isLocked(userId: stateService.getActiveAccountId()) else {
            throw Fido2Error.userInteractionRequired
        }

        let request = GetAssertionRequest(
            passkeyRequest: passkeyRequest, credentialIdentity: credentialIdentity,
        )

        return try await provideFido2Credential(
            with: request,
            fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate,
            rpId: credentialIdentity.relyingPartyIdentifier,
            clientDataHash: passkeyRequest.clientDataHash,
        )
    }

    @available(iOS 17.0, *)
    func provideFido2Credential(
        for fido2RequestParameters: PasskeyCredentialRequestParameters,
        fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate,
    ) async throws -> ASPasskeyAssertionCredential {
        try await provideFido2Credential(
            with: GetAssertionRequest(fido2RequestParameters: fido2RequestParameters),
            fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate,
            rpId: fido2RequestParameters.relyingPartyIdentifier,
            clientDataHash: fido2RequestParameters.clientDataHash,
        )
    }

    @available(iOS 18.0, *)
    func provideOTPCredential(
        for id: String,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
        repromptPasswordValidated: Bool,
    ) async throws -> ASOneTimeCodeCredential {
        let cipher = try await checkUnlockAndGetCipherToProvideCredential(
            for: id,
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
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
            cipherId: cipher.id,
        )

        return ASOneTimeCodeCredential(code: code.code)
    }

    func updateCredentialsInStore() async {
        do {
            let userId = try await stateService.getActiveAccountId()
            await replaceAllIdentities(userId: userId)
        } catch {
            errorReporter.log(error: error)
        }
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
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
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

    /// Gets the credential identities for a given cipher.
    /// - Parameter cipher: The cipher to get the credential identities from.
    /// - Returns: A list of credential identities for the cipher.
    @available(iOS 17.0, *)
    private func getCredentialIdentities(from cipher: Cipher) async throws -> [ASCredentialIdentity] {
        var identities = [ASCredentialIdentity]()
        let decryptedCipher = try await clientService.vault().ciphers().decrypt(cipher: cipher)

        let newIdentities = await credentialIdentityFactory.createCredentialIdentities(from: decryptedCipher)
        identities.append(contentsOf: newIdentities)

        let fido2Identities = try await clientService.platform().fido2()
            .vaultAuthenticator(
                userInterface: fido2UserInterfaceHelper,
                credentialStore: fido2CredentialStore,
            )
            .credentialsForAutofill()
            .filter { $0.cipherId == cipher.id }
            .compactMap { $0.toFido2CredentialIdentity() }
        identities.append(contentsOf: fido2Identities)

        return identities
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
        clientDataHash: Data,
    ) async throws -> ASPasskeyAssertionCredential {
        await fido2UserInterfaceHelper.setupDelegate(
            fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate,
        )
        await fido2UserInterfaceHelper.setupCurrentUserVerificationPreference(
            userVerificationPreference: request.options.uv,
        )

        #if DEBUG
        Fido2DebuggingReportBuilder.builder.withGetAssertionRequest(request)
        #endif

        do {
            let assertionResult = try await clientService.platform().fido2()
                .vaultAuthenticator(
                    userInterface: fido2UserInterfaceHelper,
                    credentialStore: fido2CredentialStore,
                )
                .getAssertion(request: request)

            #if DEBUG
            Fido2DebuggingReportBuilder.builder.withGetAssertionResult(.success(assertionResult))
            #endif

            do {
                try await totpService.copyTotpIfPossible(cipher: assertionResult.selectedCredential.cipher)
            } catch {
                errorReporter.log(error: error)
            }

            return ASPasskeyAssertionCredential(
                userHandle: assertionResult.userHandle,
                relyingParty: rpId,
                signature: assertionResult.signature,
                clientDataHash: clientDataHash,
                authenticatorData: assertionResult.authenticatorData,
                credentialID: assertionResult.credentialId,
            )
        } catch {
            #if DEBUG
            Fido2DebuggingReportBuilder.builder.withGetAssertionResult(.failure(error))
            #endif
            throw error
        }
    }

    /// Removes the credential identities associated with the cipher on the store.
    /// - Parameter cipher: The cipher to get the credential identities from.
    @available(iOS 17.0, *)
    private func removeCredentialsInStore(for cipher: Cipher) async {
        guard await identityStore.state().isEnabled,
              await identityStore.state().supportsIncrementalUpdates else {
            return
        }

        do {
            let identities = try await getCredentialIdentities(from: cipher)
            try await identityStore.removeCredentialIdentities(identities)

            await flightRecorder.log(
                "[AutofillCredentialService] Removed \(identities.count) identities from \(cipher.id ?? "nil")",
            )
        } catch {
            errorReporter.log(error: error)
        }
    }

    /// Adds/Updates the credential identities associated with the cipher on the store.
    /// - Parameter cipher: The cipher to get the credential identities from.
    @available(iOS 17.0, *)
    private func upsertCredentialsInStore(for cipher: Cipher) async {
        guard await identityStore.state().isEnabled,
              await identityStore.state().supportsIncrementalUpdates else {
            return
        }

        do {
            let identities = try await getCredentialIdentities(from: cipher)
            try await identityStore.saveCredentialIdentities(identities)

            await flightRecorder.log(
                "[AutofillCredentialService] Upserted \(identities.count) identities from \(cipher.id ?? "nil")",
            )
        } catch {
            errorReporter.log(error: error)
        }
    }
}

// MARK: - CredentialIdentityStore

/// A protocol for a store which makes credential identities available via the AutoFill suggestions.
///
protocol CredentialIdentityStore {
    /// Removes all existing credential identities from the store.
    ///
    func removeAllCredentialIdentities() async throws

    /// Remove the given credential identities from the store.
    ///
    /// - Parameter credentialIdentities: A list of credential identities to remove.
    ///
    @available(iOS 17.0, *)
    func removeCredentialIdentities(_ credentialIdentities: [any ASCredentialIdentity]) async throws

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

    /// Save the supplied credential identities to the store.
    ///
    /// - Parameter credentialIdentities: A list of credential identities to save.
    ///
    @available(iOS 17.0, *)
    func saveCredentialIdentities(_ credentialIdentities: [any ASCredentialIdentity]) async throws

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
