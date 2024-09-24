import XCTest

// swiftlint:disable file_length

@testable import AuthenticatorShared

// MARK: - ItemListProcessorTests

class ItemListProcessorTests: AuthenticatorTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var application: MockApplication!
    var appSettingsStore: MockAppSettingsStore!
    var authItemRepository: MockAuthenticatorItemRepository!
    var cameraService: MockCameraService!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<ItemListRoute, ItemListEvent>!
    var errorReporter: MockErrorReporter!
    var totpService: MockTOTPService!
    var subject: ItemListProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        application = MockApplication()
        appSettingsStore = MockAppSettingsStore()
        authItemRepository = MockAuthenticatorItemRepository()
        cameraService = MockCameraService()
        configService = MockConfigService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        totpService = MockTOTPService()

        let services = ServiceContainer.withMocks(
            application: application,
            appSettingsStore: appSettingsStore,
            authenticatorItemRepository: authItemRepository,
            cameraService: cameraService,
            configService: configService,
            errorReporter: errorReporter,
            totpService: totpService
        )

        subject = ItemListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: ItemListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `itemDeleted()` delegate method shows the expected toast.
    func test_delegate_itemDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemDeleted()
        XCTAssertEqual(subject.state.toast?.text, Localizations.itemDeleted)
    }

    /// `perform(_:)` with `.addItemPressed` and authorized camera
    /// navigates to `.showScanCode`
    func test_perform_addItemPressed_authorizedCamera() {
        cameraService.deviceHasCamera = true
        cameraService.cameraAuthorizationStatus = .authorized
        let task = Task {
            await subject.perform(.addItemPressed)
        }
        waitFor(!coordinator.events.isEmpty)
        task.cancel()
        XCTAssertEqual(coordinator.events, [.showScanCode])
    }

    /// `perform(_:)` with `.addItemPressed` and denied camera
    /// navigates to `.setupTotpManual`
    func test_perform_addItemPressed_deniedCamera() {
        cameraService.deviceHasCamera = true
        cameraService.cameraAuthorizationStatus = .denied
        let task = Task {
            await subject.perform(.addItemPressed)
        }
        waitFor(!coordinator.routes.isEmpty)
        task.cancel()
        XCTAssertEqual(coordinator.routes, [.setupTotpManual])
    }

    /// `perform(_:)` with `.addItemPressed` and no camera
    /// navigates to `.setupTotpManual`
    func test_perform_addItemPressed_noCamera() {
        cameraService.deviceHasCamera = false
        let task = Task {
            await subject.perform(.addItemPressed)
        }
        waitFor(!coordinator.routes.isEmpty)
        task.cancel()
        XCTAssertEqual(coordinator.routes, [.setupTotpManual])
    }

    /// `perform(_:)` with `.appeared` starts streaming vault items.
    func test_perform_appeared() {
        let result = ItemListItem.fixture(
            totp: .fixture(
                totpCode: TOTPCodeModel(
                    code: "654321",
                    codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                    period: 30
                )
            )
        )
        let resultSection = ItemListSection(id: "", items: [result], name: "Items")

        authItemRepository.itemListSubject.send([resultSection])
        authItemRepository.refreshTotpCodesResult = .success([result])

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        XCTAssertEqual(authItemRepository.refreshedTotpCodes, [result])
        XCTAssertEqual(subject.state.loadingState, .data([resultSection]))
    }

    /// `perform(_:)` with `.appeared` records any errors.
    func test_perform_appeared_error_vaultListGroupSubjectFail() {
        authItemRepository.itemListSubject.send(completion: .failure(AuthenticatorTestError.example))

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()

        XCTAssertEqual(errorReporter.errors.last as? AuthenticatorTestError, .example)
    }

    /// `perform(_:)` with `.appeared` handles TOTP Code expiration
    /// with updates the state's TOTP codes.
    func test_perform_appeared_totpExpired_single() throws { // swiftlint:disable:this function_body_length
        let firstItem = ItemListItem.fixture(
            totp: .fixture(
                totpCode: TOTPCodeModel(
                    code: "",
                    codeGenerationDate: Date(timeIntervalSinceNow: -61),
                    period: 30
                )
            )
        )
        let firstSection = ItemListSection(
            id: "",
            items: [firstItem],
            name: "Items"
        )

        let secondItem = ItemListItem.fixture(
            totp: .fixture(
                totpCode: TOTPCodeModel(
                    code: "345678",
                    codeGenerationDate: Date(timeIntervalSinceNow: -61),
                    period: 30
                )
            )
        )
        let secondSection = ItemListSection(
            id: "",
            items: [secondItem],
            name: "Items"
        )

        let thirdModel = TOTPCodeModel(
            code: "654321",
            codeGenerationDate: Date(),
            period: 30
        )
        let thirdItem = ItemListItem.fixture(
            totp: .fixture(
                totpCode: thirdModel
            )
        )
        let thirdResultSection = ItemListSection(id: "", items: [thirdItem], name: "Items")

        authItemRepository.refreshTotpCodesResult = .success([secondItem])
        let task = Task {
            await subject.perform(.appeared)
        }
        authItemRepository.itemListSubject.send([firstSection])
        waitFor(subject.state.loadingState.data == [secondSection])
        authItemRepository.refreshTotpCodesResult = .success([thirdItem])
        waitFor(subject.state.loadingState.data == [thirdResultSection])

        task.cancel()
        XCTAssertEqual([secondItem], authItemRepository.refreshedTotpCodes)
        let first = try XCTUnwrap(subject.state.loadingState.data?.first)
        XCTAssertEqual(first, thirdResultSection)
    }

    /// `perform(:_)` with `.search` updates search results in the state.
    func test_perform_search() {
        let result = ItemListItem.fixture(
            totp: .fixture(
                totpCode: TOTPCodeModel(
                    code: "654321",
                    codeGenerationDate: Date(year: 2024, month: 6, day: 28),
                    period: 30
                )
            )
        )

        authItemRepository.searchItemListSubject.send([result])
        authItemRepository.refreshTotpCodesResult = .success([result])

        let task = Task {
            await subject.perform(.search("text"))
        }

        waitFor(!subject.state.searchResults.isEmpty)
        task.cancel()

        XCTAssertEqual(authItemRepository.refreshedTotpCodes, [result])
        XCTAssertEqual(subject.state.searchResults, [result])
    }

    /// `perform(:_)` with `.search` with an empty string gets empty search results
    func test_perform_search_emptyString() async {
        await subject.perform(.search("   "))
        XCTAssertEqual(subject.state.searchResults.count, 0)
        XCTAssertEqual(
            subject.state.searchResults,
            []
        )
    }

    /// `perform(.search)` throws error and error is logged.
    func test_perform_search_error() async {
        authItemRepository.searchItemListSubject.send(completion: .failure(AuthenticatorTestError.example))
        await subject.perform(.search("example"))

        XCTAssertEqual(subject.state.searchResults.count, 0)
        XCTAssertEqual(
            subject.state.searchResults,
            []
        )
        XCTAssertEqual(errorReporter.errors as? [AuthenticatorTestError], [.example])
    }

    /// `perform(.search)` handles TOTP Code expiration
    /// with updates the state's TOTP codes.
    func test_perform_search_totpExpired() throws {
        let firstItem = ItemListItem.fixture(
            totp: .fixture(
                totpCode: TOTPCodeModel(
                    code: "123456",
                    codeGenerationDate: Date(timeIntervalSinceNow: -61),
                    period: 30
                )
            )
        )
        let firstSection = ItemListSection(id: "", items: [firstItem], name: "Items")
        subject.state.loadingState = .data([firstSection])

        let secondItem = ItemListItem.fixture(
            totp: .fixture(
                totpCode: TOTPCodeModel(
                    code: "345678",
                    codeGenerationDate: Date(timeIntervalSinceNow: -61),
                    period: 30
                )
            )
        )

        let thirdItem = ItemListItem.fixture(
            totp: .fixture(
                totpCode: TOTPCodeModel(
                    code: "654321",
                    codeGenerationDate: Date(),
                    period: 30
                )
            )
        )

        authItemRepository.refreshTotpCodesResult = .success([secondItem])
        let task = Task {
            subject.receive(.searchTextChanged("text"))
            await subject.perform(.search("text"))
        }
        authItemRepository.searchItemListSubject.send([firstItem])
        waitFor(!subject.state.searchResults.isEmpty)
        XCTAssertEqual(subject.state.searchResults, [secondItem])

        authItemRepository.refreshTotpCodesResult = .success([thirdItem])
        waitFor(authItemRepository.refreshedTotpCodes == [secondItem])
        waitFor(subject.state.searchResults == [thirdItem])

        task.cancel()
    }

    // MARK: AuthenticatorKeyCaptureDelegate Tests

    /// `didCompleteAutomaticCapture` failure
    func test_didCompleteAutomaticCapture_failure() {
        totpService.getTOTPConfigResult = .failure(TOTPServiceError.invalidKeyFormat)
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: "1234")
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        waitFor(!coordinator.alertShown.isEmpty)
        XCTAssertEqual(
            coordinator.alertShown.last,
            Alert(
                title: Localizations.keyReadError,
                message: nil,
                alertActions: [
                    AlertAction(title: Localizations.ok, style: .default),
                ]
            )
        )
        XCTAssertEqual(authItemRepository.addAuthItemAuthItems, [])
        XCTAssertNil(subject.state.toast)
    }

    /// `didCompleteAutomaticCapture` success
    func test_didCompleteAutomaticCapture_success() throws {
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: key)
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        waitFor(!authItemRepository.addAuthItemAuthItems.isEmpty)
        waitFor(subject.state.loadingState != .loading(nil))
        guard let item = authItemRepository.addAuthItemAuthItems.first
        else {
            XCTFail("Unable to get authenticator item")
            return
        }
        XCTAssertEqual(item.name, "")
        XCTAssertEqual(item.totpKey, String.base32Key)
    }

    /// Tests that the `itemListCardState` is set to `none` if the download card has been closed.
    func test_determineItemListCardState_closed_download() async {
        configService.featureFlagsBool = [.enablePasswordManagerSync: true]
        application.canOpenUrlResponse = false
        await subject.perform(.closeCard(.passwordManagerDownload))
        XCTAssertEqual(subject.state.itemListCardState, .none)
    }

    /// Tests that the `itemListCardState` is set to `none` if the sync card has been closed.
    func test_determineItemListCardState_closed_sync() async {
        configService.featureFlagsBool = [.enablePasswordManagerSync: true]
        application.canOpenUrlResponse = true
        await subject.perform(.closeCard(.passwordManagerSync))
        XCTAssertEqual(subject.state.itemListCardState, .none)
    }

    /// Tests that the `showPasswordManagerSyncCard` and `showPasswordManagerDownloadCard` are set
    /// to false if the feature flag is turned off.
    func test_determineItemListCardState_FeatureFlag_off() {
        subject.state.itemListCardState = .passwordManagerSync
        configService.featureFlagsBool = [.enablePasswordManagerSync: false]
        let task = Task {
            await self.subject.perform(.appeared)
        }

        waitFor(subject.state.itemListCardState == .none)
        task.cancel()
    }

    /// Tests that the `itemListCardState` is set to `passwordManagerDownload` if the feature flag is turned on.
    func test_determineItemListCardState_FeatureFlag_on_download() {
        configService.featureFlagsBool = [.enablePasswordManagerSync: true]
        application.canOpenUrlResponse = false
        let task = Task {
            await self.subject.perform(.appeared)
        }

        waitFor(subject.state.itemListCardState == .passwordManagerDownload)
        task.cancel()
    }

    /// Tests that the `itemListCardState` is set to `passwordManagerSync` if the feature flag is turned on.
    func test_determineItemListCardState_FeatureFlag_on_sync() {
        configService.featureFlagsBool = [.enablePasswordManagerSync: true]
        application.canOpenUrlResponse = true
        let task = Task {
            await self.subject.perform(.appeared)
        }

        waitFor(subject.state.itemListCardState == .passwordManagerSync)
        task.cancel()
    }
}
