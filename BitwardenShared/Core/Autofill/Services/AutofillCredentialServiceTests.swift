import AuthenticationServices
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AutofillCredentialServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var autofillCredentialServiceDelegate: MockAutofillCredentialServiceDelegate!
    var cipherService: MockCipherService!
    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var eventService: MockEventService!
    var fido2UserInterfaceHelperDelegate: MockFido2UserInterfaceHelperDelegate!
    var fido2CredentialStore: MockFido2CredentialStore!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
    var identityStore: MockCredentialIdentityStore!
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var totpService: MockTOTPService!
    var subject: DefaultAutofillCredentialService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        autofillCredentialServiceDelegate = MockAutofillCredentialServiceDelegate()
        cipherService = MockCipherService()
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        eventService = MockEventService()
        fido2UserInterfaceHelperDelegate = MockFido2UserInterfaceHelperDelegate()
        fido2CredentialStore = MockFido2CredentialStore()
        fido2UserInterfaceHelper = MockFido2UserInterfaceHelper()
        identityStore = MockCredentialIdentityStore()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        totpService = MockTOTPService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultAutofillCredentialService(
            cipherService: cipherService,
            clientService: clientService,
            errorReporter: errorReporter,
            eventService: eventService,
            fido2CredentialStore: fido2CredentialStore,
            fido2UserInterfaceHelper: fido2UserInterfaceHelper,
            identityStore: identityStore,
            pasteboardService: pasteboardService,
            stateService: stateService,
            totpService: totpService,
            vaultTimeoutService: vaultTimeoutService
        )

        // Wait for the `DefaultAutofillCredentialService.init` task to sync the initial set of
        // identities for the active account, otherwise there's a potential race condition between
        // that and the tests below.
        waitFor { identityStore.removeAllCredentialIdentitiesCalled }
        identityStore.removeAllCredentialIdentitiesCalled = false
    }

    override func tearDown() {
        super.tearDown()

        autofillCredentialServiceDelegate = nil
        cipherService = nil
        clientService = nil
        errorReporter = nil
        eventService = nil
        fido2UserInterfaceHelperDelegate = nil
        fido2CredentialStore = nil
        fido2UserInterfaceHelper = nil
        identityStore = nil
        pasteboardService = nil
        stateService = nil
        totpService = nil
        subject = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `isAutofillCredentialsEnabled()` returns whether autofilling credentials is enabled.
    func test_isAutofillCredentialsEnabled() async {
        identityStore.state.mockIsEnabled = false
        var isEnabled = await subject.isAutofillCredentialsEnabled()
        XCTAssertFalse(isEnabled)

        identityStore.state.mockIsEnabled = true
        isEnabled = await subject.isAutofillCredentialsEnabled()
        XCTAssertTrue(isEnabled)
    }

    /// `provideCredential(for:)` returns the credential containing the username and password for
    /// the specified ID.
    func test_provideCredential() async throws {
        cipherService.fetchCipherResult = .success(
            .fixture(login: .fixture(password: "password123", username: "user@bitwarden.com"))
        )
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false

        let credential = try await subject.provideCredential(
            for: "1",
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
            repromptPasswordValidated: false
        )

        XCTAssertEqual(credential.password, "password123")
        XCTAssertEqual(credential.user, "user@bitwarden.com")
        XCTAssertNil(pasteboardService.copiedString)
    }

    /// `provideCredential(for:)` throws an error if the cipher with the specified ID doesn't have a
    /// username or password.
    func test_provideCredential_cipherMissingUsernameOrPassword() async {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false

        cipherService.fetchCipherResult = .success(.fixture(type: .identity))
        await assertAsyncThrows(error: ASExtensionError(.credentialIdentityNotFound)) {
            _ = try await subject.provideCredential(
                for: "1",
                autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
                repromptPasswordValidated: false
            )
        }

        cipherService.fetchCipherResult = .success(.fixture(login: .fixture(password: nil, username: "user@bitwarden")))
        await assertAsyncThrows(error: ASExtensionError(.credentialIdentityNotFound)) {
            _ = try await subject.provideCredential(
                for: "1",
                autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
                repromptPasswordValidated: false
            )
        }

        cipherService.fetchCipherResult = .success(.fixture(login: .fixture(password: "test", username: nil)))
        await assertAsyncThrows(error: ASExtensionError(.credentialIdentityNotFound)) {
            _ = try await subject.provideCredential(
                for: "1",
                autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
                repromptPasswordValidated: false
            )
        }
    }

    /// `provideCredential(for:)` throws an error if a cipher with the specified ID doesn't exist.
    func test_provideCredential_cipherNotFound() async {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false

        await assertAsyncThrows(error: ASExtensionError(.credentialIdentityNotFound)) {
            _ = try await subject.provideCredential(
                for: "1",
                autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
                repromptPasswordValidated: false
            )
        }
    }

    /// `provideCredential(for:)` unlocks the user's vault if they use never lock.
    func test_provideCredential_neverLock() async throws {
        autofillCredentialServiceDelegate.unlockVaultWithNaverlockHandler = { [weak self] in
            self?.vaultTimeoutService.isClientLocked["1"] = false
        }
        cipherService.fetchCipherResult = .success(
            .fixture(login: .fixture(password: "password123", username: "user@bitwarden.com"))
        )
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = true
        vaultTimeoutService.vaultTimeout["1"] = .never

        let credential = try await subject.provideCredential(
            for: "1",
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
            repromptPasswordValidated: false
        )

        XCTAssertTrue(autofillCredentialServiceDelegate.unlockVaultWithNeverlockKeyCalled)
        XCTAssertEqual(credential.password, "password123")
        XCTAssertEqual(credential.user, "user@bitwarden.com")
        XCTAssertNil(pasteboardService.copiedString)
    }

    /// `provideCredential(for:)` throws an error if reprompt is required.
    func test_provideCredential_repromptRequired() async throws {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false

        cipherService.fetchCipherResult = .success(
            .fixture(
                login: .fixture(
                    password: "password123",
                    username: "user@bitwarden.com"
                ),
                reprompt: .password
            )
        )
        await assertAsyncThrows(error: ASExtensionError(.userInteractionRequired)) {
            _ = try await subject.provideCredential(
                for: "1",
                autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
                repromptPasswordValidated: false
            )
        }
    }

    /// `provideCredential(for:)` copies the cipher's TOTP code when returning the credential.
    func test_provideCredential_totpCopy() async throws {
        cipherService.fetchCipherResult = .success(
            .fixture(login: .fixture(
                password: "password123",
                username: "user@bitwarden.com",
                totp: "totp"
            ))
        )
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false

        let credential = try await subject.provideCredential(
            for: "1",
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
            repromptPasswordValidated: false
        )

        XCTAssertEqual(credential.password, "password123")
        XCTAssertEqual(credential.user, "user@bitwarden.com")
        XCTAssertTrue(totpService.copyTotpIfPossibleCalled)
    }

    /// `provideCredential(for:)` attempting to copy the cipher's TOTP code when returning the credential
    /// throws when gettning if active account has premium thus it gets logged by the reporter
    /// but the credential is still returned.
    func test_provideCredential_totpCopyThrows() async throws {
        cipherService.fetchCipherResult = .success(
            .fixture(login: .fixture(
                password: "password123",
                username: "user@bitwarden.com",
                totp: "totp"
            ))
        )
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false
        totpService.copyTotpIfPossibleError = BitwardenTestError.example

        let credential = try await subject.provideCredential(
            for: "1",
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
            repromptPasswordValidated: false
        )

        XCTAssertEqual(credential.password, "password123")
        XCTAssertEqual(credential.user, "user@bitwarden.com")
        XCTAssertTrue(totpService.copyTotpIfPossibleCalled)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `provideCredential(for:)` throws an error if the user's vault is locked.
    func test_provideCredential_vaultLocked() async {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = true

        await assertAsyncThrows(error: ASExtensionError(.userInteractionRequired)) {
            _ = try await subject.provideCredential(
                for: "1",
                autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
                repromptPasswordValidated: false
            )
        }
    }

    /// `provideFido2Credential(for:autofillCredentialServiceDelegate:fido2UserVerificationMediatorDelegate:)`
    /// succeeds.
    @available(iOS 17.0, *)
    func test_provideFido2Credential_succeeds() async throws {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false
        let passkeyIdentity = ASPasskeyCredentialIdentity.fixture()
        let passkeyRequest = ASPasskeyCredentialRequest.fixture(credentialIdentity: passkeyIdentity)
        let expectedAssertionResult = GetAssertionResult.fixture()

        clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .getAssertionMocker
            .withVerification { request in
                request.rpId == passkeyIdentity.relyingPartyIdentifier
                    && request.clientDataHash == passkeyRequest.clientDataHash
                    && request.allowList?[0].id == passkeyIdentity.credentialID
                    && request.allowList?[0].ty == "public-key"
                    && request.allowList?[0].transports == nil
                    && !request.options.rk
                    && request.options.uv == .discouraged
                    && request.extensions == nil
            }
            .withResult(expectedAssertionResult)

        let result = try await subject.provideFido2Credential(
            for: passkeyRequest,
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
            fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate
        )

        XCTAssertFalse(autofillCredentialServiceDelegate.unlockVaultWithNeverlockKeyCalled)
        XCTAssertEqual(fido2UserInterfaceHelper.userVerificationPreferenceSetup, .discouraged)

        XCTAssertTrue(totpService.copyTotpIfPossibleCalled)
        XCTAssertTrue(errorReporter.errors.isEmpty)

        XCTAssertEqual(result.userHandle, expectedAssertionResult.userHandle)
        XCTAssertEqual(result.relyingParty, passkeyIdentity.relyingPartyIdentifier)
        XCTAssertEqual(result.signature, expectedAssertionResult.signature)
        XCTAssertEqual(result.clientDataHash, passkeyRequest.clientDataHash)
        XCTAssertEqual(result.authenticatorData, expectedAssertionResult.authenticatorData)
        XCTAssertEqual(result.credentialID, expectedAssertionResult.credentialId)
    }

    /// `provideFido2Credential(for:autofillCredentialServiceDelegate:fido2UserVerificationMediatorDelegate:)`
    /// attempting to copy the cipher's TOTP code when returning the credential
    /// throws when gettning if active account has premium thus it gets logged by the reporter
    /// but the credential is still returned.
    @available(iOS 17.0, *)
    func test_provideFido2Credential_totpCopyThrows() async throws {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false
        let passkeyIdentity = ASPasskeyCredentialIdentity.fixture()
        let passkeyRequest = ASPasskeyCredentialRequest.fixture(credentialIdentity: passkeyIdentity)
        let expectedAssertionResult = GetAssertionResult.fixture(
            selectedCredential: .fixture(
                cipherView: .fixture(
                    login: .fixture(
                        totp: "totp"
                    )
                )
            )
        )
        totpService.copyTotpIfPossibleError = BitwardenTestError.example

        clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .getAssertionMocker
            .withVerification { request in
                request.rpId == passkeyIdentity.relyingPartyIdentifier
                    && request.clientDataHash == passkeyRequest.clientDataHash
                    && request.allowList?[0].id == passkeyIdentity.credentialID
                    && request.allowList?[0].ty == "public-key"
                    && request.allowList?[0].transports == nil
                    && !request.options.rk
                    && request.options.uv == .discouraged
                    && request.extensions == nil
            }
            .withResult(expectedAssertionResult)

        let result = try await subject.provideFido2Credential(
            for: passkeyRequest,
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
            fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate
        )

        XCTAssertFalse(autofillCredentialServiceDelegate.unlockVaultWithNeverlockKeyCalled)
        XCTAssertEqual(fido2UserInterfaceHelper.userVerificationPreferenceSetup, .discouraged)

        XCTAssertEqual(result.userHandle, expectedAssertionResult.userHandle)
        XCTAssertEqual(result.relyingParty, passkeyIdentity.relyingPartyIdentifier)
        XCTAssertEqual(result.signature, expectedAssertionResult.signature)
        XCTAssertEqual(result.clientDataHash, passkeyRequest.clientDataHash)
        XCTAssertEqual(result.authenticatorData, expectedAssertionResult.authenticatorData)
        XCTAssertEqual(result.credentialID, expectedAssertionResult.credentialId)
        XCTAssertTrue(totpService.copyTotpIfPossibleCalled)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `provideFido2Credential(for:autofillCredentialServiceDelegate:fido2UserVerificationMediatorDelegate:)`
    /// succeeds when unlocking with never key.
    @available(iOS 17.0, *)
    func test_provideFido2Credential_succeedsWithUnlockingNeverKey() async throws {
        autofillCredentialServiceDelegate.unlockVaultWithNaverlockHandler = { [weak self] in
            self?.vaultTimeoutService.isClientLocked["1"] = false
        }
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = true
        vaultTimeoutService.vaultTimeout["1"] = .never

        let passkeyIdentity = ASPasskeyCredentialIdentity.fixture()
        let passkeyRequest = ASPasskeyCredentialRequest.fixture(credentialIdentity: passkeyIdentity)
        let expectedAssertionResult = GetAssertionResult.fixture()

        clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .getAssertionMocker
            .withVerification { request in
                request.rpId == passkeyIdentity.relyingPartyIdentifier
                    && request.clientDataHash == passkeyRequest.clientDataHash
                    && request.allowList?[0].id == passkeyIdentity.credentialID
                    && request.allowList?[0].ty == "public-key"
                    && request.allowList?[0].transports == nil
                    && !request.options.rk
                    && request.options.uv == .discouraged
                    && request.extensions == nil
            }
            .withResult(expectedAssertionResult)

        let result = try await subject.provideFido2Credential(
            for: passkeyRequest,
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
            fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate
        )

        XCTAssertTrue(autofillCredentialServiceDelegate.unlockVaultWithNeverlockKeyCalled)

        XCTAssertNotNil(fido2UserInterfaceHelper.fido2UserInterfaceHelperDelegate)
        XCTAssertEqual(fido2UserInterfaceHelper.userVerificationPreferenceSetup, .discouraged)

        XCTAssertEqual(result.userHandle, expectedAssertionResult.userHandle)
        XCTAssertEqual(result.relyingParty, passkeyIdentity.relyingPartyIdentifier)
        XCTAssertEqual(result.signature, expectedAssertionResult.signature)
        XCTAssertEqual(result.clientDataHash, passkeyRequest.clientDataHash)
        XCTAssertEqual(result.authenticatorData, expectedAssertionResult.authenticatorData)
        XCTAssertEqual(result.credentialID, expectedAssertionResult.credentialId)
    }

    /// `provideFido2Credential(for:autofillCredentialServiceDelegate:fido2UserVerificationMediatorDelegate:)`
    /// succeeds when unlocking with never key.
    @available(iOS 17.0, *)
    func test_provideFido2Credential_succeedsWithVaultUnlocked() async throws {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false

        let passkeyIdentity = ASPasskeyCredentialIdentity.fixture()
        let passkeyRequest = ASPasskeyCredentialRequest.fixture(credentialIdentity: passkeyIdentity)
        let expectedAssertionResult = GetAssertionResult.fixture()

        clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .getAssertionMocker
            .withVerification { request in
                request.rpId == passkeyIdentity.relyingPartyIdentifier
                    && request.clientDataHash == passkeyRequest.clientDataHash
                    && request.allowList?[0].id == passkeyIdentity.credentialID
                    && request.allowList?[0].ty == "public-key"
                    && request.allowList?[0].transports == nil
                    && !request.options.rk
                    && request.options.uv == .discouraged
                    && request.extensions == nil
            }
            .withResult(expectedAssertionResult)

        let result = try await subject.provideFido2Credential(
            for: passkeyRequest,
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
            fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate
        )

        XCTAssertFalse(autofillCredentialServiceDelegate.unlockVaultWithNeverlockKeyCalled)

        XCTAssertNotNil(fido2UserInterfaceHelper.fido2UserInterfaceHelperDelegate)
        XCTAssertEqual(fido2UserInterfaceHelper.userVerificationPreferenceSetup, .discouraged)

        XCTAssertEqual(result.userHandle, expectedAssertionResult.userHandle)
        XCTAssertEqual(result.relyingParty, passkeyIdentity.relyingPartyIdentifier)
        XCTAssertEqual(result.signature, expectedAssertionResult.signature)
        XCTAssertEqual(result.clientDataHash, passkeyRequest.clientDataHash)
        XCTAssertEqual(result.authenticatorData, expectedAssertionResult.authenticatorData)
        XCTAssertEqual(result.credentialID, expectedAssertionResult.credentialId)
    }

    /// `provideFido2Credential(for:autofillCredentialServiceDelegate:fido2UserVerificationMediatorDelegate:)`
    /// throws when no active user.
    @available(iOS 17.0, *)
    func test_provideFido2Credential_throwsNoActiveUser() async throws {
        stateService.activeAccount = nil

        let passkeyIdentity = ASPasskeyCredentialIdentity.fixture()
        let passkeyRequest = ASPasskeyCredentialRequest.fixture(credentialIdentity: passkeyIdentity)

        clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .getAssertionMocker
            .throwing(BitwardenTestError.example)

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.provideFido2Credential(
                for: passkeyRequest,
                autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
                fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate
            )
        }
    }

    /// `provideFido2Credential(for:autofillCredentialServiceDelegate:fido2UserVerificationMediatorDelegate:)`
    /// throws when needing user interaction.
    @available(iOS 17.0, *)
    func test_provideFido2Credential_throwsNeedingUserInteraction() async throws {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = true

        let passkeyIdentity = ASPasskeyCredentialIdentity.fixture()
        let passkeyRequest = ASPasskeyCredentialRequest.fixture(credentialIdentity: passkeyIdentity)

        clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .getAssertionMocker
            .throwing(BitwardenTestError.example)

        await assertAsyncThrows(error: Fido2Error.userInteractionRequired) {
            _ = try await subject.provideFido2Credential(
                for: passkeyRequest,
                autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
                fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate
            )
        }
    }

    /// `provideFido2Credential(for:autofillCredentialServiceDelegate:fido2UserVerificationMediatorDelegate:)`
    /// throws when getting assertion with vault unlocked.
    @available(iOS 17.0, *)
    func test_provideFido2Credential_throwsGettingAssertion() async throws {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false

        let passkeyIdentity = ASPasskeyCredentialIdentity.fixture()
        let passkeyRequest = ASPasskeyCredentialRequest.fixture(credentialIdentity: passkeyIdentity)

        clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .getAssertionMocker
            .throwing(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.provideFido2Credential(
                for: passkeyRequest,
                autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
                fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate
            )
        }
    }

    /// `provideFido2Credential(for:fido2UserVerificationMediatorDelegate:)`
    /// succeeds.
    @available(iOS 17.0, *)
    func test_provideFido2Credential_passkeyRequestParameters_succeeds() async throws {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false
        let allowedCredentials = [
            Data(repeating: 2, count: 32),
            Data(repeating: 5, count: 32),
        ]
        let passkeyParameters = MockPasskeyCredentialRequestParameters(allowedCredentials: allowedCredentials)
        let expectedAssertionResult = GetAssertionResult.fixture()

        clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .getAssertionMocker
            .withVerification { request in
                request.rpId == passkeyParameters.relyingPartyIdentifier
                    && request.clientDataHash == passkeyParameters.clientDataHash
                    && request.allowList == allowedCredentials.map { credentialId in
                        PublicKeyCredentialDescriptor(
                            ty: "public-key",
                            id: credentialId,
                            transports: nil
                        )
                    }
                    && !request.options.rk
                    && request.options.uv == .preferred
                    && request.extensions == nil
            }
            .withResult(expectedAssertionResult)

        let result = try await subject.provideFido2Credential(
            for: passkeyParameters,
            fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate
        )
        XCTAssertEqual(fido2UserInterfaceHelper.userVerificationPreferenceSetup, .preferred)

        XCTAssertEqual(result.userHandle, expectedAssertionResult.userHandle)
        XCTAssertEqual(result.relyingParty, passkeyParameters.relyingPartyIdentifier)
        XCTAssertEqual(result.signature, expectedAssertionResult.signature)
        XCTAssertEqual(result.clientDataHash, passkeyParameters.clientDataHash)
        XCTAssertEqual(result.authenticatorData, expectedAssertionResult.authenticatorData)
        XCTAssertEqual(result.credentialID, expectedAssertionResult.credentialId)
    }

    /// `provideFido2Credential(for:fido2UserVerificationMediatorDelegate:)`
    /// throws when getting assertion.
    @available(iOS 17.0, *)
    func test_provideFido2Credential_passkeyRequestParameters_throwsGettingAssertion() async throws {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false

        let passkeyParameters = MockPasskeyCredentialRequestParameters()

        clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .getAssertionMocker
            .throwing(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.provideFido2Credential(
                for: passkeyParameters,
                fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate
            )
        }
    }

    /// `syncIdentities(vaultLockStatus:)` updates the credential identity store with the identities
    /// from the user's vault.
    func test_syncIdentities() {
        cipherService.fetchAllCiphersResult = .success([
            .fixture(
                id: "1",
                login: .fixture(
                    password: "password123",
                    uris: [.fixture(uri: "bitwarden.com")],
                    username: "user@bitwarden.com"
                )
            ),
            .fixture(id: "2", type: .identity),
            .fixture(
                id: "3",
                login: .fixture(
                    password: "123321",
                    uris: [.fixture(uri: "example.com")],
                    username: "user@example.com"
                )
            ),
            .fixture(deletedDate: .now, id: "4", type: .login),
        ])

        vaultTimeoutService.vaultLockStatusSubject.send(VaultLockStatus(isVaultLocked: false, userId: "1"))
        waitFor(identityStore.replaceCredentialIdentitiesIdentities != nil)

        XCTAssertEqual(
            identityStore.replaceCredentialIdentitiesIdentities,
            [
                .password(PasswordCredentialIdentity(id: "1", uri: "bitwarden.com", username: "user@bitwarden.com")),
                .password(PasswordCredentialIdentity(id: "3", uri: "example.com", username: "user@example.com")),
            ]
        )
    }

    /// `syncIdentities(vaultLockStatus:)` doesn't remove identities if the store's state is disabled.
    func test_syncIdentities_removeDisabled() async throws {
        identityStore.state.mockIsEnabled = false

        vaultTimeoutService.vaultLockStatusSubject.send(nil)
        try await waitForAsync {
            self.identityStore.stateCalled
        }

        XCTAssertFalse(identityStore.removeAllCredentialIdentitiesCalled)
    }

    /// `syncIdentities(vaultLockStatus:)` logs an error if removing identities fails.
    func test_syncIdentities_removeError() {
        identityStore.removeAllCredentialIdentitiesResult = .failure(BitwardenTestError.example)

        vaultTimeoutService.vaultLockStatusSubject.send(nil)
        waitFor(identityStore.removeAllCredentialIdentitiesCalled)

        waitFor(!errorReporter.errors.isEmpty)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `syncIdentities(vaultLockStatus:)` removes identities from the store when the user switches from a previous
    /// synced vault to another user.
    func test_syncIdentities_removeOnSwitched() async throws {
        cipherService.fetchAllCiphersResult = .success([
            .fixture(
                id: "1",
                login: .fixture(
                    password: "password123",
                    uris: [.fixture(uri: "bitwarden.com")],
                    username: "user@bitwarden.com"
                )
            ),
        ])

        vaultTimeoutService.vaultLockStatusSubject.send(VaultLockStatus(isVaultLocked: false, userId: "1"))
        try await waitForAsync {
            self.identityStore.replaceCredentialIdentitiesIdentities != nil
        }
        XCTAssertEqual(identityStore.replaceCredentialIdentitiesIdentities?.count, 1)

        vaultTimeoutService.vaultLockStatusSubject.send(VaultLockStatus(isVaultLocked: true, userId: "2"))
        try await waitForAsync {
            self.identityStore.removeAllCredentialIdentitiesCalled
        }

        XCTAssertTrue(identityStore.removeAllCredentialIdentitiesCalled)
    }

    /// `syncIdentities(vaultLockStatus:)` doesn't remove identities from the store when the user locks their vault.
    func test_syncIdentities_dontRemoveOnSwitchedEqualUser() async throws {
        cipherService.fetchAllCiphersResult = .success([
            .fixture(
                id: "1",
                login: .fixture(
                    password: "password123",
                    uris: [.fixture(uri: "bitwarden.com")],
                    username: "user@bitwarden.com"
                )
            ),
        ])

        vaultTimeoutService.vaultLockStatusSubject.send(VaultLockStatus(isVaultLocked: false, userId: "1"))
        try await waitForAsync {
            self.identityStore.replaceCredentialIdentitiesIdentities != nil
        }
        XCTAssertEqual(identityStore.replaceCredentialIdentitiesIdentities?.count, 1)

        vaultTimeoutService.vaultLockStatusSubject.send(VaultLockStatus(isVaultLocked: true, userId: "1"))
        XCTAssertFalse(identityStore.removeAllCredentialIdentitiesCalled)
    }

    /// `syncIdentities(vaultLockStatus:)` doesn't remove identities from the store when it tries to sync
    /// for the first time and it's locked (last user ID synced is `nil`).
    func test_syncIdentities_dontRemoveOnFirstSyncLocked() async throws {
        vaultTimeoutService.vaultLockStatusSubject.send(VaultLockStatus(isVaultLocked: true, userId: "1"))
        XCTAssertFalse(identityStore.removeAllCredentialIdentitiesCalled)
    }

    /// `syncIdentities(vaultLockStatus:)` removes identities from the store when the user logs out.
    func test_syncIdentities_removeOnLogout() {
        cipherService.fetchAllCiphersResult = .success([
            .fixture(
                id: "1",
                login: .fixture(
                    password: "password123",
                    uris: [.fixture(uri: "bitwarden.com")],
                    username: "user@bitwarden.com"
                )
            ),
        ])

        vaultTimeoutService.vaultLockStatusSubject.send(VaultLockStatus(isVaultLocked: false, userId: "1"))
        waitFor(identityStore.replaceCredentialIdentitiesIdentities != nil)
        XCTAssertEqual(identityStore.replaceCredentialIdentitiesIdentities?.count, 1)

        vaultTimeoutService.vaultLockStatusSubject.send(nil)
        waitFor(identityStore.removeAllCredentialIdentitiesCalled)
        XCTAssertTrue(identityStore.removeAllCredentialIdentitiesCalled)
    }

    /// `syncIdentities(vaultLockStatus:)` doesn't replace identities if the store's state is disabled.
    func test_syncIdentities_replaceDisabled() {
        identityStore.state.mockIsEnabled = false

        vaultTimeoutService.vaultLockStatusSubject.send(VaultLockStatus(isVaultLocked: false, userId: "1"))
        waitFor(identityStore.stateCalled)

        XCTAssertFalse(identityStore.replaceCredentialIdentitiesCalled)
    }

    /// `syncIdentities(vaultLockStatus:)` logs an error if replacing identities fails.
    func test_syncIdentities_replaceError() {
        identityStore.replaceCredentialIdentitiesResult = .failure(BitwardenTestError.example)

        vaultTimeoutService.vaultLockStatusSubject.send(VaultLockStatus(isVaultLocked: false, userId: "1"))
        waitFor(identityStore.replaceCredentialIdentitiesCalled)

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }
} // swiftlint:disable:this file_length
