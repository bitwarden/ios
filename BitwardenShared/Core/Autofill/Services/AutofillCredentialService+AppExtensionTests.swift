// swiftlint:disable:this file_name

import AuthenticationServices
import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

/// The tests for `DefaultAutofillCredentialService` when the app context is `.appExtension`.
/// This new file is needed given that the app context is necessary on `DefaultAutofillCredentialService`
/// initialization to see if the subscription to the `VaultTimeoutService` is necessary. So it's easier to test
/// having a new class test specifically for it.
@MainActor
class AutofillCredentialServiceAppExtensionTests: BitwardenTestCase {
    // MARK: Properties

    var appContextHelper: MockAppContextHelper!
    var autofillCredentialServiceDelegate: MockAutofillCredentialServiceDelegate!
    var cipherService: MockCipherService!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var credentialIdentityFactory: MockCredentialIdentityFactory!
    var errorReporter: MockErrorReporter!
    var eventService: MockEventService!
    var fido2UserInterfaceHelperDelegate: MockFido2UserInterfaceHelperDelegate!
    var fido2CredentialStore: MockFido2CredentialStore!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
    var identityStore: MockCredentialIdentityStore!
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var timeProvider: MockTimeProvider!
    var totpService: MockTOTPService!
    var subject: DefaultAutofillCredentialService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appContextHelper = MockAppContextHelper()
        appContextHelper.appContext = .appExtension

        autofillCredentialServiceDelegate = MockAutofillCredentialServiceDelegate()
        cipherService = MockCipherService()
        clientService = MockClientService()
        configService = MockConfigService()
        credentialIdentityFactory = MockCredentialIdentityFactory()
        errorReporter = MockErrorReporter()
        eventService = MockEventService()
        fido2UserInterfaceHelperDelegate = MockFido2UserInterfaceHelperDelegate()
        fido2CredentialStore = MockFido2CredentialStore()
        fido2UserInterfaceHelper = MockFido2UserInterfaceHelper()
        identityStore = MockCredentialIdentityStore()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.currentTime)
        totpService = MockTOTPService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultAutofillCredentialService(
            appContextHelper: appContextHelper,
            cipherService: cipherService,
            clientService: clientService,
            configService: configService,
            credentialIdentityFactory: credentialIdentityFactory,
            errorReporter: errorReporter,
            eventService: eventService,
            fido2CredentialStore: fido2CredentialStore,
            fido2UserInterfaceHelper: fido2UserInterfaceHelper,
            identityStore: identityStore,
            pasteboardService: pasteboardService,
            stateService: stateService,
            timeProvider: timeProvider,
            totpService: totpService,
            vaultTimeoutService: vaultTimeoutService,
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        appContextHelper = nil
        autofillCredentialServiceDelegate = nil
        cipherService = nil
        clientService = nil
        configService = nil
        credentialIdentityFactory = nil
        errorReporter = nil
        eventService = nil
        fido2UserInterfaceHelperDelegate = nil
        fido2CredentialStore = nil
        fido2UserInterfaceHelper = nil
        identityStore = nil
        pasteboardService = nil
        stateService = nil
        timeProvider = nil
        totpService = nil
        subject = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `syncIdentities(vaultLockStatus:)` doesn't update the credential identity store with the identities
    /// from the user's vault when the app context is `.appExtension`.
    func test_syncIdentities_appExtensionContext() {
        prepareDataForIdentitiesReplacement()

        vaultTimeoutService.vaultLockStatusSubject.send(VaultLockStatus(isVaultLocked: false, userId: "1"))

        XCTAssertFalse(cipherService.fetchAllCiphersCalled)
        XCTAssertFalse(credentialIdentityFactory.createCredentialIdentitiesMocker.called)
        XCTAssertFalse(identityStore.replaceCredentialIdentitiesCalled)
        XCTAssertNil(identityStore.replaceCredentialIdentitiesIdentities)
    }

    /// `updateCredentialsInStore()` replaces all identities in the identity Store correctly
    /// for the active user ID.
    func test_updateCredentialsInStore_succeedsActiveUserId() async throws {
        prepareDataForIdentitiesReplacement()
        stateService.activeAccount = .fixture(profile: .fixture(userId: "50"))

        await subject.updateCredentialsInStore()
        try await waitForAsync { [weak self] in
            guard let self else { return false }
            return identityStore.replaceCredentialIdentitiesIdentities != nil
        }

        XCTAssertEqual(
            identityStore.replaceCredentialIdentitiesIdentities,
            [
                .password(PasswordCredentialIdentity(id: "1", uri: "bitwarden.com", username: "user@bitwarden.com")),
                .password(PasswordCredentialIdentity(id: "3", uri: "example.com", username: "user@example.com")),
            ],
        )
        XCTAssertEqual(subject.lastSyncedUserId, "50")
    }

    /// `updateCredentialsInStore()` logs error when it throws.
    func test_updateCredentialsInStore_logOnThrow() async throws {
        stateService.activeAccount = nil

        await subject.updateCredentialsInStore()

        XCTAssertNil(identityStore.replaceCredentialIdentitiesIdentities)
        XCTAssertEqual(subject.lastSyncedUserId, nil)
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    // MARK: Private methods

    /// Prepares fixture data for identities replacement tests.
    func prepareDataForIdentitiesReplacement() {
        cipherService.fetchAllCiphersResult = .success([
            .fixture(
                id: "1",
                login: .fixture(
                    password: "password123",
                    uris: [.fixture(uri: "bitwarden.com")],
                    username: "user@bitwarden.com",
                ),
            ),
            .fixture(id: "2", type: .identity),
            .fixture(
                id: "3",
                login: .fixture(
                    password: "123321",
                    uris: [.fixture(uri: "example.com")],
                    username: "user@example.com",
                ),
            ),
            .fixture(deletedDate: .now, id: "4", type: .login),
        ])

        credentialIdentityFactory.createCredentialIdentitiesMocker
            .withResult { cipher in
                if cipher.id == "1" {
                    [
                        .password(
                            PasswordCredentialIdentity(
                                id: "1",
                                uri: "bitwarden.com",
                                username: "user@bitwarden.com",
                            ),
                        ),
                    ]
                } else if cipher.id == "3" {
                    [
                        .password(
                            PasswordCredentialIdentity(
                                id: "3",
                                uri: "example.com",
                                username: "user@example.com",
                            ),
                        ),
                    ]
                } else {
                    []
                }
            }
    }
}
