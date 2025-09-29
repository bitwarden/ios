import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

// swiftlint:disable file_length

@testable import AuthenticatorShared

// MARK: - ItemListProcessorTests

class ItemListProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var application: MockApplication!
    var appSettingsStore: MockAppSettingsStore!
    var authItemRepository: MockAuthenticatorItemRepository!
    var cameraService: MockCameraService!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<ItemListRoute, ItemListEvent>!
    var errorReporter: MockErrorReporter!
    var notificationCenterService: MockNotificationCenterService!
    var pasteboardService: MockPasteboardService!
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
        notificationCenterService = MockNotificationCenterService()
        pasteboardService = MockPasteboardService()
        totpService = MockTOTPService()

        let services = ServiceContainer.withMocks(
            application: application,
            appSettingsStore: appSettingsStore,
            authenticatorItemRepository: authItemRepository,
            cameraService: cameraService,
            configService: configService,
            errorReporter: errorReporter,
            notificationCenterService: notificationCenterService,
            pasteboardService: pasteboardService,
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

        application = nil
        appSettingsStore = nil
        authItemRepository = nil
        cameraService = nil
        configService = nil
        errorReporter = nil
        notificationCenterService = nil
        pasteboardService = nil
        totpService = nil
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `itemDeleted()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_itemDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemDeleted()
        XCTAssertEqual(subject.state.toast?.text, Localizations.itemDeleted)
    }

    /// `perform(_:)` with `.addItemPressed` and authorized camera
    /// navigates to `.showScanCode`
    @MainActor
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
    @MainActor
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
    @MainActor
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
    @MainActor
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
        authItemRepository.itemListSubject.send(completion: .failure(BitwardenTestError.example))

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.appeared` handles TOTP Code expiration
    /// with updates the state's TOTP codes.
    @MainActor
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

    /// `perform(:_)` with `.copyPressed()` with a local item copies the code to the pasteboard
    /// and updates the toast in the state.
    @MainActor
    func test_perform_copyPressed_localItem() {
        let totpCode = "654321"
        let totpModel = TOTPCodeModel(code: totpCode,
                                      codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                                      period: 30)
        let localItem = ItemListItem.fixture()
        totpService.getTotpCodeResult = .success(totpModel)

        let task = Task {
            await subject.perform(.copyPressed(localItem))
        }
        defer { task.cancel() }

        waitFor(pasteboardService.copiedString != nil)

        XCTAssertEqual(pasteboardService.copiedString, totpCode)
        XCTAssertEqual(
            subject.state.toast?.text,
            Localizations.valueHasBeenCopied(Localizations.verificationCode)
        )
    }

    /// `perform(:_)` with `.copyPressed()` with a local item copies the code to the pasteboard
    /// and updates the toast in the state.
    @MainActor
    func test_perform_copyPressed_error() {
        let localItem = ItemListItem.fixture()
        totpService.getTotpCodeResult = .failure(BitwardenTestError.example)

        let task = Task {
            await subject.perform(.copyPressed(localItem))
        }
        defer { task.cancel() }

        waitFor(!errorReporter.errors.isEmpty)

        XCTAssertEqual(coordinator.alertShown,
                       [Alert.defaultAlert(title: Localizations.anErrorHasOccurred)])
    }

    /// `perform(:_)` with `.copyPressed()` with a shared item copies the code to the pasteboard
    /// and updates the toast in the state.
    @MainActor
    func test_perform_copyPressed_sharedItem() {
        let totpCode = "654321"
        let totpModel = TOTPCodeModel(code: totpCode,
                                      codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                                      period: 30)
        let sharedItem = ItemListItem.fixtureShared()
        totpService.getTotpCodeResult = .success(totpModel)

        let task = Task {
            await subject.perform(.copyPressed(sharedItem))
        }
        defer { task.cancel() }

        waitFor(pasteboardService.copiedString != nil)

        XCTAssertEqual(pasteboardService.copiedString, totpCode)
        XCTAssertEqual(
            subject.state.toast?.text,
            Localizations.valueHasBeenCopied(Localizations.verificationCode)
        )
    }

    /// `perform(:_)` with `.copyPressed()` with a `.syncError` item does not throw
    /// and produces no result.
    @MainActor
    func test_perform_copyPressed_syncError() async {
        await assertAsyncDoesNotThrow {
            await subject.perform(.copyPressed(.syncError()))
        }
        XCTAssertNil(subject.state.toast)
        XCTAssertNil(pasteboardService.copiedString)
    }

    /// `perform(:_)` with `.moveToBitwardenPressed()` with a local item stores the item in the shared
    /// store and launches the Bitwarden app via the new item  deep link.
    @MainActor
    func test_perform_moveToBitwardenPressed_localItem() async throws {
        authItemRepository.pmSyncEnabled = true
        application.canOpenUrlResponse = true
        let expected = AuthenticatorItemView.fixture()
        let localItem = ItemListItem.fixture(totp: .fixture(itemView: expected))

        await subject.perform(.moveToBitwardenPressed(localItem))

        waitFor(authItemRepository.tempItem != nil)
        XCTAssertEqual(authItemRepository.tempItem, expected)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.passwordManagerNewItem)
    }

    /// `perform(:_)` with `.moveToBitwardenPressed()` captures any errors thrown, logs them, and shows an
    /// error alert.
    @MainActor
    func test_perform_moveToBitwardenPressed_error() async throws {
        authItemRepository.pmSyncEnabled = true
        application.canOpenUrlResponse = true
        let localItem = ItemListItem.fixture()
        authItemRepository.tempItemErrorToThrow = BitwardenTestError.example

        await subject.perform(.moveToBitwardenPressed(localItem))

        waitFor(!errorReporter.errors.isEmpty)

        XCTAssertEqual(coordinator.alertShown,
                       [Alert.defaultAlert(title: Localizations.anErrorHasOccurred)])
    }

    /// `perform(:_)` with `.moveToBitwardenPressed()` does nothing when the Password Manager app is not
    /// installed - i.e. the `bitwarden://` urls cannot be opened.
    @MainActor
    func test_perform_moveToBitwardenPressed_passwordManagerAppNotInstalled() async throws {
        application.canOpenUrlResponse = false
        let localItem = ItemListItem.fixture()

        await subject.perform(.moveToBitwardenPressed(localItem))

        XCTAssertNil(authItemRepository.tempItem)
        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertNil(subject.state.url)
    }

    /// `perform(:_)` with `.moveToBitwardenPressed()` does nothing when called with a shared item.
    @MainActor
    func test_perform_moveToBitwardenPressed_sharedItem() async throws {
        application.canOpenUrlResponse = true
        let localItem = ItemListItem.fixtureShared()

        await subject.perform(.moveToBitwardenPressed(localItem))

        XCTAssertNil(authItemRepository.tempItem)
        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertNil(subject.state.url)
    }

    /// `perform(:_)` with `.search` updates search results in the state.
    @MainActor
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
    @MainActor
    func test_perform_search_emptyString() async {
        await subject.perform(.search("   "))
        XCTAssertEqual(subject.state.searchResults.count, 0)
        XCTAssertEqual(
            subject.state.searchResults,
            []
        )
    }

    /// `perform(.search)` throws error and error is logged.
    @MainActor
    func test_perform_search_error() async {
        authItemRepository.searchItemListSubject.send(completion: .failure(BitwardenTestError.example))
        await subject.perform(.search("example"))

        XCTAssertEqual(subject.state.searchResults.count, 0)
        XCTAssertEqual(
            subject.state.searchResults,
            []
        )
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `perform(.search)` handles TOTP Code expiration
    /// with updates the state's TOTP codes.
    @MainActor
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

        let secondItem = ItemListItem.fixtureShared(
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

    /// `perform(_:)` with `.streamItemList` starts streaming vault items. When there are no shared
    /// account items, does not show a toast.
    @MainActor
    func test_perform_streamItemList() {
        let totpCode = TOTPCodeModel(code: "654321",
                                     codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                                     period: 30)
        let results = [
            ItemListItem.fixture(totp: .fixture(totpCode: totpCode)),
        ]
        let resultSection = ItemListSection(id: "", items: results, name: "")

        authItemRepository.itemListSubject.send([resultSection])
        authItemRepository.refreshTotpCodesResult = .success(results)

        let task = Task {
            await subject.perform(.streamItemList)
        }
        defer { task.cancel() }

        waitFor(subject.state.loadingState != .loading(nil))

        XCTAssertEqual(authItemRepository.refreshedTotpCodes, results)
        XCTAssertEqual(subject.state.loadingState, .data([resultSection]))
        XCTAssertNil(subject.state.toast)
    }

    /// `perform(_:)` with `.streamItemList` starts streaming vault items. Item List is sorted by name
    @MainActor
    func test_perform_streamItemList_sorted() {
        let results = [
            ItemListItem.fixture(name: "Gamma"),
            ItemListItem.fixture(name: "Beta"),
            ItemListItem.fixture(name: "Delta"),
            ItemListItem.fixture(name: "Alpha"),
            ItemListItem.fixture(name: "beta"),
            ItemListItem.fixtureShared(name: "", accountName: nil),
            ItemListItem.fixture(name: "", accountName: "delta"),
        ]
        let resultsSorted = [
            results[5], // name and account name blank
            results[3], // Alpha
            results[4], // beta
            results[1], // Beta
            results[6], // delta (account name, name is blank)
            results[2], // Delta
            results[0], // Gamma
        ]
        let resultSection = ItemListSection(id: "", items: results, name: "")
        let sortedSection = ItemListSection(id: "", items: resultsSorted, name: "")

        authItemRepository.itemListSubject.send([resultSection])
        authItemRepository.refreshTotpCodesResult = .success(results)

        let task = Task {
            await subject.perform(.streamItemList)
        }
        defer { task.cancel() }

        waitFor(subject.state.loadingState != .loading(nil))

        XCTAssertEqual(authItemRepository.refreshedTotpCodes, results)
        XCTAssertEqual(subject.state.loadingState, .data([sortedSection]))
    }

    /// `perform(_:)` with `.streamItemList` starts streaming vault items. When there are shared items
    /// from an account the user has not synced with previously, it should show a toast stating that the account
    /// was synced.
    ///
    @MainActor
    func test_perform_streamItemList_withAccountSyncToast() {
        let accountName = "test@example.com | vault.example.com"
        let totpCode = TOTPCodeModel(code: "654321",
                                     codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                                     period: 30)
        let results = [
            ItemListItem.fixtureShared(totp: .fixture(totpCode: totpCode)),
        ]
        let resultSection = ItemListSection(id: accountName, items: results, name: accountName)

        authItemRepository.itemListSubject.send([resultSection])
        authItemRepository.refreshTotpCodesResult = .success(results)

        let task = Task {
            await subject.perform(.streamItemList)
        }
        defer { task.cancel() }

        waitFor(subject.state.loadingState != .loading(nil))

        XCTAssertEqual(authItemRepository.refreshedTotpCodes, results)
        XCTAssertEqual(subject.state.loadingState, .data([resultSection]))
        XCTAssertEqual(subject.state.toast?.text, Localizations.accountsSyncedFromBitwardenApp)
        XCTAssertTrue(appSettingsStore.hasSyncedAccount(name: accountName))
    }

    /// `perform(_:)` with `.streamItemList` starts streaming vault items. When there are shared items
    /// from an account the user *has* synced with previously, it should *not* show a toast.
    ///
    @MainActor
    func test_perform_streamItemList_withPreviouslySyncedAccount() {
        let accountName = "test@example.com | vault.example.com"
        let totpCode = TOTPCodeModel(code: "654321",
                                     codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                                     period: 30)
        let results = [
            ItemListItem.fixtureShared(totp: .fixture(totpCode: totpCode)),
        ]
        let resultSection = ItemListSection(id: accountName, items: results, name: accountName)

        appSettingsStore.setHasSyncedAccount(name: accountName)
        authItemRepository.itemListSubject.send([resultSection])
        authItemRepository.refreshTotpCodesResult = .success(results)

        let task = Task {
            await subject.perform(.streamItemList)
        }
        defer { task.cancel() }

        waitFor(subject.state.loadingState != .loading(nil))

        XCTAssertEqual(authItemRepository.refreshedTotpCodes, results)
        XCTAssertEqual(subject.state.loadingState, .data([resultSection]))
        XCTAssertNil(subject.state.toast)
    }

    /// `perform(_:)` with `.streamItemList` sets `showMoveToBitwarden` to `false`
    /// when the user has not yet turned sync on for at least one account.
    @MainActor
    func test_perform_streamItemList_showMoveToBitwarden_false() {
        authItemRepository.pmSyncEnabled = false
        let totpCode = TOTPCodeModel(code: "654321",
                                     codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                                     period: 30)
        let results = [
            ItemListItem.fixture(totp: .fixture(totpCode: totpCode)),
            ItemListItem.fixtureShared(totp: .fixture(totpCode: totpCode)),
        ]
        let resultSection = ItemListSection(id: "", items: results, name: "Items")

        authItemRepository.itemListSubject.send([resultSection])
        authItemRepository.refreshTotpCodesResult = .success(results)

        let task = Task {
            await subject.perform(.streamItemList)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        XCTAssertFalse(subject.state.showMoveToBitwarden)
    }

    /// `perform(_:)` with `.streamItemList` sets `showMoveToBitwarden` to `true` when
    /// and the user has turned sync on for at least one account.
    @MainActor
    func test_perform_appeared_showMoveToBitwarden_true() {
        authItemRepository.pmSyncEnabled = true
        let totpCode = TOTPCodeModel(code: "654321",
                                     codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                                     period: 30)
        let results = [
            ItemListItem.fixture(totp: .fixture(totpCode: totpCode)),
            ItemListItem.fixtureShared(totp: .fixture(totpCode: totpCode)),
        ]
        let resultSection = ItemListSection(id: "", items: results, name: "Items")

        authItemRepository.itemListSubject.send([resultSection])
        authItemRepository.refreshTotpCodesResult = .success(results)

        let task = Task {
            await subject.perform(.streamItemList)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        XCTAssertTrue(subject.state.showMoveToBitwarden)
    }

    /// `.receive` with `.clearURL` sets the `state.url` to `nil`.
    @MainActor
    func test_receive_clearURL() throws {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `setupForegroundNotification()` is called as part of `init()` and subscribes to any
    ///  foreground notification, performing `.refresh` when it receives a notification.
    @MainActor
    func test_setupForegroundNotification() async throws {
        let item = ItemListItem.fixture()
        let resultSection = ItemListSection(id: "", items: [item], name: "Items")
        authItemRepository.itemListSubject.send([resultSection])
        authItemRepository.refreshTotpCodesResult = .success([item])

        application.canOpenUrlResponse = false

        notificationCenterService.willEnterForegroundSubject.send()

        try await waitForAsync { self.subject.state.loadingState != .loading(nil) }
        XCTAssertEqual(subject.state.loadingState, .data([resultSection]))
        XCTAssertEqual(subject.state.itemListCardState, .passwordManagerDownload)
    }

    // MARK: AuthenticatorKeyCaptureDelegate Tests

    /// `didCompleteAutomaticCapture` failure when the user has opted to save locally by default.
    @MainActor
    func test_didCompleteAutomaticCapture_failure() {
        appSettingsStore.hasSeenDefaultSaveOptionPrompt = true
        appSettingsStore.defaultSaveOption = .saveHere
        totpService.getTOTPConfigResult = .failure(TOTPServiceError.invalidKeyFormat)
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: "1234")
        waitFor(captureCoordinator.routes.last != nil)
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

    /// `didCompleteAutomaticCapture` success when the user has opted to be asked by default and
    /// chooses the save locally option.
    @MainActor
    func test_didCompleteAutomaticCapture_hasSeenPrompt_noneLocalSaveChosen() async throws {
        authItemRepository.pmSyncEnabled = true
        application.canOpenUrlResponse = true
        appSettingsStore.hasSeenDefaultSaveOptionPrompt = true
        appSettingsStore.defaultSaveOption = .none
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: key)
        try await waitForAsync { !self.coordinator.alertShown.isEmpty }

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(alert.alertActions.count, 2)
        let saveLocallyOption = try XCTUnwrap(alert.alertActions.first)
        XCTAssertEqual(saveLocallyOption.title, Localizations.saveHere)
        await saveLocallyOption.handler?(saveLocallyOption, [])

        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()

        try await waitForAsync { !self.authItemRepository.addAuthItemAuthItems.isEmpty }
        try await waitForAsync { self.subject.state.loadingState != .loading(nil) }
        let item = try XCTUnwrap(authItemRepository.addAuthItemAuthItems.first)
        XCTAssertEqual(item.name, "")
        XCTAssertEqual(item.totpKey, String.base32Key)
    }

    /// `didCompleteAutomaticCapture` success when the user has opted to be asked by default and
    /// chooses the save locally option.
    @MainActor
    func test_didCompleteAutomaticCapture_hasSeenPrompt_noneSaveToBitwardenChosen() async throws {
        authItemRepository.pmSyncEnabled = true
        application.canOpenUrlResponse = true
        appSettingsStore.hasSeenDefaultSaveOptionPrompt = true
        appSettingsStore.defaultSaveOption = .none
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: key)
        try await waitForAsync { !self.coordinator.alertShown.isEmpty }

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(alert.alertActions.count, 2)
        let saveLocallyOption = try XCTUnwrap(alert.alertActions[1])
        XCTAssertEqual(saveLocallyOption.title, Localizations.saveToBitwarden)
        await saveLocallyOption.handler?(saveLocallyOption, [])

        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()

        try await waitForAsync { self.authItemRepository.tempItem != nil }
        let item = try XCTUnwrap(authItemRepository.tempItem)
        XCTAssertEqual(item.name, "")
        XCTAssertEqual(item.totpKey, String.base32Key)

        try await waitForAsync { self.subject.state.url != nil }
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.passwordManagerNewItem)
    }

    /// `didCompleteAutomaticCapture` success when the user has opted to save locally by default.
    @MainActor
    func test_didCompleteAutomaticCapture_hasSeenPrompt_saveLocally() async throws {
        appSettingsStore.hasSeenDefaultSaveOptionPrompt = true
        appSettingsStore.defaultSaveOption = .saveHere
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: key)
        try await waitForAsync { captureCoordinator.routes.last != nil }
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        try await waitForAsync { !self.authItemRepository.addAuthItemAuthItems.isEmpty }
        try await waitForAsync { self.subject.state.loadingState != .loading(nil) }
        let item = try XCTUnwrap(authItemRepository.addAuthItemAuthItems.first)
        XCTAssertEqual(item.name, "")
        XCTAssertEqual(item.totpKey, String.base32Key)
    }

    /// `didCompleteAutomaticCapture` success when the user has opted to save to Bitwarden by default.
    @MainActor
    func test_didCompleteAutomaticCapture_hasSeenPrompt_saveToBitwarden() async throws {
        authItemRepository.pmSyncEnabled = true
        application.canOpenUrlResponse = true
        appSettingsStore.hasSeenDefaultSaveOptionPrompt = true
        appSettingsStore.defaultSaveOption = .saveToBitwarden
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: key)
        try await waitForAsync { captureCoordinator.routes.last != nil }
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        try await waitForAsync { self.authItemRepository.tempItem != nil }
        try await waitForAsync { self.subject.state.url != nil }
        let item = try XCTUnwrap(authItemRepository.tempItem)
        XCTAssertEqual(item.name, "")
        XCTAssertEqual(item.totpKey, String.base32Key)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.passwordManagerNewItem)
    }

    /// `didCompleteAutomaticCapture` success when the user has no default save option set, chooses
    /// to save locally and choose to not set that as their default.
    @MainActor
    func test_didCompleteAutomaticCapture_noDefault_saveLocally_noToDefault() async throws {
        authItemRepository.pmSyncEnabled = true
        appSettingsStore.hasSeenDefaultSaveOptionPrompt = false
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: key)
        try await waitForAsync { !self.coordinator.alertShown.isEmpty }

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(alert.alertActions.count, 2)
        let saveLocallyOption = try XCTUnwrap(alert.alertActions.first)
        XCTAssertEqual(saveLocallyOption.title, Localizations.saveHere)
        await saveLocallyOption.handler?(saveLocallyOption, [])

        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()

        try await waitForAsync { self.coordinator.alertShown.count > 1 }

        let secondAlert = try XCTUnwrap(coordinator.alertShown[1])
        XCTAssertEqual(secondAlert.alertActions.count, 2)
        let noOption = try XCTUnwrap(secondAlert.alertActions[1])
        XCTAssertEqual(noOption.title, Localizations.noAskMe)
        Task {
            await noOption.handler?(noOption, [])
        }

        try await waitForAsync { !self.authItemRepository.addAuthItemAuthItems.isEmpty }
        try await waitForAsync { self.subject.state.loadingState != .loading(nil) }
        let item = try XCTUnwrap(authItemRepository.addAuthItemAuthItems.first)
        XCTAssertEqual(item.name, "")
        XCTAssertEqual(item.totpKey, String.base32Key)
        XCTAssertEqual(appSettingsStore.defaultSaveOption, .none)
    }

    /// `didCompleteAutomaticCapture` success when the user has no default save option set, chooses
    /// to save locally and choose to set that as their default.
    @MainActor
    func test_didCompleteAutomaticCapture_noDefault_saveLocally_yesToDefault() async throws {
        authItemRepository.pmSyncEnabled = true
        appSettingsStore.hasSeenDefaultSaveOptionPrompt = false
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: key)
        try await waitForAsync { !self.coordinator.alertShown.isEmpty }

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(alert.alertActions.count, 2)
        let saveLocallyOption = try XCTUnwrap(alert.alertActions.first)
        XCTAssertEqual(saveLocallyOption.title, Localizations.saveHere)
        await saveLocallyOption.handler?(saveLocallyOption, [])

        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()

        try await waitForAsync { self.coordinator.alertShown.count > 1 }

        let secondAlert = try XCTUnwrap(coordinator.alertShown[1])
        XCTAssertEqual(secondAlert.alertActions.count, 2)
        let yesOption = try XCTUnwrap(secondAlert.alertActions.first)
        XCTAssertEqual(yesOption.title, Localizations.yesSetDefault)
        Task {
            await yesOption.handler?(yesOption, [])
        }

        try await waitForAsync { !self.authItemRepository.addAuthItemAuthItems.isEmpty }
        try await waitForAsync { self.subject.state.loadingState != .loading(nil) }
        let item = try XCTUnwrap(authItemRepository.addAuthItemAuthItems.first)
        XCTAssertEqual(item.name, "")
        XCTAssertEqual(item.totpKey, String.base32Key)
        XCTAssertEqual(appSettingsStore.defaultSaveOption, .saveHere)
    }

    /// `didCompleteAutomaticCapture` success when the user has no default save option set, chooses
    /// to save to Bitwarden and choose to not set that as their default.
    @MainActor
    func test_didCompleteAutomaticCapture_noDefault_saveToBitwarden_noToDefault() async throws {
        authItemRepository.pmSyncEnabled = true
        application.canOpenUrlResponse = true
        appSettingsStore.hasSeenDefaultSaveOptionPrompt = false
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: key)
        try await waitForAsync { !self.coordinator.alertShown.isEmpty }

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(alert.alertActions.count, 2)
        let saveToBitwardenOption = try XCTUnwrap(alert.alertActions[1])
        XCTAssertEqual(saveToBitwardenOption.title, Localizations.saveToBitwarden)
        await saveToBitwardenOption.handler?(saveToBitwardenOption, [])

        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()

        try await waitForAsync { self.coordinator.alertShown.count > 1 }

        let secondAlert = try XCTUnwrap(coordinator.alertShown[1])
        XCTAssertEqual(secondAlert.alertActions.count, 2)
        let noOption = try XCTUnwrap(secondAlert.alertActions[1])
        XCTAssertEqual(noOption.title, Localizations.noAskMe)
        await noOption.handler?(noOption, [])

        try await waitForAsync { self.authItemRepository.tempItem != nil }
        try await waitForAsync { self.subject.state.url != nil }
        let item = try XCTUnwrap(authItemRepository.tempItem)
        XCTAssertEqual(item.name, "")
        XCTAssertEqual(item.totpKey, String.base32Key)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.passwordManagerNewItem)
        XCTAssertEqual(appSettingsStore.defaultSaveOption, .none)
    }

    /// `didCompleteAutomaticCapture` success when the user has no default save option set, chooses
    /// to save to Bitwarden and choose to set that as their default.
    @MainActor
    func test_didCompleteAutomaticCapture_noDefault_saveToBitwarden_yesToDefault() async throws {
        authItemRepository.pmSyncEnabled = true
        application.canOpenUrlResponse = true
        appSettingsStore.hasSeenDefaultSaveOptionPrompt = false
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: key)
        try await waitForAsync { !self.coordinator.alertShown.isEmpty }

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(alert.alertActions.count, 2)
        let saveLocallyOption = try XCTUnwrap(alert.alertActions[1])
        XCTAssertEqual(saveLocallyOption.title, Localizations.saveToBitwarden)
        await saveLocallyOption.handler?(saveLocallyOption, [])

        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()

        try await waitForAsync { self.coordinator.alertShown.count > 1 }

        let secondAlert = try XCTUnwrap(coordinator.alertShown[1])
        XCTAssertEqual(secondAlert.alertActions.count, 2)
        let yesOption = try XCTUnwrap(secondAlert.alertActions.first)
        XCTAssertEqual(yesOption.title, Localizations.yesSetDefault)
        await yesOption.handler?(yesOption, [])

        try await waitForAsync { self.authItemRepository.tempItem != nil }
        try await waitForAsync { self.subject.state.url != nil }
        let item = try XCTUnwrap(authItemRepository.tempItem)
        XCTAssertEqual(item.name, "")
        XCTAssertEqual(item.totpKey, String.base32Key)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.passwordManagerNewItem)
        XCTAssertEqual(appSettingsStore.defaultSaveOption, .saveToBitwarden)
    }

    /// `didCompleteAutomaticCapture` should not show any prompts or look at the defaults when the sync
    /// is not active (the user hasn't yet turned sync on). It should revert to the
    /// pre-existing behavior and save the code locally.
    @MainActor
    func test_didCompleteAutomaticCapture_syncNotActive() async throws {
        authItemRepository.pmSyncEnabled = false
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: key)
        try await waitForAsync { captureCoordinator.routes.last != nil }
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        try await waitForAsync { !self.authItemRepository.addAuthItemAuthItems.isEmpty }
        try await waitForAsync { self.subject.state.loadingState != .loading(nil) }
        let item = try XCTUnwrap(authItemRepository.addAuthItemAuthItems.first)
        XCTAssertEqual(item.name, "")
        XCTAssertEqual(item.totpKey, String.base32Key)
    }

    /// `didCompleteManualCapture` failure
    @MainActor
    func test_didCompleteManualCapture_failure() {
        totpService.getTOTPConfigResult = .failure(TOTPServiceError.invalidKeyFormat)
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteManualCapture(captureCoordinator.asAnyCoordinator(),
                                         key: "1234",
                                         name: "name",
                                         sendToBitwarden: false)
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

    /// `didCompleteManualCapture` success with a locally saved item
    @MainActor
    func test_didCompleteManualCapture_localSuccess() throws {
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteManualCapture(captureCoordinator.asAnyCoordinator(),
                                         key: key,
                                         name: "name",
                                         sendToBitwarden: false)
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        waitFor(!authItemRepository.addAuthItemAuthItems.isEmpty)
        waitFor(subject.state.loadingState != .loading(nil))
        let item = try XCTUnwrap(authItemRepository.addAuthItemAuthItems.first)
        XCTAssertEqual(item.name, "name")
        XCTAssertEqual(item.totpKey, String.base32Key)
    }

    /// `didCompleteManualCapture` success with `sendToBitwarden` item
    @MainActor
    func test_didCompleteManualCapture_sendToBitwardenSuccess() throws {
        authItemRepository.pmSyncEnabled = true
        application.canOpenUrlResponse = true
        let key = String.otpAuthUriKeyComplete
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        let expected = AuthenticatorItemView.fixture(name: "name", totpKey: key)
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteManualCapture(captureCoordinator.asAnyCoordinator(),
                                         key: key,
                                         name: "name",
                                         sendToBitwarden: true)
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()

        waitFor(authItemRepository.tempItem != nil)
        waitFor(subject.state.url != nil)
        XCTAssertEqual(authItemRepository.tempItem?.totpKey, expected.totpKey)
        XCTAssertEqual(authItemRepository.tempItem?.name, expected.name)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.passwordManagerNewItem)
    }

    /// Tests that the `itemListCardState` is set to `none` if the download card has been closed.
    @MainActor
    func test_determineItemListCardState_closed_download() async {
        application.canOpenUrlResponse = false
        await subject.perform(.closeCard(.passwordManagerDownload))
        XCTAssertEqual(subject.state.itemListCardState, .none)
    }

    /// Tests that the `itemListCardState` is set to `none` if the sync card has been closed.
    @MainActor
    func test_determineItemListCardState_closed_sync() async {
        application.canOpenUrlResponse = true
        await subject.perform(.closeCard(.passwordManagerSync))
        XCTAssertEqual(subject.state.itemListCardState, .none)
    }

    /// Tests that the `itemListCardState` is set to `passwordManagerDownload` if PM is not installed.
    @MainActor
    func test_determineItemListCardState_PM_notInstalled() {
        application.canOpenUrlResponse = false
        let task = Task {
            await self.subject.perform(.appeared)
        }

        waitFor(subject.state.itemListCardState == .passwordManagerDownload)
        task.cancel()
    }

    /// Tests that the `itemListCardState` is set to `passwordManagerSync` if PM is installed.
    @MainActor
    func test_determineItemListCardState_PM_installed() {
        application.canOpenUrlResponse = true
        let task = Task {
            await self.subject.perform(.appeared)
        }

        waitFor(subject.state.itemListCardState == .passwordManagerSync)
        task.cancel()
    }

    /// Tests that the `itemListCardState` is set to `none` if the user has already enabled sync in the BWPM app
    /// (when the BWPM app is not installed).
    @MainActor
    func test_determineItemListCardState_syncAlreadyOn_download() {
        authItemRepository.pmSyncEnabled = true
        application.canOpenUrlResponse = false
        let task = Task {
            await self.subject.perform(.appeared)
        }
        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        XCTAssertEqual(subject.state.itemListCardState, .none)
    }

    /// Tests that the `itemListCardState` is set to `none` if the user has already enabled sync in the BWPM app
    /// (when the BWPM app is installed).
    @MainActor
    func test_determineItemListCardState_syncAlreadyOn_sync() {
        authItemRepository.pmSyncEnabled = true
        application.canOpenUrlResponse = true
        let task = Task {
            await self.subject.perform(.appeared)
        }
        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        XCTAssertEqual(subject.state.itemListCardState, .none)
    }
}
