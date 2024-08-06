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
            vaultTimeoutService: vaultTimeoutService
        )
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
        subject = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `onProfileSwitched(oldUserId:activeUserId:)` removes all identities
    /// when old user ID exists and active user is locked.
    func test_onProfileSwitched_locked() async throws {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = true
        try await waitAndResetRemoveAllCredentialIdentitiesCalled()

        try await subject.onProfileSwitched(oldUserId: "123", activeUserId: "1")

        XCTAssertTrue(identityStore.removeAllCredentialIdentitiesCalled)
    }

    /// `onProfileSwitched(oldUserId:activeUserId:)` doesn't remove all identities
    /// when old user ID doesn't exist.
    func test_onProfileSwitched_oldUserNil() async throws {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = true
        try await waitAndResetRemoveAllCredentialIdentitiesCalled()

        try await subject.onProfileSwitched(oldUserId: nil, activeUserId: "1")

        XCTAssertFalse(identityStore.removeAllCredentialIdentitiesCalled)
    }

    /// `onProfileSwitched(oldUserId:activeUserId:)` doesn't remove all identities
    /// when active user is not locked.
    func test_onProfileSwitched_notLocked() async throws {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false
        try await waitAndResetRemoveAllCredentialIdentitiesCalled()

        try await subject.onProfileSwitched(oldUserId: "123", activeUserId: "1")

        XCTAssertFalse(identityStore.removeAllCredentialIdentitiesCalled)
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
        XCTAssertEqual(pasteboardService.copiedString, "123456")
    }

    /// `provideCredential(for:)` doesn't copy the cipher's TOTP code if the copy TOTP code setting
    /// has been disabled.
    func test_provideCredential_totpCopyDisabled() async throws {
        cipherService.fetchCipherResult = .success(
            .fixture(login: .fixture(
                password: "password123",
                username: "user@bitwarden.com",
                totp: "totp"
            ))
        )
        stateService.activeAccount = .fixture()
        stateService.disableAutoTotpCopyByUserId["1"] = true
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

    /// `provideCredential(for:)` doesn't copy the cipher's TOTP code if the user doesn't have premium access.
    func test_provideCredential_totpCopyNotPremium() async throws {
        cipherService.fetchCipherResult = .success(
            .fixture(login: .fixture(
                password: "password123",
                username: "user@bitwarden.com",
                totp: "totp"
            ))
        )
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = .success(false)
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

    /// `provideCredential(for:)` copies the cipher's TOTP code if the user doesn't have premium
    /// but the org uses TOTP.
    func test_provideCredential_totpCopyOrgUseTotp() async throws {
        cipherService.fetchCipherResult = .success(
            .fixture(
                login: .fixture(
                    password: "password123",
                    username: "user@bitwarden.com",
                    totp: "totp"
                ),
                organizationUseTotp: true
            )
        )
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = .success(false)
        vaultTimeoutService.isClientLocked["1"] = false

        let credential = try await subject.provideCredential(
            for: "1",
            autofillCredentialServiceDelegate: autofillCredentialServiceDelegate,
            repromptPasswordValidated: false
        )

        XCTAssertEqual(credential.password, "password123")
        XCTAssertEqual(credential.user, "user@bitwarden.com")
        XCTAssertEqual(pasteboardService.copiedString, "123456")
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
    func test_syncIdentities_removeDisabled() {
        identityStore.state.mockIsEnabled = false

        vaultTimeoutService.vaultLockStatusSubject.send(nil)
        waitFor(identityStore.stateCalled)

        XCTAssertFalse(identityStore.removeAllCredentialIdentitiesCalled)
    }

    /// `syncIdentities(vaultLockStatus:)` logs an error if removing identities fails.
    func test_syncIdentities_removeError() {
        identityStore.removeAllCredentialIdentitiesResult = .failure(BitwardenTestError.example)

        vaultTimeoutService.vaultLockStatusSubject.send(nil)
        waitFor(identityStore.removeAllCredentialIdentitiesCalled)

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
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

    // MARK: Private

    /// Waits for `identityStore.removeAllCredentialIdentitiesCalled` to be `true`
    /// and then resets it to `false` so it doesn't alter the result of the test given the
    /// `vaultLockStatusPublisher` -> `syncIdentities` logic.
    private func waitAndResetRemoveAllCredentialIdentitiesCalled() async throws {
        try await waitForAsync {
            self.identityStore.removeAllCredentialIdentitiesCalled
        }
        identityStore.removeAllCredentialIdentitiesCalled = false
    }
} // swiftlint:disable:this file_length
