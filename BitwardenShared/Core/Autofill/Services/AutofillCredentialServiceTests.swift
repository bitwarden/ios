import AuthenticationServices
import XCTest

@testable import BitwardenShared

class AutofillCredentialServiceTests: BitwardenTestCase {
    // MARK: Properties

    var cipherService: MockCipherService!
    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var eventService: MockEventService!
    var identityStore: MockCredentialIdentityStore!
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var subject: DefaultAutofillCredentialService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        eventService = MockEventService()
        identityStore = MockCredentialIdentityStore()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultAutofillCredentialService(
            cipherService: cipherService,
            clientService: clientService,
            errorReporter: errorReporter,
            eventService: eventService,
            identityStore: identityStore,
            pasteboardService: pasteboardService,
            stateService: stateService,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        clientService = nil
        errorReporter = nil
        eventService = nil
        identityStore = nil
        pasteboardService = nil
        stateService = nil
        subject = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `provideCredential(for:)` returns the credential containing the username and password for
    /// the specified ID.
    func test_provideCredential() async throws {
        cipherService.fetchCipherResult = .success(
            .fixture(login: .fixture(password: "password123", username: "user@bitwarden.com"))
        )
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false

        let credential = try await subject.provideCredential(for: "1", repromptPasswordValidated: false)

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
            _ = try await subject.provideCredential(for: "1", repromptPasswordValidated: false)
        }

        cipherService.fetchCipherResult = .success(.fixture(login: .fixture(password: nil, username: "user@bitwarden")))
        await assertAsyncThrows(error: ASExtensionError(.credentialIdentityNotFound)) {
            _ = try await subject.provideCredential(for: "1", repromptPasswordValidated: false)
        }

        cipherService.fetchCipherResult = .success(.fixture(login: .fixture(password: "test", username: nil)))
        await assertAsyncThrows(error: ASExtensionError(.credentialIdentityNotFound)) {
            _ = try await subject.provideCredential(for: "1", repromptPasswordValidated: false)
        }
    }

    /// `provideCredential(for:)` throws an error if a cipher with the specified ID doesn't exist.
    func test_provideCredential_cipherNotFound() async {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = false

        await assertAsyncThrows(error: ASExtensionError(.credentialIdentityNotFound)) {
            _ = try await subject.provideCredential(for: "1", repromptPasswordValidated: false)
        }
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
            _ = try await subject.provideCredential(for: "1", repromptPasswordValidated: false)
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

        let credential = try await subject.provideCredential(for: "1", repromptPasswordValidated: false)

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

        let credential = try await subject.provideCredential(for: "1", repromptPasswordValidated: false)

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

        let credential = try await subject.provideCredential(for: "1", repromptPasswordValidated: false)

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

        let credential = try await subject.provideCredential(for: "1", repromptPasswordValidated: false)

        XCTAssertEqual(credential.password, "password123")
        XCTAssertEqual(credential.user, "user@bitwarden.com")
        XCTAssertEqual(pasteboardService.copiedString, "123456")
    }

    /// `provideCredential(for:)` throws an error if the user's vault is locked.
    func test_provideCredential_vaultLocked() async {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = true

        await assertAsyncThrows(error: ASExtensionError(.userInteractionRequired)) {
            _ = try await subject.provideCredential(for: "1", repromptPasswordValidated: false)
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
}
