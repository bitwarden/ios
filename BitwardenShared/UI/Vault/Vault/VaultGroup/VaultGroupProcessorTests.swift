import BitwardenSdk
import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared

// MARK: - VaultGroupProcessorTests

class VaultGroupProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var filterDelegate: MockVaultFilterDelegate!
    let fixedDate = Date(year: 2023, month: 12, day: 31, minute: 0, second: 31)
    var pasteboardService: MockPasteboardService!
    var policyService: MockPolicyService!
    var stateService: MockStateService!
    var subject: VaultGroupProcessor!
    var timeProvider: MockTimeProvider!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        filterDelegate = MockVaultFilterDelegate()
        pasteboardService = MockPasteboardService()
        policyService = MockPolicyService()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(fixedDate))
        vaultRepository = MockVaultRepository()
        vaultRepository.timeProvider = timeProvider

        subject = VaultGroupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                policyService: policyService,
                stateService: stateService,
                timeProvider: timeProvider,
                vaultRepository: vaultRepository
            ),
            state: VaultGroupState(
                searchVaultFilterType: .allVaults,
                vaultFilterType: .allVaults
            )
        )
        subject.vaultFilterDelegate = filterDelegate
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        filterDelegate = nil
        pasteboardService = nil
        policyService = nil
        stateService = nil
        subject = nil
        timeProvider = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `itemDeleted()` delegate method shows the expected toast.
    func test_delegate_itemDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemDeleted()
        XCTAssertEqual(subject.state.toast?.text, Localizations.itemDeleted)
    }

    /// `itemSoftDeleted()` delegate method shows the expected toast.
    func test_delegate_itemSoftDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemSoftDeleted()
        XCTAssertEqual(subject.state.toast?.text, Localizations.itemSoftDeleted)
    }

    /// `itemRestored()` delegate method shows the expected toast.
    func test_delegate_itemRestored() {
        XCTAssertNil(subject.state.toast)

        subject.itemRestored()
        XCTAssertEqual(subject.state.toast?.text, Localizations.itemRestored)
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

    /// `perform(_:)` with `.appeared` records any errors.
    func test_perform_appeared_error_vaultListGroupSubjectFail() {
        vaultRepository.vaultListGroupSubject.send(completion: .failure(BitwardenTestError.example))

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.appeared` updates the state depending on if the
    /// personal ownership policy is enabled.
    func test_perform_appeared_personalOwnershipPolicy() {
        policyService.policyAppliesToUserResult[.personalOwnership] = true

        let task = Task {
            await subject.perform(.appeared)
        }
        waitFor(subject.state.isPersonalOwnershipDisabled)
        task.cancel()

        XCTAssertTrue(subject.state.isPersonalOwnershipDisabled)
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

    /// `perform(.search)` with a keyword should update search results in state.
    func test_perform_search() async {
        let searchResult: [CipherView] = [.fixture(name: "example")]
        vaultRepository.searchVaultListSubject.value = searchResult.compactMap { VaultListItem(cipherView: $0) }
        subject.state.searchVaultFilterType = .organization(.fixture(id: "id1"))
        await subject.perform(.search("example"))
        XCTAssertEqual(subject.state.searchResults.count, 1)
        XCTAssertEqual(
            vaultRepository.searchVaultListFilterType,
            .organization(.fixture(id: "id1"))
        )
        XCTAssertEqual(
            subject.state.searchResults,
            try [VaultListItem.fixture(cipherView: XCTUnwrap(searchResult.first))]
        )
    }

    /// `perform(.search)` throws error and error is logged.
    func test_perform_search_error() async {
        vaultRepository.searchVaultListSubject.send(completion: .failure(BitwardenTestError.example))
        await subject.perform(.search("example"))

        XCTAssertEqual(subject.state.searchResults.count, 0)
        XCTAssertEqual(
            subject.state.searchResults,
            []
        )
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(.search)` with a keyword should update search results in state.
    func test_perform_search_expiredTOTP() { // swiftlint:disable:this function_body_length
        let loginView = LoginView.fixture(totp: .base32Key)
        let refreshed = VaultListItem(
            id: "1",
            itemType: .totp(
                name: "refreshed totp",
                totpModel: .init(
                    id: "1",
                    loginView: loginView,
                    totpCode: .init(
                        code: "654321",
                        codeGenerationDate: timeProvider.presentTime,
                        period: 30
                    )
                )
            )
        )
        vaultRepository.refreshTOTPCodesResult = .success(
            [
                refreshed,
            ]
        )
        let task = Task {
            await subject.perform(.search("example"))
        }
        let expired = VaultListItem(
            id: "1",
            itemType: .totp(
                name: "expiredTOTP",
                totpModel: .init(
                    id: "1",
                    loginView: loginView,
                    totpCode: .init(
                        code: "098765",
                        codeGenerationDate: timeProvider.presentTime
                            .addingTimeInterval(-1.5),
                        period: 30
                    )
                )
            )
        )
        let stable = VaultListItem(
            id: "2",
            itemType: .totp(
                name: "stableTOTP",
                totpModel: .init(
                    id: "1",
                    loginView: loginView,
                    totpCode: .init(
                        code: "111222",
                        codeGenerationDate: timeProvider.presentTime,
                        period: 30
                    )
                )
            )
        )
        vaultRepository.searchVaultListSubject.send([
            expired,
            stable,
        ])
        waitFor(subject.state.searchResults.count == 2)
        task.cancel()

        waitFor(!vaultRepository.refreshedTOTPCodes.isEmpty)
        XCTAssertEqual(
            vaultRepository.refreshedTOTPCodes,
            [expired]
        )
        let expectedRefresh = [
            refreshed,
            stable,
        ]
        waitFor(subject.state.searchResults == expectedRefresh)
    }

    /// `perform(.search)` with a keyword should update search results in state.
    func test_perform_search_expiredTOTP_error() { // swiftlint:disable:this function_body_length
        let loginView = LoginView.fixture(totp: .base32Key)
        vaultRepository.refreshTOTPCodesResult = .failure(BitwardenTestError.example)
        let task = Task {
            await subject.perform(.search("example"))
        }
        let expired = VaultListItem(
            id: "1",
            itemType: .totp(
                name: "expiredTOTP",
                totpModel: .init(
                    id: "1",
                    loginView: loginView,
                    totpCode: .init(
                        code: "098765",
                        codeGenerationDate: timeProvider.presentTime
                            .addingTimeInterval(-1.5),
                        period: 30
                    )
                )
            )
        )
        let stable = VaultListItem(
            id: "2",
            itemType: .totp(
                name: "stableTOTP",
                totpModel: .init(
                    id: "1",
                    loginView: loginView,
                    totpCode: .init(
                        code: "111222",
                        codeGenerationDate: timeProvider.presentTime,
                        period: 30
                    )
                )
            )
        )
        vaultRepository.searchVaultListSubject.send([
            expired,
            stable,
        ])
        waitFor(subject.state.searchResults.count == 2)
        task.cancel()

        waitFor(!vaultRepository.refreshedTOTPCodes.isEmpty)
        XCTAssertEqual(
            vaultRepository.refreshedTOTPCodes,
            [expired]
        )

        // Ensure that even after a delay, the searchResults are not refreshed,
        //  given the error.
        var didWait = false
        let delay = Task {
            try await Task.sleep(nanoseconds: (1 * NSEC_PER_SEC) / 4)
            didWait = true
        }
        waitFor(didWait)
        delay.cancel()

        XCTAssertEqual(
            subject.state.searchResults,
            [
                expired,
                stable,
            ]
        )
    }

    /// `perform(.search)` with a empty keyword should get empty search result.
    func test_perform_search_emptyString() async {
        await subject.perform(.search("   "))
        XCTAssertEqual(subject.state.searchResults.count, 0)
        XCTAssertEqual(
            subject.state.searchResults,
            []
        )
    }

    /// `perform(_:)` with `.streamOrganizations` updates the state's organizations whenever it changes.
    func test_perform_streamOrganizations() {
        let task = Task {
            await subject.perform(.streamOrganizations)
        }

        let organizations = [
            Organization.fixture(id: "1", name: "Organization1"),
            Organization.fixture(id: "2", name: "Organization2"),
        ]

        vaultRepository.organizationsSubject.value = organizations

        waitFor { !subject.state.organizations.isEmpty }
        task.cancel()

        XCTAssertEqual(subject.state.organizations, organizations)
    }

    /// `perform(_:)` with `.streamOrganizations` records any errors.
    func test_perform_streamOrganizations_error() {
        let task = Task {
            await subject.perform(.streamOrganizations)
        }

        vaultRepository.organizationsSubject.send(completion: .failure(BitwardenTestError.example))

        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()

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

    /// `perform(_:)` with `.streamVaultList` updates the state's vault list whenever it changes.
    func test_perform_streamVaultList() throws {
        let loginView = LoginView.fixture(totp: .base32Key)
        let vaultListItem = VaultListItem(
            id: "2",
            itemType: .totp(
                name: "totp",
                totpModel: .init(
                    id: "1",
                    loginView: loginView,
                    totpCode: .init(
                        code: "111222",
                        codeGenerationDate: timeProvider.presentTime,
                        period: 30
                    )
                )
            )
        )
        subject.state.group = .totp
        vaultRepository.vaultListGroupSubject.send([
            vaultListItem,
        ])

        let task = Task {
            await subject.perform(.streamVaultList)
        }

        waitFor(subject.state.loadingState != .loading)
        task.cancel()

        let items = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertEqual(items, [vaultListItem])
    }

    /// `perform(_:)` with `.streamVaultList` records any errors.
    func test_perform_streamVaultList_error() throws {
        vaultRepository.vaultListGroupSubject.send(completion: .failure(BitwardenTestError.example))

        let task = Task {
            await subject.perform(.streamVaultList)
        }

        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route with the correct group.
    func test_receive_addItemPressed() {
        subject.state.group = .card
        subject.receive(.addItemPressed)
        XCTAssertEqual(coordinator.routes.last, .addItem(group: .card))
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
            state: VaultGroupState(
                searchVaultFilterType: .allVaults,
                vaultFilterType: .allVaults
            )
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
        XCTAssertEqual(
            coordinator.routes.last,
            .group(
                .init(group: .card, filter: .allVaults)
            )
        )
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

    /// `receive(_:)` with `.morePressed` and press `copyPassword` presents master password re-prompt alert.
    func test_receive_morePressed_copyPassword_rePromptMasterPassword() async throws {
        // A login with data should show the copy and launch actions.
        let loginWithData = CipherView.loginFixture(
            login: .fixture(
                password: "secretPassword",
                uris: [.init(uri: URL.example.relativeString, match: nil)],
                username: "username"
            ),
            reprompt: .password
        )
        let item = try XCTUnwrap(VaultListItem(cipherView: loginWithData))
        subject.receive(.morePressed(item))
        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 6)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.copyPassword)

        // Test the functionality of the copy user name and password buttons.

        // Copy username copies the username.
        let copyUsernameAction = try XCTUnwrap(alert.alertActions[2])
        await copyUsernameAction.handler?(copyUsernameAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "username")

        // Copy password copies the user's password.
        let copyPasswordAction = try XCTUnwrap(alert.alertActions[3])
        await copyPasswordAction.handler?(copyPasswordAction, [])

        // mock the master password
        vaultRepository.validatePasswordResult = .success(true)

        // Validate master password re-prompt is shown
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .masterPasswordPrompt { _ in })
        var textField = try XCTUnwrap(alert.alertTextFields.first)
        textField = AlertTextField(id: "password", text: "password")
        let submitAction = try XCTUnwrap(alert.alertActions.first(where: { $0.title == Localizations.submit }))
        await submitAction.handler?(submitAction, [textField])

        XCTAssertEqual(pasteboardService.copiedString, "secretPassword")
    }

    /// `receive(_:)` with `.morePressed` and press `copyPassword` presents master password re-prompt alert,
    ///  entering wrong password should not allow to copy password.
    func test_receive_morePressed_copyPassword_passwordReprompt_invalidPassword() async throws {
        // A login with data should show the copy and launch actions.
        let loginWithData = CipherView.loginFixture(
            login: .fixture(
                password: "password",
                uris: [.init(uri: URL.example.relativeString, match: nil)],
                username: "username"
            ),
            reprompt: .password
        )
        let item = try XCTUnwrap(VaultListItem(cipherView: loginWithData))
        subject.receive(.morePressed(item))
        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 6)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.copyPassword)

        // Test the functionality of the copy user name and password buttons.

        // Copy username copies the username.
        let copyUsernameAction = try XCTUnwrap(alert.alertActions[2])
        await copyUsernameAction.handler?(copyUsernameAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "username")

        // Copy password copies the user's password.
        let copyPasswordAction = try XCTUnwrap(alert.alertActions[3])
        await copyPasswordAction.handler?(copyPasswordAction, [])

        // mock the master password
        vaultRepository.validatePasswordResult = .success(false)

        // Validate master password re-prompt is shown
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .masterPasswordPrompt { _ in })
        try await alert.tapAction(title: Localizations.submit)

        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .defaultAlert(title: Localizations.invalidMasterPassword))

        XCTAssertNotEqual(pasteboardService.copiedString, "secretPassword")
        XCTAssertEqual(pasteboardService.copiedString, "username")
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

    /// `receive(_:)` with `.searchStateChanged(isSearching: false)` hides the profile switcher
    func test_receive_searchTextChanged_false_clearsSearch() {
        subject.state.isSearching = true
        subject.state.searchText = "text"
        subject.state.searchResults = [
            .fixture(),
        ]
        subject.receive(.searchStateChanged(isSearching: false))

        XCTAssertTrue(subject.state.searchText.isEmpty)
        XCTAssertFalse(subject.state.isSearching)
        XCTAssertTrue(subject.state.searchResults.isEmpty)
    }

    /// `receive(_:)` with `.searchStateChanged(isSearching: true)` hides the profile switcher
    func test_receive_searchStateChanged_true_setsSearch() {
        subject.state.isSearching = false
        subject.receive(.searchStateChanged(isSearching: true))

        XCTAssertTrue(subject.state.isSearching)
    }

    /// `receive(_:)` with `.searchVaultFilterChanged` updates the state correctly.
    func test_receive_searchVaultFilterChanged() {
        let organization = Organization.fixture()

        subject.state.searchVaultFilterType = .myVault
        subject.receive(.searchVaultFilterChanged(.organization(organization)))

        XCTAssertEqual(subject.state.searchVaultFilterType, .organization(organization))
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
            state: VaultGroupState(
                searchVaultFilterType: .allVaults,
                vaultFilterType: .allVaults
            )
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

    /// `receive(_:)` with `.vaultFilterChanged` updates the state correctly.
    func test_receive_vaultFilterChanged() {
        let organization = Organization.fixture()

        subject.state.vaultFilterType = .myVault
        subject.receive(.vaultFilterChanged(.organization(organization)))

        XCTAssertEqual(subject.state.vaultFilterType, .organization(organization))
        XCTAssertEqual(filterDelegate.newFilter, .organization(organization))
    }

    /// `didSetVaultFilter(_:)` udpates the filters.
    func test_didSetVaultFilter() {
        subject.didSetVaultFilter(.myVault)
        XCTAssertEqual(subject.state.vaultFilterType, .myVault)
    }
}
