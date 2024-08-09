import BitwardenSdk
import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared

// MARK: - VaultGroupProcessorTests

class VaultGroupProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    let fixedDate = Date(year: 2023, month: 12, day: 31, minute: 0, second: 31)
    var pasteboardService: MockPasteboardService!
    var policyService: MockPolicyService!
    var stateService: MockStateService!
    var subject: VaultGroupProcessor!
    var timeProvider: MockTimeProvider!
    var vaultItemMoreOptionsHelper: MockVaultItemMoreOptionsHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        policyService = MockPolicyService()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(fixedDate))
        vaultItemMoreOptionsHelper = MockVaultItemMoreOptionsHelper()
        vaultRepository = MockVaultRepository()
        vaultRepository.timeProvider = timeProvider

        subject = VaultGroupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
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
            ),
            vaultItemMoreOptionsHelper: vaultItemMoreOptionsHelper
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        policyService = nil
        stateService = nil
        subject = nil
        timeProvider = nil
        vaultItemMoreOptionsHelper = nil
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
        let vaultListSection = VaultListSection(id: "", items: [vaultListItem], name: "Items")
        vaultRepository.vaultListGroupSubject.send([vaultListSection])

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        XCTAssertEqual(subject.state.loadingState, .data([vaultListSection]))
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

    /// `perform(_:)` with `.morePressed` has the vault item more options helper display the alert.
    func test_perform_morePressed() async throws {
        await subject.perform(.morePressed(.fixture()))

        XCTAssertTrue(vaultItemMoreOptionsHelper.showMoreOptionsAlertCalled)
        XCTAssertNotNil(vaultItemMoreOptionsHelper.showMoreOptionsAlertHandleDisplayToast)
        XCTAssertNotNil(vaultItemMoreOptionsHelper.showMoreOptionsAlertHandleOpenURL)

        let toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.password))
        vaultItemMoreOptionsHelper.showMoreOptionsAlertHandleDisplayToast?(toast)
        XCTAssertEqual(subject.state.toast, toast)

        let url = URL.example
        vaultItemMoreOptionsHelper.showMoreOptionsAlertHandleOpenURL?(url)
        XCTAssertEqual(subject.state.url, url)
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
                    requiresMasterPassword: false,
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
                    requiresMasterPassword: false,
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
                    requiresMasterPassword: false,
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
                    requiresMasterPassword: false,
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
                    requiresMasterPassword: false,
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
        let resultSection = VaultListSection(id: "", items: [result], name: "Items")
        let newResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                totpCode: .init(
                    code: "345678",
                    codeGenerationDate: Date(),
                    period: 30
                )
            )
        )
        let newResultSection = VaultListSection(id: "", items: [newResult], name: "Items")
        vaultRepository.refreshTOTPCodesResult = .success([newResult])
        let task = Task {
            await subject.perform(.appeared)
        }
        vaultRepository.vaultListGroupSubject.send([resultSection])
        waitFor(!vaultRepository.refreshedTOTPCodes.isEmpty)
        waitFor(subject.state.loadingState.data == [newResultSection])
        task.cancel()
        XCTAssertEqual([result], vaultRepository.refreshedTOTPCodes)
        let first = try XCTUnwrap(subject.state.loadingState.data?.first)
        XCTAssertEqual(first, newResultSection)
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
            ),
            vaultItemMoreOptionsHelper: vaultItemMoreOptionsHelper
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
        let vaultListSection = VaultListSection(
            id: "",
            items: [
                olderThanIntervalResult,
                shortExpirationResult,
                veryOldResult,
                stableResult,
            ],
            name: "Items"
        )
        vaultRepository.vaultListGroupSubject.send([vaultListSection])
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
        XCTAssertEqual(coordinator.routes.last, .group(.card, filter: .allVaults))
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.viewItem` route.
    func test_receive_itemPressed_totp() {
        let totpItem = VaultListItem.fixtureTOTP(totp: .fixture())
        subject.receive(.itemPressed(totpItem))
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: totpItem.id))
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
            ),
            vaultItemMoreOptionsHelper: vaultItemMoreOptionsHelper
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
        vaultRepository.vaultListGroupSubject.send([VaultListSection(id: "1", items: [result], name: "")])
        waitFor(!vaultRepository.refreshedTOTPCodes.isEmpty)
        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()
        let first = try XCTUnwrap(errorReporter.errors.first as? TestError)
        XCTAssertEqual(first, TestError())
    }
}
