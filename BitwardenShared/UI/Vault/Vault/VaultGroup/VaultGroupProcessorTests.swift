import BitwardenSdk
import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared

// MARK: - VaultGroupProcessorTests

class VaultGroupProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var coordinator: MockCoordinator<VaultRoute>!
    var errorReporter: MockErrorReporter!
    let fixedDate = Date(year: 2023, month: 12, day: 31, minute: 0, second: 33)
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var subject: VaultGroupProcessor!
    var timeProvider: MockTimeProvider!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(fixedDate))
        vaultRepository = MockVaultRepository()
        vaultRepository.timeProvider = timeProvider

        subject = VaultGroupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                stateService: stateService,
                vaultRepository: vaultRepository
            ),
            state: VaultGroupState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        stateService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `itemDeleted()` delegate method shows the expected toast.
    func test_delegate_itemDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemDeleted()
        XCTAssertEqual(subject.state.toast?.text, Localizations.itemSoftDeleted)
    }

    /// `perform(_:)` with `.appeared` starts streaming vault items.
    func test_perform_appeared() {
        let vaultListItem = VaultListItem.fixture()
        vaultRepository.vaultListGroupSubject.send([
            vaultListItem,
        ])

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading)
        task.cancel()

        XCTAssertEqual(subject.state.loadingState, .data([vaultListItem]))
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.refreshed` requests a fetch sync update with the vault repository.
    func test_perform_refreshed() async {
        await subject.perform(.refresh)
        XCTAssertTrue(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.refreshed` records an error if applicable.
    func test_perform_refreshed_error() async {
        vaultRepository.fetchSyncResult = .failure(BitwardenTestError.example)

        await subject.perform(.refresh)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.streamShowWebIcons` requests the value of the show
    /// web icons parameter from the state service.
    func test_perform_streamShowWebIcons() {
        let task = Task {
            await subject.perform(.streamShowWebIcons)
        }

        stateService.showWebIconsSubject.send(false)
        waitFor(subject.state.showWebIcons == false)

        task.cancel()
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route with the correct group.
    func test_receive_addItemPressed() {
        subject.state.group = .card
        subject.receive(.addItemPressed)
        XCTAssertEqual(coordinator.routes.last, .addItem(group: .card))
    }

    /// `receive(_:)` with `.clearURL` clears the url in the state.
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `receive` with `.copyTOTPCode` copies the value with the pasteboard service.
    func test_receive_copyTOTPCode() {
        subject.receive(.copyTOTPCode("123456"))
        XCTAssertEqual(pasteboardService.copiedString, "123456")
        XCTAssertEqual(subject.state.toast?.text, Localizations.valueHasBeenCopied(Localizations.verificationCode))
    }

    /// `receive(_:)` with `.itemPressed` on a cipher navigates to the `.viewItem` route.
    func test_receive_itemPressed_cipher() {
        subject.receive(.itemPressed(.fixture(cipherView: .fixture(id: "id"))))
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: "id"))
    }

    /// `receive(_:)` with `.itemPressed` on a group navigates to the `.group` route.
    func test_receive_itemPressed_group() {
        subject.receive(.itemPressed(VaultListItem(id: "1", itemType: .group(.card, 2))))
        XCTAssertEqual(coordinator.routes.last, .group(.card))
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.viewItem` route.
    func test_receive_itemPressed_totp() {
        let totpItem = VaultListItem.fixtureTOTP(totp: .fixture())
        subject.receive(.itemPressed(totpItem))
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: totpItem.id))
    }

    /// `receive(_:)` with `.morePressed` shows the appropriate more options alert for a card cipher.
    func test_receive_morePressed_card() async throws {
        var item = try XCTUnwrap(VaultListItem(cipherView: .fixture(type: .card)))

        // If the card item has no number or code, only the view and add buttons should display.
        vaultRepository.fetchCipherResult = .success(.cardFixture())
        subject.receive(.morePressed(item))
        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        // If the item is in the trash, the edit option should not display.
        subject.state.group = .trash
        subject.receive(.morePressed(item))
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        // A card with data should show the copy actions.
        let cardWithData = CipherView.cardFixture(card: .fixture(
            code: "123",
            number: "123456789"
        ))
        item = try XCTUnwrap(VaultListItem(cipherView: cardWithData))
        subject.state.group = .card
        subject.receive(.morePressed(item))
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 5)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.copyNumber)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.copySecurityCode)
        XCTAssertEqual(alert.alertActions[4].title, Localizations.cancel)

        // Test the functionality of the buttons.

        // View navigates to the view item view.
        let viewAction = try XCTUnwrap(alert.alertActions[0])
        await viewAction.handler?(viewAction, [])
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id))

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(cardWithData))

        // Copy number copies the card's number.
        let copyNumberAction = try XCTUnwrap(alert.alertActions[2])
        await copyNumberAction.handler?(copyNumberAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "123456789")

        // Copy security code copies the card's security code.
        let copyCodeAction = try XCTUnwrap(alert.alertActions[3])
        await copyCodeAction.handler?(copyCodeAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "123")
    }

    /// `receive(_:)` with `.morePressed` shows the appropriate more options alert for a login cipher.
    func test_receive_morePressed_login() async throws {
        var item = try XCTUnwrap(VaultListItem(cipherView: .fixture(type: .login)))

        // If the login item has no username, password, or url, only the view and add buttons should display.
        vaultRepository.fetchCipherResult = .success(.loginFixture())
        subject.receive(.morePressed(item))
        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        // If the item is in the trash, the edit option should not display.
        subject.state.group = .trash
        subject.receive(.morePressed(item))
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        // A login with data should show the copy and launch actions.
        let loginWithData = CipherView.loginFixture(login: .fixture(
            password: "password",
            uris: [.init(uri: URL.example.relativeString, match: nil)],
            username: "username"
        ))
        item = try XCTUnwrap(VaultListItem(cipherView: loginWithData))
        subject.state.group = .login
        subject.receive(.morePressed(item))
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 6)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.copyUsername)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.copyPassword)
        XCTAssertEqual(alert.alertActions[4].title, Localizations.launch)
        XCTAssertEqual(alert.alertActions[5].title, Localizations.cancel)

        // Test the functionality of the buttons.

        // View navigates to the view item view.
        let viewAction = try XCTUnwrap(alert.alertActions[0])
        await viewAction.handler?(viewAction, [])
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id))

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(loginWithData))

        // Copy username copies the username.
        let copyUsernameAction = try XCTUnwrap(alert.alertActions[2])
        await copyUsernameAction.handler?(copyUsernameAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "username")

        // Copy password copies the user's username.
        let copyPasswordAction = try XCTUnwrap(alert.alertActions[3])
        await copyPasswordAction.handler?(copyPasswordAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "password")

        // Launch action set's the url to open.
        let launchAction = try XCTUnwrap(alert.alertActions[4])
        await launchAction.handler?(launchAction, [])
        XCTAssertEqual(subject.state.url, .example)
    }

    /// `receive(_:)` with `.morePressed` shows the appropriate more options alert for an identity cipher.
    func test_receive_morePressed_identity() async throws {
        let item = try XCTUnwrap(VaultListItem(cipherView: .fixture(type: .identity)))

        // If the item is in the trash, the edit option should not display.
        vaultRepository.fetchCipherResult = .success(.fixture())
        subject.state.group = .trash
        subject.receive(.morePressed(item))
        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        // An identity option can be viewed or edited.
        subject.state.group = .identity
        subject.receive(.morePressed(item))
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        // Test the functionality of the buttons.

        // View navigates to the view item view.
        let viewAction = try XCTUnwrap(alert.alertActions[0])
        await viewAction.handler?(viewAction, [])
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id))

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(.fixture(type: .identity)))
    }

    /// `receive(_:)` with `.morePressed` shows the appropriate more options alert for a secure note cipher.
    func test_receive_morePressed_secureNote() async throws {
        var item = try XCTUnwrap(VaultListItem(cipherView: .fixture(type: .secureNote)))

        // If the secure note has no value, only the view and add buttons should display.
        vaultRepository.fetchCipherResult = .success(.fixture(type: .secureNote))
        subject.receive(.morePressed(item))
        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        // If the item is in the trash, the edit option should not display.
        subject.state.group = .trash
        subject.receive(.morePressed(item))
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        // A note with data should show the copy action.
        let noteWithData = CipherView.fixture(notes: "Test Note", type: .secureNote)
        item = try XCTUnwrap(VaultListItem(cipherView: noteWithData))
        subject.state.group = .secureNote
        subject.receive(.morePressed(item))
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 4)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.copyNotes)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.cancel)

        // Test the functionality of the buttons.

        // View navigates to the view item view.
        let viewAction = try XCTUnwrap(alert.alertActions[0])
        await viewAction.handler?(viewAction, [])
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id))

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(noteWithData))

        // Copy copies the items notes.
        let copyNoteAction = try XCTUnwrap(alert.alertActions[2])
        await copyNoteAction.handler?(copyNoteAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "Test Note")
    }

    /// `receive(_:)` with `.searchTextChanged` and no value sets the state correctly.
    func test_receive_searchTextChanged_withoutValue() {
        subject.state.searchText = "search"
        subject.receive(.searchTextChanged(""))
        XCTAssertEqual(subject.state.searchText, "")
    }

    /// `receive(_:)` with `.searchTextChanged` and a value sets the state correctly.
    func test_receive_searchTextChanged_withValue() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("search"))
        XCTAssertEqual(subject.state.searchText, "search")
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// TOTP Code expiration updates the state's TOTP codes.
    func test_receive_appeared_totpExpired_single() throws {
        let result = VaultListItem.fixtureTOTP(
            totp: .fixture(
                totpCode: .init(
                    code: "",
                    codeGenerationDate: .init(year: 2023, month: 12, day: 31),
                    period: 30
                )
            )
        )
        let newResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                totpCode: .init(
                    code: "345678",
                    codeGenerationDate: Date(),
                    period: 30
                )
            )
        )
        vaultRepository.refreshTOTPCodesResult = .success([
            newResult,
        ])
        let task = Task {
            await subject.perform(.appeared)
        }
        vaultRepository.vaultListGroupSubject.send([result])
        waitFor(!vaultRepository.refreshedTOTPCodes.isEmpty)
        waitFor(subject.state.loadingState.data == [newResult])
        task.cancel()
        XCTAssertEqual([result], vaultRepository.refreshedTOTPCodes)
        let first = try XCTUnwrap(subject.state.loadingState.data?.first)
        XCTAssertEqual(first, newResult)
    }

    /// TOTP Code expiration updates the state's TOTP codes.
    func test_receive_appeared_totpExpired_multi() throws { // swiftlint:disable:this function_body_length
        subject = VaultGroupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                timeProvider: timeProvider,
                vaultRepository: vaultRepository
            ),
            state: VaultGroupState()
        )
        let olderThanIntervalResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "olderThanIntervalResult",
                totpCode: .init(
                    code: "olderThanIntervalResult",
                    codeGenerationDate: fixedDate.addingTimeInterval(-31.0),
                    period: 30
                )
            )
        )
        let shortExpirationResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "shortExpirationResult",
                totpCode: .init(
                    code: "shortExpirationResult",
                    codeGenerationDate: Date(year: 2023, month: 12, day: 31, minute: 0, second: 24),
                    period: 30
                )
            )
        )
        let veryOldResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "veryOldResult",
                totpCode: .init(
                    code: "veryOldResult",
                    codeGenerationDate: fixedDate.addingTimeInterval(-40.0),
                    period: 30
                )
            )
        )
        let expectedUpdate1 = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "olderThanIntervalResult",
                totpCode: .init(
                    code: "olderThanIntervalResult",
                    codeGenerationDate: fixedDate,
                    period: 30
                )
            )
        )
        let expectedUpdate2 = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "shortExpirationResult",
                totpCode: .init(
                    code: "shortExpirationResult",
                    codeGenerationDate: fixedDate,
                    period: 30
                )
            )
        )
        let expectedUpdate3 = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "veryOldResult",
                totpCode: .init(
                    code: "veryOldResult",
                    codeGenerationDate: fixedDate,
                    period: 30
                )
            )
        )
        let newResults: [VaultListItem] = [
            expectedUpdate1,
            expectedUpdate2,
            expectedUpdate3,
            .fixtureTOTP(
                totp: .fixture(
                    id: "New Result",
                    totpCode: .init(
                        code: "New Result",
                        codeGenerationDate: fixedDate,
                        period: 30
                    )
                )
            ),
        ]
        vaultRepository.refreshTOTPCodesResult = .success(newResults)
        let task = Task {
            await subject.perform(.appeared)
        }
        let stableResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "stableResult",
                totpCode: .init(
                    code: "stableResult",
                    codeGenerationDate: fixedDate.addingTimeInterval(2.0),
                    period: 30
                )
            )
        )
        vaultRepository.vaultListGroupSubject.send([
            olderThanIntervalResult,
            shortExpirationResult,
            veryOldResult,
            stableResult,
        ])
        waitFor(!vaultRepository.refreshedTOTPCodes.isEmpty)
        task.cancel()

        XCTAssertEqual(fixedDate, vaultRepository.refreshedTOTPTime)
        XCTAssertEqual(
            [
                olderThanIntervalResult,
                shortExpirationResult,
                veryOldResult,
            ],
            vaultRepository.refreshedTOTPCodes
                .sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
        )
    }

    /// `receive(_:)` with `.totpCodeExpired` handles errors.
    func test_receive_totpExpired_error() throws {
        subject = VaultGroupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                vaultRepository: vaultRepository
            ),
            state: VaultGroupState()
        )
        struct TestError: Error, Equatable {}
        let result = VaultListItem.fixtureTOTP(
            totp: .fixture(
                totpCode: .init(
                    code: "",
                    codeGenerationDate: .distantPast,
                    period: 30
                )
            )
        )
        vaultRepository.refreshTOTPCodesResult = .failure(TestError())
        let task = Task {
            await subject.perform(.appeared)
        }
        vaultRepository.vaultListGroupSubject.send([result])
        waitFor(!vaultRepository.refreshedTOTPCodes.isEmpty)
        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()
        let first = try XCTUnwrap(errorReporter.errors.first as? TestError)
        XCTAssertEqual(first, TestError())
    }
}
