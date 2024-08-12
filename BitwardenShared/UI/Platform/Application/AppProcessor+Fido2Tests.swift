// swiftlint:disable:this file_name

import AuthenticationServices
import BitwardenSdk
import Foundation
import XCTest

@testable import BitwardenShared

@available(iOS 17.0, *)
class AppProcessorFido2Tests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockFido2AppExtensionDelegate!
    var appModule: MockAppModule!
    var authRepository: MockAuthRepository!
    var autofillCredentialService: MockAutofillCredentialService!
    var clientService: MockClientService!
    var coordinator: MockCoordinator<AppRoute, AppEvent>!
    var errorReporter: MockErrorReporter!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
    var migrationService: MockMigrationService!
    var notificationCenterService: MockNotificationCenterService!
    var notificationService: MockNotificationService!
    var router: MockRouter<AuthEvent, AuthRoute>!
    var stateService: MockStateService!
    var subject: AppProcessor!
    var syncService: MockSyncService!
    var timeProvider: MockTimeProvider!
    var vaultRepository: MockVaultRepository!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        router = MockRouter(routeForEvent: { _ in .landing })
        appExtensionDelegate = MockFido2AppExtensionDelegate()
        appModule = MockAppModule()
        authRepository = MockAuthRepository()
        autofillCredentialService = MockAutofillCredentialService()
        clientService = MockClientService()
        coordinator = MockCoordinator()
        appModule.authRouter = router
        appModule.appCoordinator = coordinator
        errorReporter = MockErrorReporter()
        fido2UserInterfaceHelper = MockFido2UserInterfaceHelper()
        migrationService = MockMigrationService()
        notificationCenterService = MockNotificationCenterService()
        notificationService = MockNotificationService()
        stateService = MockStateService()
        syncService = MockSyncService()
        timeProvider = MockTimeProvider(.currentTime)
        vaultRepository = MockVaultRepository()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = AppProcessor(
            appExtensionDelegate: appExtensionDelegate,
            appModule: appModule,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                autofillCredentialService: autofillCredentialService,
                clientService: clientService,
                errorReporter: errorReporter,
                fido2UserInterfaceHelper: fido2UserInterfaceHelper,
                migrationService: migrationService,
                notificationService: notificationService,
                notificationCenterService: notificationCenterService,
                stateService: stateService,
                syncService: syncService,
                vaultRepository: vaultRepository,
                vaultTimeoutService: vaultTimeoutService
            )
        )
        subject.coordinator = coordinator.asAnyCoordinator()
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        appModule = nil
        authRepository = nil
        autofillCredentialService = nil
        clientService = nil
        coordinator = nil
        errorReporter = nil
        fido2UserInterfaceHelper = nil
        migrationService = nil
        notificationCenterService = nil
        notificationService = nil
        stateService = nil
        subject = nil
        syncService = nil
        timeProvider = nil
        vaultRepository = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `getter:isAutofillingFromList` returns `true` when delegate is autofilling from list.
    func test_isAutofillingFromList_true() async throws {
        appExtensionDelegate.extensionMode = .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters())
        XCTAssertTrue(subject.isAutofillingFromList)
    }

    /// `getter:isAutofillingFromList` returns `false` when delegate is not autofilling from list.
    func test_isAutofillingFromList_false() async throws {
        appExtensionDelegate.extensionMode = .configureAutofill
        XCTAssertFalse(subject.isAutofillingFromList)
    }

    /// `onNeedsUserInteraction()` throws when flows is not with user interaction but user interaction is required.
    @available(iOS 17.0, *)
    func test_onNeedsUserInteraction_throws() async {
        appExtensionDelegate.flowWithUserInteraction = false

        await assertAsyncThrows(error: Fido2Error.userInteractionRequired) {
            try await subject.onNeedsUserInteraction()
        }
        XCTAssertTrue(appExtensionDelegate.setUserInteractionRequiredCalled)
    }

    /// `onNeedsUserInteraction()` doesn't throw when flows is not with user interaction
    /// but user interaction is required.
    @available(iOS 17.0, *)
    func test_onNeedsUserInteraction_flowWithUserInteraction() async {
        appExtensionDelegate.flowWithUserInteraction = true

        let taskResult = Task {
            try await subject.onNeedsUserInteraction()
        }

        appExtensionDelegate.didAppearPublisher.send(true)

        await assertAsyncDoesNotThrow {
            try await taskResult.value
        }
        XCTAssertFalse(appExtensionDelegate.setUserInteractionRequiredCalled)
    }

    /// `provideFido2Credential(for:)` succeeds calling
    /// the autofill credential service.
    @available(iOS 17.0, *)
    func test_provideFido2Credential() async throws {
        let passkeyIdentity = ASPasskeyCredentialIdentity.fixture()
        let passkeyRequest = ASPasskeyCredentialRequest.fixture(credentialIdentity: passkeyIdentity)
        let expectedAssertionResult = ASPasskeyAssertionCredential(
            userHandle: Data(repeating: 1, count: 16),
            relyingParty: passkeyIdentity.relyingPartyIdentifier,
            signature: Data(repeating: 1, count: 32),
            clientDataHash: passkeyRequest.clientDataHash,
            authenticatorData: Data(repeating: 1, count: 40),
            credentialID: Data(repeating: 1, count: 32)
        )

        autofillCredentialService.provideFido2CredentialResult = .success(expectedAssertionResult)

        let result = try await subject.provideFido2Credential(for: passkeyRequest)

        XCTAssertEqual(result.userHandle, expectedAssertionResult.userHandle)
        XCTAssertEqual(result.relyingParty, passkeyIdentity.relyingPartyIdentifier)
        XCTAssertEqual(result.signature, expectedAssertionResult.signature)
        XCTAssertEqual(result.clientDataHash, passkeyRequest.clientDataHash)
        XCTAssertEqual(result.authenticatorData, expectedAssertionResult.authenticatorData)
        XCTAssertEqual(result.credentialID, expectedAssertionResult.credentialID)
    }

    /// `provideFido2Credential(for:)` throws calling
    /// the autofill credential service.
    @available(iOS 17.0, *)
    func test_provideFido2Credential_throws() async throws {
        let passkeyIdentity = ASPasskeyCredentialIdentity.fixture()
        let passkeyRequest = ASPasskeyCredentialRequest.fixture(credentialIdentity: passkeyIdentity)

        autofillCredentialService.provideFido2CredentialResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.provideFido2Credential(for: passkeyRequest)
        }
    }

    /// `showAlert(_:onDismissed:)` shows the alert with the coordinator.
    func test_showAlert_withOnDismissed() async throws {
        subject.showAlert(Alert(title: "Test", message: "testing"), onDismissed: nil)
        XCTAssertFalse(coordinator.alertShown.isEmpty)
    }

    /// `showAlert(_:)` shows the alert with the coordinator.
    func test_showAlert() async throws {
        subject.showAlert(Alert(title: "Test", message: "testing"))
        XCTAssertFalse(coordinator.alertShown.isEmpty)
    }
}
