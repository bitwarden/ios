import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - ViewItemProcessorTests

class ViewItemProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var client: MockHTTPClient!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>!
    var delegate: MockCipherItemOperationDelegate!
    var errorReporter: MockErrorReporter!
    var eventService: MockEventService!
    var pasteboardService: MockPasteboardService!
    var rehydrationHelper: MockRehydrationHelper!
    var stateService: MockStateService!
    var subject: ViewItemProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        authRepository = MockAuthRepository()
        client = MockHTTPClient()
        configService = MockConfigService()
        coordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()
        delegate = MockCipherItemOperationDelegate()
        errorReporter = MockErrorReporter()
        eventService = MockEventService()
        pasteboardService = MockPasteboardService()
        rehydrationHelper = MockRehydrationHelper()
        stateService = MockStateService()
        vaultRepository = MockVaultRepository()
        let services = ServiceContainer.withMocks(
            authRepository: authRepository,
            configService: configService,
            errorReporter: errorReporter,
            eventService: eventService,
            httpClient: client,
            pasteboardService: pasteboardService,
            rehydrationHelper: rehydrationHelper,
            stateService: stateService,
            vaultRepository: vaultRepository
        )
        subject = ViewItemProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            itemId: "id",
            services: services,
            state: ViewItemState()
        )
    }

    override func tearDown() {
        super.tearDown()
        authRepository = nil
        client = nil
        coordinator = nil
        errorReporter = nil
        eventService = nil
        pasteboardService = nil
        rehydrationHelper = nil
        stateService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `didMoveCipher(_:to:)` displays a toast after the cipher is moved to the organization.
    @MainActor
    func test_didMoveCipher() {
        subject.didMoveCipher(.fixture(name: "Bitwarden Password"), to: .organization(id: "1", name: "Organization"))

        waitFor { subject.state.toast != nil }

        XCTAssertEqual(
            subject.state.toast,
            Toast(title: Localizations.movedItemToOrg("Bitwarden Password", "Organization"))
        )
    }

    /// `didUpdateCipher()` displays a toast after the cipher is updated.
    @MainActor
    func test_didUpdateCipher() {
        subject.didUpdateCipher()

        waitFor { subject.state.toast != nil }

        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.itemUpdated))
    }

    /// `init(appExtensionDelegate:coordinator:delegate:services:state:)` with editing configuration
    /// doesn't add itself as a rehydratable target.
    @MainActor
    func test_init_editingConfiguration() {
        rehydrationHelper.rehydratableTargets.removeAll()

        let services = ServiceContainer.withMocks(
            authRepository: authRepository,
            errorReporter: errorReporter,
            eventService: eventService,
            httpClient: client,
            pasteboardService: pasteboardService,
            rehydrationHelper: rehydrationHelper,
            stateService: stateService,
            vaultRepository: vaultRepository
        )
        subject = ViewItemProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            itemId: "id",
            services: services,
            state: ViewItemState()
        )
        waitFor(
            !rehydrationHelper.rehydratableTargets.isEmpty
                && rehydrationHelper.rehydratableTargets[0] is ViewItemProcessor
        )
    }

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository.
    @MainActor
    func test_perform_appeared() {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.showWebIcons = true
        vaultRepository.doesActiveAccountHavePremiumResult = true
        let collections = [
            CollectionView.fixture(id: "1"),
            CollectionView.fixture(id: "2"),
        ]
        vaultRepository.fetchCollectionsResult = .success(collections)

        let cipherItem = CipherView.fixture(
            id: "id",
            login: LoginView(
                username: "username",
                password: "password",
                passwordRevisionDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil,
                fido2Credentials: nil
            ),
            name: "Name",
            notes: "Notes",
            viewPassword: true
        )
        vaultRepository.cipherDetailsSubject.send(cipherItem)

        XCTAssertNil(subject.streamCipherDetailsTask)
        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        var expectedState = CipherItemState(
            existing: cipherItem,
            hasPremium: true,
            iconBaseURL: URL(string: "https://example.com/icons")!
        )!

        expectedState.allUserCollections = collections

        XCTAssertNotNil(subject.streamCipherDetailsTask)
        XCTAssertTrue(subject.state.hasPremiumFeatures)
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
        XCTAssertEqual(subject.state.loadingState, .data(expectedState))

        guard case let .data(currentState) = subject.state.loadingState else {
            XCTFail("State doesn't have data")
            return
        }
        XCTAssertTrue(currentState.showWebIcons)
    }

    /// `perform(_:)` with `.appeared` records any errors.
    @MainActor
    func test_perform_appeared_errors() {
        vaultRepository.cipherDetailsSubject.send(completion: .failure(BitwardenTestError.example))

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository.
    @MainActor
    func test_perform_appeared_invalidFixture() {
        let cipherItem = CipherView.fixture(id: nil)
        vaultRepository.cipherDetailsSubject.send(cipherItem)

        let task = Task {
            await subject.perform(.appeared)
        }
        waitFor(vaultRepository.doesActiveAccountHavePremiumCalled)
        task.cancel()

        XCTAssertEqual(
            subject.state.loadingState,
            .loading(nil)
        )
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.appeared` observe the premium status of a user.
    @MainActor
    func test_perform_appeared_nonPremium() {
        let account = Account.fixture()
        stateService.activeAccount = account

        let cipherItem = CipherView.loginFixture(
            id: "id"
        )
        vaultRepository.doesActiveAccountHavePremiumResult = false
        vaultRepository.cipherDetailsSubject.send(cipherItem)

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        let expectedState = CipherItemState(
            existing: cipherItem,
            hasPremium: false,
            iconBaseURL: URL(string: "https://example.com/icons")!
        )!

        XCTAssertEqual(subject.state.loadingState, .data(expectedState))
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository when
    /// cipher belongs to a folder fetching such folder to set the folder name to the state.
    @MainActor
    func test_perform_appearedWithFolder() {
        let account = Account.fixture()
        stateService.activeAccount = account
        vaultRepository.doesActiveAccountHavePremiumResult = true
        let collections = [
            CollectionView.fixture(id: "1"),
            CollectionView.fixture(id: "2"),
        ]
        vaultRepository.fetchCollectionsResult = .success(collections)

        let cipherItem = CipherView.fixture(
            folderId: "1",
            id: "id",
            login: LoginView(
                username: "username",
                password: "password",
                passwordRevisionDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil,
                fido2Credentials: nil
            ),
            name: "Name",
            notes: "Notes",
            viewPassword: true
        )
        vaultRepository.cipherDetailsSubject.send(cipherItem)
        vaultRepository.fetchFolderResult = .success(.fixture(id: "1", name: "FolderTest"))

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        var expectedState = CipherItemState(
            existing: cipherItem,
            hasPremium: true,
            iconBaseURL: URL(string: "https://example.com/icons")!
        )!

        expectedState.allUserCollections = collections
        expectedState.folderName = "FolderTest"

        XCTAssertTrue(subject.state.hasPremiumFeatures)
        XCTAssertEqual(subject.state.loadingState, .data(expectedState))
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository when
    /// cipher belongs to an organization fetching such organization to set the organization name to the state.
    @MainActor
    func test_perform_appearedWithOrganization() {
        let account = Account.fixture()
        stateService.activeAccount = account
        vaultRepository.doesActiveAccountHavePremiumResult = true
        let collections = [
            CollectionView.fixture(id: "1"),
            CollectionView.fixture(id: "2"),
        ]
        vaultRepository.fetchCollectionsResult = .success(collections)

        let cipherItem = CipherView.fixture(
            id: "id",
            login: LoginView(
                username: "username",
                password: "password",
                passwordRevisionDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil,
                fido2Credentials: nil
            ),
            name: "Name",
            notes: "Notes",
            organizationId: "1",
            viewPassword: true
        )
        vaultRepository.cipherDetailsSubject.send(cipherItem)
        vaultRepository.fetchOrganizationResult = .success(.fixture(name: "OrgTest"))

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        var expectedState = CipherItemState(
            existing: cipherItem,
            hasPremium: true,
            iconBaseURL: URL(string: "https://example.com/icons")!
        )!

        expectedState.allUserCollections = collections
        expectedState.organizationName = "OrgTest"

        XCTAssertTrue(subject.state.hasPremiumFeatures)
        XCTAssertEqual(subject.state.loadingState, .data(expectedState))
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository when
    /// cipher belongs to an organization and to collections which update the ones to display
    @MainActor
    func test_perform_appearedWithOrganizationAndCollectionsDisplay() {
        let account = Account.fixture()
        stateService.activeAccount = account
        vaultRepository.doesActiveAccountHavePremiumResult = true
        let collections = [
            CollectionView.fixture(id: "1"),
            CollectionView.fixture(id: "2"),
            CollectionView.fixture(id: "3"),
        ]
        vaultRepository.fetchCollectionsResult = .success(collections)

        let cipherItem = CipherView.fixture(
            collectionIds: ["2", "3"],
            id: "id",
            login: LoginView(
                username: "username",
                password: "password",
                passwordRevisionDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil,
                fido2Credentials: nil
            ),
            name: "Name",
            notes: "Notes",
            organizationId: "1",
            viewPassword: true
        )
        vaultRepository.cipherDetailsSubject.send(cipherItem)
        vaultRepository.fetchOrganizationResult = .success(.fixture(name: "OrgTest"))

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        var expectedState = CipherItemState(
            existing: cipherItem,
            hasPremium: true,
            iconBaseURL: URL(string: "https://example.com/icons")!
        )!

        expectedState.allUserCollections = collections
        expectedState.isShowingMultipleCollections = false
        expectedState.organizationName = "OrgTest"

        XCTAssertTrue(subject.state.hasPremiumFeatures)
        XCTAssertEqual(subject.state.loadingState, .data(expectedState))
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

    /// `perform` with `.checkPasswordPressed` records any errors.
    @MainActor
    func test_perform_checkPasswordPressed_error() async throws {
        let cipher = CipherView.loginFixture(login: .fixture(password: "password1234"))
        subject.state.loadingState = try .data(XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true)))
        client.result = .httpFailure(BitwardenTestError.example)

        await subject.perform(.checkPasswordPressed)

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform` with `.checkPasswordPressed` shows an alert if the password has been exposed.
    @MainActor
    func test_perform_checkPasswordPressed_exposedPassword() async throws {
        let cipher = CipherView.loginFixture(login: .fixture(password: "password1234"))
        subject.state.loadingState = try .data(XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true)))
        client.result = .httpSuccess(testData: .hibpLeakedPasswords)

        await subject.perform(.checkPasswordPressed)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/e6b6a"))
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.passwordExposed(1957),
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        ))
    }

    /// `perform` with `.checkPasswordPressed` shows an alert notifying the user that
    /// their password has not been found in a data breach.
    @MainActor
    func test_perform_checkPasswordPressed_safePassword() async throws {
        let cipher = CipherView.loginFixture(login: .fixture(password: "iqpeor,kmn!JO8932jldfasd"))
        subject.state.loadingState = try .data(XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true)))
        client.result = .httpSuccess(testData: .hibpLeakedPasswords)

        await subject.perform(.checkPasswordPressed)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/c3ed8"))
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.passwordSafe,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        ))
    }

    /// `perform(_:)` with `.totpCodeExpired` updates the totp code.
    @MainActor
    func test_perform_totpCodeExpired() async throws {
        let totpKey = TOTPKeyModel(authenticatorKey: .standardTotpKey)
        let cipherView = CipherView.fixture(login: .fixture(totp: totpKey.rawAuthenticatorKey))
        let cipherState = try XCTUnwrap(CipherItemState(existing: cipherView, hasPremium: true))
        subject.state.loadingState = .data(cipherState)
        subject.state.hasPremiumFeatures = true
        vaultRepository.refreshTOTPCodeResult = .success(LoginTOTPState("Test"))

        await subject.perform(.totpCodeExpired)

        XCTAssertEqual(subject.state.loadingState.data?.loginState.totpState, LoginTOTPState("Test"))
    }

    /// `perform(_:)` with `.totpCodeExpired` records any errors.
    @MainActor
    func test_perform_totpCodeExpired_error() async throws {
        let totpKey = TOTPKeyModel(authenticatorKey: .standardTotpKey)
        let cipherView = CipherView.fixture(login: .fixture(totp: totpKey.rawAuthenticatorKey))
        let cipherState = try XCTUnwrap(CipherItemState(existing: cipherView, hasPremium: true))
        subject.state.loadingState = .data(cipherState)
        subject.state.hasPremiumFeatures = true
        vaultRepository.refreshTOTPCodeResult = .failure(BitwardenTestError.example)

        await subject.perform(.totpCodeExpired)

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `receive` with `.cardItemAction` while loading logs an error.
    @MainActor
    func test_receive_cardItemAction_impossible_loading() throws {
        subject.state.loadingState = .loading(nil)
        subject.receive(.cardItemAction(.toggleCodeVisibilityChanged(true)))
        XCTAssertEqual(
            errorReporter.errors.first as? ViewItemProcessor.ActionError,
            ViewItemProcessor.ActionError.dataNotLoaded("Cannot handle card action without loaded data")
        )
    }

    /// `receive` with `.cardItemAction` throws if the cipher is not of card type.
    @MainActor
    func test_receive_cardItemAction_impossible_nonCard() throws {
        let cipherView = CipherView.fixture(
            id: "123",
            login: nil,
            name: "name",
            revisionDate: Date(),
            type: .login
        )
        let cipherState = CipherItemState(
            existing: cipherView,
            hasPremium: true
        )!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.cardItemAction(.toggleCodeVisibilityChanged(true)))
        XCTAssertEqual(
            errorReporter.errors.first as? ViewItemProcessor.ActionError,
            ViewItemProcessor.ActionError.nonCardTypeToggle("Cannot handle card action on non-card type")
        )
    }

    /// `receive` with `.passwordVisibilityPressed` with a login state toggles the value
    /// for `isPasswordVisible`.
    @MainActor
    func test_receive_cardItemAction_code() throws {
        let cipherView = CipherView.cardFixture(id: "123")
        var cipherState = CipherItemState(
            existing: cipherView,
            hasPremium: true
        )!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.cardItemAction(.toggleCodeVisibilityChanged(true)))

        cipherState.cardItemState.isCodeVisible = true
        XCTAssertEqual(subject.state.loadingState, .data(cipherState))
    }

    /// `receive` with `.passwordVisibilityPressed` with a login state toggles the value
    /// for `isPasswordVisible`.
    @MainActor
    func test_receive_cardItemAction_number() throws {
        let cipherView = CipherView.cardFixture(id: "123")
        var cipherState = CipherItemState(
            existing: cipherView,
            hasPremium: true
        )!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.cardItemAction(.toggleNumberVisibilityChanged(true)))

        cipherState.cardItemState.isNumberVisible = true
        XCTAssertEqual(subject.state.loadingState, .data(cipherState))
    }

    /// `receive` with `.copyPressed` copies the value with the pasteboard service and shows a toast.
    @MainActor
    func test_receive_copyPressed() {
        let cipherView = CipherView.cardFixture(id: "123")
        let cipherState = CipherItemState(
            existing: cipherView,
            hasPremium: true
        )!
        subject.state.loadingState = .data(cipherState)

        subject.receive(.copyPressed(value: "card number", field: .cardNumber))
        XCTAssertEqual(pasteboardService.copiedString, "card number")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.number)))

        subject.receive(.copyPressed(value: "hidden field value", field: .customHiddenField))
        XCTAssertEqual(pasteboardService.copiedString, "hidden field value")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.value)))
        waitFor(eventService.collectEventType == .cipherClientCopiedHiddenField)
        XCTAssertEqual(eventService.collectCipherId, "123")

        subject.receive(.copyPressed(value: "text field value", field: .customTextField))
        XCTAssertEqual(pasteboardService.copiedString, "text field value")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.value)))

        subject.receive(.copyPressed(value: "password", field: .password))
        XCTAssertEqual(pasteboardService.copiedString, "password")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.password)))
        waitFor(eventService.collectEventType == .cipherClientCopiedPassword)
        XCTAssertEqual(eventService.collectCipherId, "123")

        subject.receive(.copyPressed(value: "security code", field: .securityCode))
        XCTAssertEqual(pasteboardService.copiedString, "security code")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.securityCode)))
        waitFor(eventService.collectEventType == .cipherClientCopiedCardCode)
        XCTAssertEqual(eventService.collectCipherId, "123")

        subject.receive(.copyPressed(value: "totp", field: .totp))
        XCTAssertEqual(pasteboardService.copiedString, "totp")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.totp)))

        subject.receive(.copyPressed(value: "username", field: .username))
        XCTAssertEqual(pasteboardService.copiedString, "username")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.username)))
    }

    /// `recieve` with `.copyPressed` doesn't copy if the data isn't loaded.
    @MainActor
    func test_receive_copyPressed_notLoaded() {
        subject.receive(.copyPressed(value: "card number", field: .cardNumber))
        XCTAssertNil(pasteboardService.copiedString)
        XCTAssertNil(subject.state.toast)
    }

    /// `receive` with `.customFieldVisibilityPressed()` toggles custom field visibility.
    @MainActor
    func test_receive_customFieldVisiblePressed_withValidField() throws {
        let customField1 = CustomFieldState(
            isPasswordVisible: false,
            linkedIdType: nil,
            name: "name 1",
            type: .hidden,
            value: "value 1"
        )
        let customField2 = CustomFieldState(
            isPasswordVisible: false,
            linkedIdType: nil,
            name: "name 2",
            type: .hidden,
            value: "value 2"
        )
        let customField3 = CustomFieldState(
            isPasswordVisible: false,
            linkedIdType: nil,
            name: "name 3",
            type: .hidden,
            value: "value 3"
        )
        var cipherState = CipherItemState(
            existing: CipherView.loginFixture(),
            hasPremium: true
        )!
        cipherState.customFieldsState.customFields = [
            customField1,
            customField2,
            customField3,
        ]
        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state

        subject.receive(.customFieldVisibilityPressed(customField2))
        let newLoadingState = try XCTUnwrap(subject.state.loadingState.data)
        guard let loadingState = newLoadingState.viewState else {
            XCTFail("ViewItemState has incorrect value: \(newLoadingState)")
            return
        }
        let customFields = loadingState.customFieldsState.customFields
        XCTAssertEqual(customFields.count, 3)
        XCTAssertFalse(customFields[0].isPasswordVisible)
        XCTAssertTrue(customFields[1].isPasswordVisible)
        XCTAssertFalse(customFields[2].isPasswordVisible)
    }

    /// `receive` with `.customFieldVisibilityPressed()` while loading logs an error.
    @MainActor
    func test_receive_customFieldVisiblePressed_impossible() throws {
        let customField = CustomFieldState(
            isPasswordVisible: false,
            linkedIdType: nil,
            name: "name 2",
            type: .hidden,
            value: "value 2"
        )
        subject.state.loadingState = .loading(nil)
        subject.receive(.customFieldVisibilityPressed(customField))
        XCTAssertEqual(
            errorReporter.errors.first as? ViewItemProcessor.ActionError,
            ViewItemProcessor.ActionError
                .dataNotLoaded("Cannot toggle password for non-loaded item.")
        )
    }

    /// `receive` with `.dismissPressed` navigates to the `.dismiss` route.
    @MainActor
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    /// `receive` with `.disappeared` should clear streamCipherDetailsTask.
    @MainActor
    func test_receive_disappearPressed() {
        let account = Account.fixture()
        stateService.activeAccount = account

        XCTAssertNil(subject.streamCipherDetailsTask)
        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        XCTAssertNotNil(subject.streamCipherDetailsTask)
        subject.receive(.disappeared)
        XCTAssertNil(subject.streamCipherDetailsTask)
    }

    /// `perform(_:)` with `.deletePressed` presents the confirmation alert before delete the item and displays
    /// generic error alert if soft deleting fails.
    @MainActor
    func test_perform_deletePressed_genericError() async throws {
        let cipherState = CipherItemState(
            existing: CipherView.loginFixture(id: "123"),
            hasPremium: false
        )!

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state
        struct TestError: Error, Equatable {}
        vaultRepository.softDeleteCipherResult = .failure(TestError())
        await subject.perform(.deletePressed)
        // Ensure the alert is shown.
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert, .deleteCipherConfirmation(isSoftDelete: true) {})

        // Tap the "Yes" button on the alert.
        let action = try XCTUnwrap(alert?.alertActions.first(where: { $0.title == Localizations.yes }))
        await action.handler?(action, [])

        // Ensure the generic error alert is displayed.
        let errorAlert = try XCTUnwrap(coordinator.errorAlertsShown.last)
        XCTAssertEqual(errorAlert as? TestError, TestError())
        XCTAssertEqual(errorReporter.errors.first as? TestError, TestError())
    }

    /// `perform(_:)` with `.deletePressed` presents a confirmation alert before deleting the item.
    /// On failure, a generic error alert is displayed.
    @MainActor
    func test_perform_deletePressed_genericError_permanentDelete() async throws {
        let cipherState = CipherItemState(
            existing: CipherView.loginFixture(deletedDate: .now, id: "123"),
            hasPremium: false
        )!

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state
        struct TestError: Error, Equatable {}
        vaultRepository.deleteCipherResult = .failure(TestError())
        await subject.perform(.deletePressed)
        // Ensure the alert is shown.
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert, .deleteCipherConfirmation(isSoftDelete: false) {})

        // Tap the "Yes" button on the alert.
        let action = try XCTUnwrap(alert?.alertActions.first(where: { $0.title == Localizations.yes }))
        await action.handler?(action, [])

        // Ensure the generic error alert is displayed.
        let errorAlert = try XCTUnwrap(coordinator.errorAlertsShown.last)
        XCTAssertEqual(errorAlert as? TestError, TestError())
        XCTAssertEqual(errorReporter.errors.first as? TestError, TestError())
    }

    /// `perform(_:)` with `.deletePressed` presents the confirmation alert before permanently
    /// deleting the item from the trash.
    @MainActor
    func test_perform_deletePressed_showsPermanentDeleteConfirmationAlert() async throws {
        let cipherState = CipherItemState(
            existing: CipherView.loginFixture(deletedDate: .now, id: "123"),
            hasPremium: false
        )!

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state
        await subject.perform(.deletePressed)

        // Ensure the alert is shown.
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert, .deleteCipherConfirmation(isSoftDelete: false) {})
    }

    /// `perform(_:)` with `.deletePressed` presents the confirmation alert before soft deleting the item.
    @MainActor
    func test_perform_deletePressed_showsSoftDeleteConfirmationAlert() async throws {
        let cipherState = CipherItemState(
            existing: CipherView.loginFixture(id: "123"),
            hasPremium: false
        )!

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state
        vaultRepository.softDeleteCipherResult = .success(())
        await subject.perform(.deletePressed)
        // Ensure the alert is shown.
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert, .deleteCipherConfirmation(isSoftDelete: true) {})
    }

    /// `perform(_:)` with `.deletePressed` presents the confirmation alert before delete the item and displays
    /// toast if soft deleting succeeds.
    @MainActor
    func test_perform_deletePressed_success() async throws {
        let cipherState = CipherItemState(
            existing: CipherView.loginFixture(id: "123"),
            hasPremium: false
        )!

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state
        vaultRepository.softDeleteCipherResult = .success(())
        await subject.perform(.deletePressed)
        // Ensure the alert is shown.
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert, .deleteCipherConfirmation(isSoftDelete: true) {})

        // Tap the "Yes" button on the alert.
        let action = try XCTUnwrap(alert?.alertActions.first(where: { $0.title == Localizations.yes }))
        await action.handler?(action, [])

        XCTAssertNil(errorReporter.errors.first)
        // Ensure the cipher is deleted and the view is dismissed.
        XCTAssertEqual(vaultRepository.softDeletedCipher.last?.id, "123")
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = coordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        XCTAssertTrue(delegate.itemSoftDeletedCalled)
    }

    /// `perform(_:)` with `.deletePressed` presents the confirmation alert before delete the item and displays
    /// toast if permanently deleting succeeds.
    @MainActor
    func test_perform_deletePressed_success_permanent_delete() async throws {
        let cipherState = CipherItemState(
            existing: CipherView.loginFixture(deletedDate: .now, id: "123"),
            hasPremium: false
        )!

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state
        vaultRepository.softDeleteCipherResult = .success(())
        await subject.perform(.deletePressed)
        // Ensure the alert is shown.
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert, .deleteCipherConfirmation(isSoftDelete: false) {})

        // Tap the "Yes" button on the alert.
        let action = try XCTUnwrap(alert?.alertActions.first(where: { $0.title == Localizations.yes }))
        await action.handler?(action, [])

        XCTAssertNil(errorReporter.errors.first)
        // Ensure the cipher is deleted and the view is dismissed.
        XCTAssertEqual(vaultRepository.deletedCipher.last, "123")
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = coordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        XCTAssertTrue(delegate.itemDeletedCalled)
    }

    /// `perform(_:)` with `.restorePressed` presents the confirmation alert before restore the item and displays
    /// generic error alert if restoring fails.
    @MainActor
    func test_perform_restorePressed_genericError() async throws {
        let cipherState = CipherItemState(
            existing: CipherView.loginFixture(deletedDate: .now, id: "123"),
            hasPremium: false
        )!

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state
        struct TestError: Error, Equatable {}
        vaultRepository.restoreCipherResult = .failure(TestError())
        await subject.perform(.restorePressed)
        // Ensure the alert is shown.
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert?.title, Localizations.doYouReallyWantToRestoreCipher)
        XCTAssertNil(alert?.message)

        // Tap the "Yes" button on the alert.
        let action = try XCTUnwrap(alert?.alertActions.first(where: { $0.title == Localizations.yes }))
        await action.handler?(action, [])

        // Ensure the generic error alert is displayed.
        let errorAlert = try XCTUnwrap(coordinator.errorAlertsShown.last)
        XCTAssertEqual(errorAlert as? TestError, TestError())
        XCTAssertEqual(errorReporter.errors.first as? TestError, TestError())
    }

    /// `perform(_:)` with `.restorePressed` presents the confirmation alert before restore the item and displays
    /// toast if restoring succeeds.
    @MainActor
    func test_perform_restorePressed_success() async throws {
        let cipherState = CipherItemState(
            existing: CipherView.loginFixture(deletedDate: .now, id: "123"),
            hasPremium: false
        )!

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state
        vaultRepository.softDeleteCipherResult = .success(())
        await subject.perform(.restorePressed)
        // Ensure the alert is shown.
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert?.title, Localizations.doYouReallyWantToRestoreCipher)
        XCTAssertNil(alert?.message)

        // Tap the "Yes" button on the alert.
        let action = try XCTUnwrap(alert?.alertActions.first(where: { $0.title == Localizations.yes }))
        await action.handler?(action, [])

        XCTAssertNil(errorReporter.errors.first)
        // Ensure the cipher is deleted and the view is dismissed.
        XCTAssertEqual(vaultRepository.restoredCipher.last?.id, "123")
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = coordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        XCTAssertTrue(delegate.itemRestoredCalled)
    }

    /// `perform(_:)` with `.toggleDisplayMultipleCollections` doesn't update the state if
    /// loadingState is not `.data(:)`
    @MainActor
    func test_perform_toggleDisplayMultipleCollectionsNoAction() async throws {
        let state = ViewItemState(
            loadingState: .loading(nil)
        )
        subject.state = state

        await subject.perform(.toggleDisplayMultipleCollections)

        XCTAssertTrue(subject.state.loadingState == .loading(nil))
    }

    /// `perform(_:)` with `.toggleDisplayMultipleCollections` doesn't update the state if
    /// there are no collection ids in cipher state.
    @MainActor
    func test_perform_toggleDisplayMultipleCollectionsNoCollectionIds() async throws {
        let cipherState = CipherItemState(
            existing: .fixture(),
            hasPremium: false
        )!

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state

        await subject.perform(.toggleDisplayMultipleCollections)

        guard case let .data(cipherState) = subject.state.loadingState else {
            XCTFail("There should be data in the loadingState.")
            return
        }
        XCTAssertTrue(cipherState.cipherCollectionsToDisplay.isEmpty)
    }

    /// `perform(_:)` with `.toggleDisplayMultipleCollections` doesn't update the state if
    /// there are collection ids in cipher state but no cipher collections to display.
    @MainActor
    func test_perform_toggleDisplayMultipleCollectionsNoCollectionToDisplay() async throws {
        let cipherState = CipherItemState(
            existing: .fixture(collectionIds: ["1", "2"]),
            hasPremium: false
        )!

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state

        await subject.perform(.toggleDisplayMultipleCollections)

        guard case let .data(cipherState) = subject.state.loadingState else {
            XCTFail("There should be data in the loadingState.")
            return
        }
        XCTAssertTrue(cipherState.cipherCollectionsToDisplay.isEmpty)
    }

    /// `perform(_:)` with `.toggleDisplayMultipleCollections` updates the state when
    /// there are collection ids in cipher state and one cipher collections to display to many
    /// collections to display.
    @MainActor
    func test_perform_toggleDisplayMultipleCollectionsFromOneToMany() async throws {
        var cipherState = CipherItemState(
            existing: .fixture(collectionIds: ["1", "2", "4"]),
            hasPremium: false
        )!
        cipherState.allUserCollections = [
            .fixture(id: "1"),
            .fixture(id: "2"),
            .fixture(id: "3"),
            .fixture(id: "4"),
            .fixture(id: "5"),
        ]

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state

        await subject.perform(.toggleDisplayMultipleCollections)

        guard case let .data(cipherState) = subject.state.loadingState else {
            XCTFail("There should be data in the loadingState.")
            return
        }
        XCTAssertEqual(cipherState.cipherCollectionsToDisplay.count, 3)
        XCTAssertEqual(cipherState.cipherCollectionsToDisplay[0].id, "1")
        XCTAssertEqual(cipherState.cipherCollectionsToDisplay[1].id, "2")
        XCTAssertEqual(cipherState.cipherCollectionsToDisplay[2].id, "4")
    }

    /// `perform(_:)` with `.toggleDisplayMultipleCollections` updates the state when
    /// there are collection ids in cipher state and many cipher collections to display to one
    /// collection to display.
    @MainActor
    func test_perform_toggleDisplayMultipleCollectionsFromManyToOne() async throws {
        var cipherState = CipherItemState(
            existing: .fixture(collectionIds: ["2", "3", "5"]),
            hasPremium: false
        )!
        cipherState.allUserCollections = [
            .fixture(id: "1"),
            .fixture(id: "2"),
            .fixture(id: "3"),
            .fixture(id: "4"),
            .fixture(id: "5"),
        ]
        cipherState.isShowingMultipleCollections = true

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state

        await subject.perform(.toggleDisplayMultipleCollections)

        guard case let .data(cipherState) = subject.state.loadingState else {
            XCTFail("There should be data in the loadingState.")
            return
        }
        XCTAssertEqual(cipherState.cipherCollectionsToDisplay.count, 1)
        XCTAssertEqual(cipherState.cipherCollectionsToDisplay[0].id, "2")
    }

    /// `.receive(_:)` with `.downloadAttachment(_)` shows an alert and downloads the attachment for large attachments.
    @MainActor
    func test_receive_downloadAttachment() async throws {
        // Set up the mock results.
        vaultRepository.downloadAttachmentResult = .success(.example)
        let attachment = AttachmentView.fixture(size: "11000000", sizeName: "big")
        let cipher = CipherView.fixture(attachments: [attachment])
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        subject.state.loadingState = .data(state)

        // Attempt to download the attachment.
        subject.receive(.downloadAttachment(attachment))

        // Confirm on the alert
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Confirm the results.
        XCTAssertEqual(vaultRepository.downloadAttachmentAttachment, attachment)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.downloading)
        XCTAssertEqual(coordinator.routes.last, .saveFile(temporaryUrl: .example))
    }

    /// `.receive(_:)` with `.downloadAttachment(_)`handles any errors.
    @MainActor
    func test_receive_downloadAttachment_error() async throws {
        // Set up the mock results.
        vaultRepository.downloadAttachmentResult = .failure(BitwardenTestError.example)
        let attachment = AttachmentView.fixture(size: "11000000", sizeName: "big")
        let cipher = CipherView.fixture(attachments: [attachment])
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        subject.state.loadingState = .data(state)

        // Attempt to download the attachment.
        subject.receive(.downloadAttachment(attachment))

        // Confirm on the alert
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Confirm the results.
        XCTAssertEqual(vaultRepository.downloadAttachmentAttachment, attachment)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.downloading)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.unableToDownloadFile))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `.receive(_:)` with `.downloadAttachment(_)` shows an alert if the data wasn't saved to a url.
    @MainActor
    func test_receive_downloadAttachment_nilUrl() async throws {
        // Set up the mock results.
        vaultRepository.downloadAttachmentResult = .success(nil)
        let attachment = AttachmentView.fixture(size: "11000000", sizeName: "big")
        let cipher = CipherView.fixture(attachments: [attachment])
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        subject.state.loadingState = .data(state)

        // Attempt to download the attachment.
        subject.receive(.downloadAttachment(attachment))

        // Confirm on the alert
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Confirm the results.
        XCTAssertEqual(vaultRepository.downloadAttachmentAttachment, attachment)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.downloading)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.unableToDownloadFile))
    }

    /// `.receive(_:)` with `.downloadAttachment(_)` skips the confirmation alert for small files..
    @MainActor
    func test_receive_downloadAttachment_smallAttachment() throws {
        // Set up the mock results.
        vaultRepository.downloadAttachmentResult = .success(.example)
        let attachment = AttachmentView.fixture(size: "10", sizeName: "small")
        let cipher = CipherView.fixture(attachments: [attachment])
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        subject.state.loadingState = .data(state)

        // Attempt to download the attachment.
        let task = Task {
            subject.receive(.downloadAttachment(attachment))
        }

        // Confirm the results.
        waitFor(!coordinator.routes.isEmpty)
        task.cancel()
        XCTAssertTrue(coordinator.alertShown.isEmpty)
        XCTAssertEqual(coordinator.routes.last, .saveFile(temporaryUrl: .example))
    }

    /// `receive` with `.editPressed` has no change when the state is loading.
    @MainActor
    func test_receive_editPressed_loading() {
        subject.receive(.editPressed)
        XCTAssertEqual(coordinator.routes, [])
    }

    /// `receive` with `.editPressed`with data navigates to the edit item route.
    @MainActor
    func test_receive_editPressed_data() {
        let cipherView = CipherView.fixture(
            id: "123",
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil,
                fido2Credentials: nil
            ),
            name: "name",
            revisionDate: Date()
        )
        let loginState = CipherItemState(
            existing: cipherView,
            hasPremium: true
        )!
        subject.state.loadingState = .data(loginState)

        subject.receive(.editPressed)

        waitFor(!coordinator.routes.isEmpty)

        XCTAssertEqual(coordinator.routes, [.editItem(cipherView, true)])
    }

    /// `receive(_:)` with `.morePressed(.attachments)` navigates the user to attachments view.
    @MainActor
    func test_receive_morePressed_attachments() throws {
        let cipher = CipherView.fixture(id: "1")
        subject.state.loadingState = try .data(XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true)))

        subject.receive(.morePressed(.attachments))

        XCTAssertEqual(coordinator.routes.last, .attachments(cipher))
    }

    /// `receive(_:)` with `.morePressed(.clone)` navigates the user to the move to
    /// clone item view.
    @MainActor
    func test_receive_morePressed_clone() throws {
        let cipher = CipherView.fixture(id: "1")
        subject.state.loadingState = try .data(
            XCTUnwrap(
                CipherItemState(
                    existing: cipher,
                    hasPremium: false
                )
            )
        )

        subject.receive(.morePressed(.clone))

        waitFor(!coordinator.routes.isEmpty)

        XCTAssertEqual(coordinator.routes.last, .cloneItem(cipher: cipher, hasPremium: true))
        XCTAssertIdentical(coordinator.contexts.last as? ViewItemProcessor, subject)
    }

    /// `receive(_:)` with `.morePressed(.clone)` for a cipher with FIDO2 credentials shows an
    /// alert confirming that the user wants to proceed without cloning the FIDO2 credential and
    /// navigates the user to the clone item view.
    @MainActor
    func test_receive_morePressed_clone_fido2Credentials() throws {
        let cipher = CipherView.loginFixture(id: "1", login: .fixture(fido2Credentials: [.fixture()]))
        subject.state.loadingState = try .data(
            XCTUnwrap(
                CipherItemState(
                    existing: cipher,
                    hasPremium: false
                )
            )
        )

        subject.receive(.morePressed(.clone))

        waitFor(!coordinator.alertShown.isEmpty)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, Alert.confirmCloneExcludesFido2Credential {})

        let task = Task {
            try await alert.tapAction(title: Localizations.yes)
        }
        waitFor(!coordinator.routes.isEmpty)
        task.cancel()

        XCTAssertEqual(coordinator.routes.last, .cloneItem(cipher: cipher, hasPremium: true))
        XCTAssertIdentical(coordinator.contexts.last as? ViewItemProcessor, subject)
    }

    /// `receive(_:)` with `.morePressed(.editCollections)` navigates the user to the edit
    /// collections view.
    @MainActor
    func test_receive_morePressed_editCollections() throws {
        let cipher = CipherView.fixture(id: "1")
        subject.state.loadingState = try .data(
            XCTUnwrap(
                CipherItemState(
                    existing: cipher,
                    hasPremium: true
                )
            )
        )

        subject.receive(.morePressed(.editCollections))

        XCTAssertEqual(coordinator.routes.last, .editCollections(cipher))
        XCTAssertTrue(coordinator.contexts.last as? ViewItemProcessor === subject)
    }

    /// `receive(_:)` with `.morePressed()` shows an error alert if the data is unavailable.
    @MainActor
    func test_receive_morePressed_loading() throws {
        subject.state.loadingState = .loading(nil)

        subject.receive(.morePressed(.attachments))

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(
            errorReporter.errors.last as? ViewItemProcessor.ActionError,
            .dataNotLoaded("Cannot perform action on cipher until it's loaded.")
        )
    }

    /// `receive(_:)` with `.morePressed(.moveToOrganization)` navigates the user to the move to
    /// organization view.
    @MainActor
    func test_receive_morePressed_moveToOrganization() throws {
        let cipher = CipherView.fixture(id: "1")
        subject.state.loadingState = try .data(
            XCTUnwrap(
                CipherItemState(
                    existing: cipher,
                    hasPremium: false
                )
            )
        )

        subject.receive(.morePressed(.moveToOrganization))

        XCTAssertEqual(coordinator.routes.last, .moveToOrganization(cipher))
        XCTAssertTrue(coordinator.contexts.last as? ViewItemProcessor === subject)
    }

    /// `receive` with `.passwordHistoryPressed` navigates to the password history view.
    @MainActor
    func test_receive_passwordHistoryPressed() {
        subject.state.passwordHistory = [.fixture(), .fixture()]
        subject.receive(.passwordHistoryPressed)
        XCTAssertEqual(coordinator.routes.last, .passwordHistory([.fixture(), .fixture()]))
    }

    /// `receive` with `.passwordHistoryPressed` does nothing if there's no password history.
    @MainActor
    func test_receive_passwordHistoryPressed_noData() {
        subject.state.passwordHistory = nil
        subject.receive(.passwordHistoryPressed)
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `receive` with `.passwordVisibilityPressed` while loading logs an error.
    @MainActor
    func test_receive_passwordVisibilityPressed_impossible_loading() throws {
        subject.state.loadingState = .loading(nil)
        subject.receive(.passwordVisibilityPressed)
        XCTAssertEqual(
            errorReporter.errors.first as? ViewItemProcessor.ActionError,
            ViewItemProcessor.ActionError
                .dataNotLoaded("Cannot toggle password for non-loaded item.")
        )
    }

    /// `receive` with `.passwordVisibilityPressed` while loading logs an error.
    @MainActor
    func test_receive_passwordVisibilityPressed_impossible_nonLogin() throws {
        let cipherView = CipherView.fixture(
            id: "123",
            login: nil,
            name: "name",
            revisionDate: Date(),
            type: .card
        )
        let cipherState = CipherItemState(
            existing: cipherView,
            hasPremium: true
        )!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.passwordVisibilityPressed)
        XCTAssertEqual(
            errorReporter.errors.first as? ViewItemProcessor.ActionError,
            ViewItemProcessor.ActionError
                .nonLoginPasswordToggle("Cannot toggle password for non-login item.")
        )
    }

    /// `receive` with `.passwordVisibilityPressed` with a login state toggles the value
    /// for `isPasswordVisible`.
    @MainActor
    func test_receive_passwordVisibilityPressed_withLoginState() {
        let cipherView = CipherView.fixture(
            id: "123",
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil,
                fido2Credentials: nil
            ),
            name: "name",
            revisionDate: Date()
        )
        var cipherState = CipherItemState(
            existing: cipherView,
            hasPremium: true
        )!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.passwordVisibilityPressed)

        cipherState.loginState.isPasswordVisible = true
        XCTAssertEqual(subject.state.loadingState, .data(cipherState))
    }

    /// `receive(_:)` with `.sshKeyItemAction` with `.privateKeyVisibilityPressed`  toggles
    /// the visibility of the `privateKey` field.
    @MainActor
    func test_receive_sshKeyItemAction_privateKeyVisibilityPressed() {
        initializeSshKeyState()
        subject.receive(.sshKeyItemAction(.privateKeyVisibilityPressed))

        XCTAssertTrue(subject.state.loadingState.data?.sshKeyState.isPrivateKeyVisible == true)
    }

    /// `receive(_:)` with `.sshKeyItemAction` with `.privateKeyVisibilityPressed`  but data is not loaded yet
    /// throws.
    @MainActor
    func test_receive_sshKeyItemAction_privateKeyVisibilityPressedLoadingLogsError() async throws {
        subject.state.loadingState = .loading(nil)
        subject.receive(.sshKeyItemAction(.privateKeyVisibilityPressed))

        XCTAssertEqual(
            errorReporter.errors.last as? ViewItemProcessor.ActionError,
            .dataNotLoaded("Cannot handle SSH key action without loaded data")
        )
    }

    /// `receive(_:)` with `.sshKeyItemAction` with `.privateKeyVisibilityPressed`  but data is not loaded yet
    /// throws.
    @MainActor
    func test_receive_sshKeyItemAction_privateKeyVisibilityPressedNotSshKeyTypeLogsError() async throws {
        var cipherItemState = CipherItemState(
            existing: .fixture(),
            hasPremium: true
        )!
        cipherItemState.type = .login
        subject.state.loadingState = .data(cipherItemState)

        subject.receive(.sshKeyItemAction(.privateKeyVisibilityPressed))

        XCTAssertEqual(
            errorReporter.errors.last as? ViewItemProcessor.ActionError,
            .nonSshKeyTypeToggle("Cannot handle SSH key action on non SSH key type")
        )
    }

    /// `receive(_:)` with `.sshKeyItemAction` with `.copyPressed`  copies the corresponding field.
    @MainActor
    func test_receive_sshKeyItemAction_copyPressed() async throws {
        initializeSshKeyState(reprompt: .none)

        subject.receive(.sshKeyItemAction(.copyPressed(value: "privateKey", field: .sshPrivateKey)))
        XCTAssertEqual(pasteboardService.copiedString, "privateKey")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.privateKey)))

        subject.receive(.sshKeyItemAction(.copyPressed(value: "publicKey", field: .sshPublicKey)))
        XCTAssertEqual(pasteboardService.copiedString, "publicKey")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.publicKey)))

        subject.receive(.sshKeyItemAction(.copyPressed(value: "fingerprint", field: .sshKeyFingerprint)))
        XCTAssertEqual(pasteboardService.copiedString, "fingerprint")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.fingerprint)))
    }

    /// `receive(_:)` with `.toastShown` with a value updates the state correctly.
    @MainActor
    func test_receive_toastShown_withValue() {
        let toast = Toast(title: "123")
        subject.receive(.toastShown(toast))

        XCTAssertEqual(subject.state.toast, toast)
    }

    /// `getter:rehydrationState` returns the proper state with the cipher id.
    @MainActor
    func test_rehydrationState() {
        XCTAssertEqual(subject.rehydrationState?.target, .viewCipher(cipherId: "id"))
    }

    // MARK: Private

    /// Initializes the state for a cipher of type `.sshKey`.
    @MainActor
    private func initializeSshKeyState(reprompt: BitwardenSdk.CipherRepromptType = .none) {
        let cipherView = CipherView.fixture(
            id: "123",
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil,
                fido2Credentials: nil
            ),
            name: "name",
            reprompt: reprompt,
            revisionDate: Date()
        )
        var cipherItemState = CipherItemState(
            existing: cipherView,
            hasPremium: true
        )!
        cipherItemState.type = .sshKey
        cipherItemState.sshKeyState = SSHKeyItemState(
            isPrivateKeyVisible: false,
            privateKey: "privateKey",
            publicKey: "publicKey",
            keyFingerprint: "fingerprint"
        )
        subject.state.loadingState = .data(cipherItemState)
    }
} // swiftlint:disable:this file_length
