import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import InlineSnapshotTesting
import TestHelpers
import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - VaultGroupProcessorTests

class VaultGroupProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    let fixedDate = Date(year: 2023, month: 12, day: 31, minute: 0, second: 31)
    var masterPasswordRepromptHelper: MockMasterPasswordRepromptHelper!
    var pasteboardService: MockPasteboardService!
    var policyService: MockPolicyService!
    var searchProcessorMediator: MockSearchProcessorMediator!
    var searchProcessorMediatorFactory: MockSearchProcessorMediatorFactory!
    var stateService: MockStateService!
    var subject: VaultGroupProcessor!
    var timeProvider: MockTimeProvider!
    var vaultItemMoreOptionsHelper: MockVaultItemMoreOptionsHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        configService = MockConfigService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        masterPasswordRepromptHelper = MockMasterPasswordRepromptHelper()
        pasteboardService = MockPasteboardService()
        policyService = MockPolicyService()

        searchProcessorMediator = MockSearchProcessorMediator()
        searchProcessorMediatorFactory = MockSearchProcessorMediatorFactory()
        searchProcessorMediatorFactory.makeReturnValue = searchProcessorMediator

        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(fixedDate))
        vaultItemMoreOptionsHelper = MockVaultItemMoreOptionsHelper()
        vaultRepository = MockVaultRepository()
        vaultRepository.timeProvider = timeProvider

        subject = VaultGroupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            masterPasswordRepromptHelper: masterPasswordRepromptHelper,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                configService: configService,
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                policyService: policyService,
                searchProcessorMediatorFactory: searchProcessorMediatorFactory,
                stateService: stateService,
                timeProvider: timeProvider,
                vaultRepository: vaultRepository,
            ),
            state: VaultGroupState(
                searchVaultFilterType: .allVaults,
                vaultFilterType: .allVaults,
            ),
            vaultItemMoreOptionsHelper: vaultItemMoreOptionsHelper,
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        configService = nil
        coordinator = nil
        errorReporter = nil
        masterPasswordRepromptHelper = nil
        pasteboardService = nil
        policyService = nil
        searchProcessorMediator = nil
        searchProcessorMediatorFactory = nil
        stateService = nil
        subject = nil
        timeProvider = nil
        vaultItemMoreOptionsHelper = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `itemArchived()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_itemArchived() {
        XCTAssertNil(subject.state.toast)

        subject.itemArchived()
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.itemMovedToArchive))
        waitFor(vaultRepository.fetchSyncCalled)
    }

    /// `itemDeleted()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_itemDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemDeleted()
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.itemDeleted))
        waitFor(vaultRepository.fetchSyncCalled)
    }

    /// `itemSoftDeleted()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_itemSoftDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemSoftDeleted()
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.itemSoftDeleted))
        waitFor(vaultRepository.fetchSyncCalled)
    }

    /// `itemRestored()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_itemRestored() {
        XCTAssertNil(subject.state.toast)

        subject.itemRestored()
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.itemRestored))
        waitFor(vaultRepository.fetchSyncCalled)
    }

    /// `itemUnarchived()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_itemUnarchived() {
        XCTAssertNil(subject.state.toast)

        subject.itemUnarchived()
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.itemMovedToVault))
        waitFor(vaultRepository.fetchSyncCalled)
    }

    /// `init(coordinator:masterPasswordRepromptHelper:services:state:vaultItemMoreOptionsHelper:)` initializes
    /// the search process mediator.
    func test_init() {
        XCTAssertTrue(searchProcessorMediatorFactory.makeCalled)
    }

    /// `perform(_:)` with `.appeared` starts streaming vault items.
    @MainActor
    func test_perform_appeared() {
        let vaultListItem = VaultListItem.fixture()
        let vaultListSection = VaultListSection(id: "", items: [vaultListItem], name: "Items")
        vaultRepository.vaultListSubject.send(VaultListData(sections: [vaultListSection]))

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        XCTAssertEqual(subject.state.loadingState, .data([vaultListSection]))
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.appeared` records any errors.
    func test_perform_appeared_error_vaultListSubjectFail() {
        vaultRepository.vaultListSubject.send(completion: .failure(BitwardenTestError.example))

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.appeared` updates the state depending on if the user has premium account.
    @MainActor
    func test_perform_appeared_hasPremiumAccount() {
        stateService.doesActiveAccountHavePremiumResult = true

        let task = Task {
            await subject.perform(.appeared)
        }
        defer { task.cancel() }

        waitFor(subject.state.hasPremium)
    }

    /// `perform(_:)` with `.appeared` updates the state depending on if the
    /// personal ownership policy is enabled.
    @MainActor
    func test_perform_appeared_personalOwnershipPolicy() {
        policyService.policyAppliesToUserResult[.personalOwnership] = true

        let task = Task {
            await subject.perform(.appeared)
        }
        waitFor(subject.state.isPersonalOwnershipDisabled)
        task.cancel()

        XCTAssertTrue(subject.state.isPersonalOwnershipDisabled)
    }

    /// `perform(_:)` with `.appeared` updates the state with new values
    @MainActor
    func test_perform_appeared_itemTypesUserCanCreate() {
        vaultRepository.getItemTypesUserCanCreateResult = [.card]
        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.itemTypesUserCanCreate == [.card])
        task.cancel()
    }

    /// `perform(_:)` with `appeared` determines whether the vault filter can be shown based on
    /// policy settings.
    @MainActor
    func test_perform_appeared_policyCanShowVaultFilterDisabled() {
        vaultRepository.canShowVaultFilter = false
        subject.state.organizations = [.fixture()]

        let task = Task {
            await subject.perform(.appeared)
        }
        waitFor(subject.state.loadingState == .data([]))
        task.cancel()

        XCTAssertFalse(subject.state.canShowVaultFilter)
        XCTAssertFalse(subject.state.vaultFilterState.canShowVaultFilter)
        XCTAssertEqual(subject.state.vaultFilterState.vaultFilterOptions, [])
    }

    /// `perform(_:)` with `appeared` determines whether the vault filter can be shown based on
    /// policy settings.
    @MainActor
    func test_perform_appeared_policyCanShowVaultFilterEnabled() {
        vaultRepository.canShowVaultFilter = true
        subject.state.organizations = [.fixture()]

        let task = Task {
            await subject.perform(.appeared)
        }
        waitFor(subject.state.loadingState == .data([]))
        task.cancel()

        XCTAssertTrue(subject.state.canShowVaultFilter)
        XCTAssertTrue(subject.state.vaultFilterState.canShowVaultFilter)
        XCTAssertEqual(
            subject.state.vaultFilterState.vaultFilterOptions,
            [.allVaults, .myVault, .organization(.fixture())],
        )
    }

    /// `perform(_:)` with `.morePressed` has the vault item more options helper display the alert.
    @MainActor
    func test_perform_morePressed() async throws {
        await subject.perform(.morePressed(.fixture()))

        XCTAssertTrue(vaultItemMoreOptionsHelper.showMoreOptionsAlertCalled)
        XCTAssertNotNil(vaultItemMoreOptionsHelper.showMoreOptionsAlertHandleDisplayToast)
        XCTAssertNotNil(vaultItemMoreOptionsHelper.showMoreOptionsAlertHandleOpenURL)

        let toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.password))
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
        XCTAssertFalse(try XCTUnwrap(vaultRepository.fetchSyncIsPeriodic))
    }

    /// `perform(_:)` with `.refreshed` records an error if applicable.
    @MainActor
    func test_perform_refreshed_error() async {
        vaultRepository.fetchSyncResult = .failure(BitwardenTestError.example)

        await subject.perform(.refresh)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(.search)` with a keyword should indicate the search processor mediator that the filter changed.
    @MainActor
    func test_perform_search() async throws {
        subject.state.searchVaultFilterType = .organization(.fixture(id: "id1"))

        await subject.perform(.search("example"))

        XCTAssertEqual(
            searchProcessorMediator.updateFilterReceivedFilter,
            VaultListFilter(
                filterType: .organization(.fixture(id: "id1")),
                group: .login,
                searchText: "example",
            ),
        )
    }

    /// `perform(.search)` with a empty keyword should get empty search result.
    @MainActor
    func test_perform_search_emptyString() async {
        subject.state.searchResults = [.fixture(), .fixture()]

        await subject.perform(.search("   "))
        XCTAssertEqual(
            subject.state.searchResults,
            [],
        )
        XCTAssertFalse(searchProcessorMediator.updateFilterCalled)

        subject.state.searchResults = [.fixture(), .fixture()]

        await subject.perform(.search(""))
        XCTAssertEqual(
            subject.state.searchResults,
            [],
        )
        XCTAssertFalse(searchProcessorMediator.updateFilterCalled)
    }

    /// `perform(_:)` with `.streamOrganizations` updates the state's organizations whenever it changes.
    @MainActor
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
    @MainActor
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
    @MainActor
    func test_perform_streamShowWebIcons() {
        let task = Task {
            await subject.perform(.streamShowWebIcons)
        }

        stateService.showWebIconsSubject.send(false)
        waitFor(subject.state.showWebIcons == false)

        task.cancel()
    }

    /// `onNewSearchResults(data:)` closure from search mediator should update search results in state.
    @MainActor
    func test_onNewSearchResults_updatesState() async {
        subject.receive(.searchStateChanged(isSearching: true))

        await searchProcessorMediator.startSearchingReceivedArguments?.onNewSearchResults(
            VaultListData(
                sections: [
                    VaultListSection(
                        id: "SearchResults",
                        items: [
                            VaultListItem(cipherListView: .fixture(name: "Result 1")),
                            VaultListItem(cipherListView: .fixture(name: "Result 2")),
                            VaultListItem(cipherListView: .fixture(name: "Result 3")),
                        ].compactMap(\.self),
                        name: "Search Results",
                    ),
                ],
            ),
        )

        assertInlineSnapshot(of: subject.state.searchResults.dump(), as: .lines) {
            """
            - Cipher: Result 1
            - Cipher: Result 2
            - Cipher: Result 3
            """
        }
    }

    /// `onNewSearchResults(data:)` closure from search mediator updates the state's search to empty
    /// when there are no sections in the data.
    @MainActor
    func test_onNewSearchResults_noSections() async {
        subject.receive(.searchStateChanged(isSearching: true))

        await searchProcessorMediator.startSearchingReceivedArguments?.onNewSearchResults(
            VaultListData(
                sections: [],
            ),
        )

        assertInlineSnapshot(of: subject.state.searchResults.dump(), as: .lines) {
            """
            (empty)
            """
        }
    }

    /// `onNewSearchResults(data:)` closure from search mediator should update search results in state
    /// when TOTP expired.
    @MainActor
    func test_onNewSearchResults_expiredTOTP() async throws { // swiftlint:disable:this function_body_length
        let loginListView = LoginListView.fixture(totp: .standardTotpKey)
        let refreshed = VaultListItem(
            id: "1",
            itemType: .totp(
                name: "refreshed totp",
                totpModel: .init(
                    id: "1",
                    cipherListView: .fixture(type: .login(loginListView)),
                    requiresMasterPassword: false,
                    totpCode: .init(
                        code: "654321",
                        codeGenerationDate: timeProvider.presentTime,
                        period: 30,
                    ),
                ),
            ),
        )
        vaultRepository.refreshTOTPCodesResult = .success(
            [
                refreshed,
            ],
        )

        let expired = VaultListItem(
            id: "1",
            itemType: .totp(
                name: "expiredTOTP",
                totpModel: .init(
                    id: "1",
                    cipherListView: .fixture(type: .login(loginListView)),
                    requiresMasterPassword: false,
                    totpCode: .init(
                        code: "098765",
                        codeGenerationDate: timeProvider.presentTime
                            .addingTimeInterval(-1.5),
                        period: 30,
                    ),
                ),
            ),
        )
        let stable = VaultListItem(
            id: "2",
            itemType: .totp(
                name: "stableTOTP",
                totpModel: .init(
                    id: "1",
                    cipherListView: .fixture(type: .login(loginListView)),
                    requiresMasterPassword: false,
                    totpCode: .init(
                        code: "111222",
                        codeGenerationDate: timeProvider.presentTime,
                        period: 30,
                    ),
                ),
            ),
        )

        subject.receive(.searchStateChanged(isSearching: true))

        await searchProcessorMediator.startSearchingReceivedArguments?.onNewSearchResults(
            VaultListData(
                sections: [
                    VaultListSection(
                        id: "",
                        items: [expired, stable],
                        name: "",
                    ),
                ],
            ),
        )

        try await waitForAsync {
            !self.vaultRepository.refreshedTOTPCodes.isEmpty
        }
        XCTAssertEqual(
            vaultRepository.refreshedTOTPCodes,
            [expired],
        )
        let expectedRefresh = [
            refreshed,
            stable,
        ]
        try await waitForAsync {
            self.subject.state.searchResults == expectedRefresh
        }
    }

    /// `onNewSearchResults(data:)` closure from search mediator should update search results in state
    /// but refreshing TOTP throws.
    @MainActor
    func test_onNewSearchResults_expiredTOTP_error() async throws { // swiftlint:disable:this function_body_length
        let loginListView = LoginListView.fixture(totp: .standardTotpKey)
        vaultRepository.refreshTOTPCodesResult = .failure(BitwardenTestError.example)

        let expired = VaultListItem(
            id: "1",
            itemType: .totp(
                name: "expiredTOTP",
                totpModel: .init(
                    id: "1",
                    cipherListView: .fixture(type: .login(loginListView)),
                    requiresMasterPassword: false,
                    totpCode: .init(
                        code: "098765",
                        codeGenerationDate: timeProvider.presentTime
                            .addingTimeInterval(-1.5),
                        period: 30,
                    ),
                ),
            ),
        )
        let stable = VaultListItem(
            id: "2",
            itemType: .totp(
                name: "stableTOTP",
                totpModel: .init(
                    id: "1",
                    cipherListView: .fixture(type: .login(loginListView)),
                    requiresMasterPassword: false,
                    totpCode: .init(
                        code: "111222",
                        codeGenerationDate: timeProvider.presentTime,
                        period: 30,
                    ),
                ),
            ),
        )

        subject.receive(.searchStateChanged(isSearching: true))

        await searchProcessorMediator.startSearchingReceivedArguments?.onNewSearchResults(
            VaultListData(
                sections: [
                    VaultListSection(
                        id: "",
                        items: [expired, stable],
                        name: "",
                    ),
                ],
            ),
        )

        try await waitForAsync {
            !self.vaultRepository.refreshedTOTPCodes.isEmpty
        }
        XCTAssertEqual(
            vaultRepository.refreshedTOTPCodes,
            [expired],
        )

        // Ensure that even after a delay, the searchResults are not refreshed,
        //  given the error.
        var didWait = false
        let delay = Task {
            try await Task.sleep(nanoseconds: (1 * NSEC_PER_SEC) / 4)
            didWait = true
        }
        try await waitForAsync { didWait }
        delay.cancel()

        XCTAssertEqual(
            subject.state.searchResults,
            [
                expired,
                stable,
            ],
        )
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route with the correct group.
    @MainActor
    func test_receive_addItemPressed() {
        subject.state.group = .card
        subject.receive(.addItemPressed(.card))
        XCTAssertEqual(coordinator.routes.last, .addItem(group: .card, type: .card))
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route with the correct group.
    @MainActor
    func test_receive_addItemPressed_default() {
        let group = VaultListGroup.folder(id: "1", name: "Folder")
        subject.state.group = group
        subject.receive(.addItemPressed(nil))
        XCTAssertEqual(coordinator.routes.last, .addItem(group: group, type: .login))
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route with an organization
    /// group.
    @MainActor
    func test_receive_addItemPressed_collection() {
        let group = VaultListGroup.collection(id: "1", name: "Team A", organizationId: "12345")
        subject.state.group = group
        subject.receive(.addItemPressed(.secureNote))
        XCTAssertEqual(coordinator.routes.last, .addItem(group: group, type: .secureNote))
    }

    /// TOTP Code expiration updates the state's TOTP codes.
    @MainActor
    func test_receive_appeared_totpExpired_single() throws {
        let result = VaultListItem.fixtureTOTP(
            totp: .fixture(
                totpCode: .init(
                    code: "",
                    codeGenerationDate: .init(year: 2023, month: 12, day: 31),
                    period: 30,
                ),
            ),
        )
        let resultSection = VaultListSection(id: "", items: [result], name: "Items")
        let newResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                totpCode: .init(
                    code: "345678",
                    codeGenerationDate: Date(),
                    period: 30,
                ),
            ),
        )
        let newResultSection = VaultListSection(id: "", items: [newResult], name: "Items")
        vaultRepository.refreshTOTPCodesResult = .success([newResult])
        let task = Task {
            await subject.perform(.appeared)
        }
        vaultRepository.vaultListSubject.send(VaultListData(sections: [resultSection]))
        waitFor(!vaultRepository.refreshedTOTPCodes.isEmpty)
        waitFor(subject.state.loadingState.data == [newResultSection])
        task.cancel()
        XCTAssertEqual([result], vaultRepository.refreshedTOTPCodes)
        let first = try XCTUnwrap(subject.state.loadingState.data?.first)
        XCTAssertEqual(first, newResultSection)
    }

    /// TOTP Code expiration updates the state's TOTP codes.
    @MainActor
    func test_receive_appeared_totpExpired_multi() throws { // swiftlint:disable:this function_body_length
        subject = VaultGroupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            masterPasswordRepromptHelper: masterPasswordRepromptHelper,
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                searchProcessorMediatorFactory: searchProcessorMediatorFactory,
                timeProvider: timeProvider,
                vaultRepository: vaultRepository,
            ),
            state: VaultGroupState(
                searchVaultFilterType: .allVaults,
                vaultFilterType: .allVaults,
            ),
            vaultItemMoreOptionsHelper: vaultItemMoreOptionsHelper,
        )
        let olderThanIntervalResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "olderThanIntervalResult",
                totpCode: .init(
                    code: "olderThanIntervalResult",
                    codeGenerationDate: fixedDate.addingTimeInterval(-31.0),
                    period: 30,
                ),
            ),
        )
        let shortExpirationResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "shortExpirationResult",
                totpCode: .init(
                    code: "shortExpirationResult",
                    codeGenerationDate: Date(year: 2023, month: 12, day: 31, minute: 0, second: 24),
                    period: 30,
                ),
            ),
        )
        let veryOldResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "veryOldResult",
                totpCode: .init(
                    code: "veryOldResult",
                    codeGenerationDate: fixedDate.addingTimeInterval(-40.0),
                    period: 30,
                ),
            ),
        )
        let expectedUpdate1 = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "olderThanIntervalResult",
                totpCode: .init(
                    code: "olderThanIntervalResult",
                    codeGenerationDate: fixedDate,
                    period: 30,
                ),
            ),
        )
        let expectedUpdate2 = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "shortExpirationResult",
                totpCode: .init(
                    code: "shortExpirationResult",
                    codeGenerationDate: fixedDate,
                    period: 30,
                ),
            ),
        )
        let expectedUpdate3 = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "veryOldResult",
                totpCode: .init(
                    code: "veryOldResult",
                    codeGenerationDate: fixedDate,
                    period: 30,
                ),
            ),
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
                        period: 30,
                    ),
                ),
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
                    period: 30,
                ),
            ),
        )
        let vaultListSection = VaultListSection(
            id: "",
            items: [
                olderThanIntervalResult,
                shortExpirationResult,
                veryOldResult,
                stableResult,
            ],
            name: "Items",
        )
        vaultRepository.vaultListSubject.send(VaultListData(sections: [vaultListSection]))
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
                .sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending },
        )
    }

    /// `receive(_:)` with `.clearURL` clears the url in the state.
    @MainActor
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `receive` with `.copyTOTPCode` copies the value with the pasteboard service.
    @MainActor
    func test_receive_copyTOTPCode() {
        subject.receive(.copyTOTPCode("123456"))
        XCTAssertEqual(pasteboardService.copiedString, "123456")
        XCTAssertEqual(
            subject.state.toast,
            Toast(title: Localizations.valueHasBeenCopied(Localizations.verificationCode)),
        )
    }

    /// `receive(_:)` with `.itemPressed` on a cipher navigates to the `.viewItem` route.
    @MainActor
    func test_receive_itemPressed_cipher() async throws {
        let cipherListView = CipherListView.fixture(id: "id")

        subject.receive(.itemPressed(.fixture(cipherListView: cipherListView)))
        try await waitForAsync { !self.coordinator.routes.isEmpty }

        XCTAssertEqual(coordinator.routes.last, .viewItem(id: "id", masterPasswordRepromptCheckCompleted: true))
        XCTAssertEqual(masterPasswordRepromptHelper.repromptForMasterPasswordCipherListView, cipherListView)
    }

    /// `receive(_:)` with `.itemPressed` shows an alert when tapping on a cipher which failed to decrypt.
    @MainActor
    func test_receive_itemPressed_cipherDecryptionFailure() async throws {
        let cipherListView = CipherListView.fixture(name: Localizations.errorCannotDecrypt)
        let item = VaultListItem.fixture(cipherListView: cipherListView)

        subject.receive(.itemPressed(item))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .cipherDecryptionFailure(cipherIds: ["1"]) { _ in })

        try await alert.tapAction(title: Localizations.copyErrorReport)
        XCTAssertEqual(
            pasteboardService.copiedString,
            """
            \(Localizations.decryptionError)
            \(Localizations.bitwardenCouldNotDecryptThisVaultItemDescriptionLong)

            1
            """,
        )
    }

    /// `receive(_:)` with `.itemPressed` on a group navigates to the `.group` route.
    @MainActor
    func test_receive_itemPressed_group() {
        subject.receive(.itemPressed(VaultListItem(id: "1", itemType: .group(.card, 2))))
        XCTAssertEqual(coordinator.routes.last, .group(.card, filter: .allVaults))
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.viewItem` route.
    @MainActor
    func test_receive_itemPressed_totp() async throws {
        let cipherListView = CipherListView.fixture()
        let totpItem = VaultListItem.fixtureTOTP(totp: .fixture(cipherListView: cipherListView))

        subject.receive(.itemPressed(totpItem))
        try await waitForAsync { !self.coordinator.routes.isEmpty }

        XCTAssertEqual(coordinator.routes.last, .viewItem(id: totpItem.id, masterPasswordRepromptCheckCompleted: true))
        XCTAssertEqual(masterPasswordRepromptHelper.repromptForMasterPasswordCipherListView, cipherListView)
    }

    /// `receive(_:)` with `.searchTextChanged` and no value sets the state correctly.
    @MainActor
    func test_receive_searchTextChanged_withoutValue() {
        subject.state.searchText = "search"
        subject.receive(.searchTextChanged(""))
        XCTAssertEqual(subject.state.searchText, "")
    }

    /// `receive(_:)` with `.searchTextChanged` and a value sets the state correctly.
    @MainActor
    func test_receive_searchTextChanged_withValue() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("search"))
        XCTAssertEqual(subject.state.searchText, "search")
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    @MainActor
    func test_receive_toastShown() {
        let toast = Toast(title: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.searchStateChanged(isSearching: false)` hides the profile switcher
    @MainActor
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
    @MainActor
    func test_receive_searchStateChanged_true_setsSearch() {
        subject.state.isSearching = false
        subject.receive(.searchStateChanged(isSearching: true))

        XCTAssertTrue(subject.state.isSearching)
    }

    /// `receive(_:)` with `.searchVaultFilterChanged` updates the state correctly.
    @MainActor
    func test_receive_searchVaultFilterChanged() {
        let organization = Organization.fixture()

        subject.state.searchVaultFilterType = .myVault
        subject.receive(.searchVaultFilterChanged(.organization(organization)))

        XCTAssertEqual(subject.state.searchVaultFilterType, .organization(organization))
    }

    /// `receive(_:)` with `.totpCodeExpired` handles errors.
    @MainActor
    func test_receive_totpExpired_error() throws {
        subject = VaultGroupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            masterPasswordRepromptHelper: MockMasterPasswordRepromptHelper(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                searchProcessorMediatorFactory: searchProcessorMediatorFactory,
                vaultRepository: vaultRepository,
            ),
            state: VaultGroupState(
                searchVaultFilterType: .allVaults,
                vaultFilterType: .allVaults,
            ),
            vaultItemMoreOptionsHelper: vaultItemMoreOptionsHelper,
        )
        struct TestError: Error, Equatable {}
        let result = VaultListItem.fixtureTOTP(
            totp: .fixture(
                totpCode: .init(
                    code: "",
                    codeGenerationDate: .distantPast,
                    period: 30,
                ),
            ),
        )
        vaultRepository.refreshTOTPCodesResult = .failure(TestError())
        let task = Task {
            await subject.perform(.appeared)
        }
        vaultRepository.vaultListSubject.send(VaultListData(
            sections: [VaultListSection(id: "1", items: [result], name: "")],
        ))
        waitFor(!vaultRepository.refreshedTOTPCodes.isEmpty)
        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()
        let first = try XCTUnwrap(errorReporter.errors.first as? TestError)
        XCTAssertEqual(first, TestError())
    }
}
