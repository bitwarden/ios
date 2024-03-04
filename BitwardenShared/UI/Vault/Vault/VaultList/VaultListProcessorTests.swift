import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - VaultListProcessorTests

// swiftlint:disable file_length

class VaultListProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var notificationService: MockNotificationService!
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var subject: VaultListProcessor!
    var vaultRepository: MockVaultRepository!

    let profile1 = ProfileSwitcherItem.fixture()
    let profile2 = ProfileSwitcherItem.fixture()

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        authService = MockAuthService()
        errorReporter = MockErrorReporter()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        notificationService = MockNotificationService()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        vaultRepository = MockVaultRepository()
        let services = ServiceContainer.withMocks(
            authRepository: authRepository,
            authService: authService,
            errorReporter: errorReporter,
            notificationService: notificationService,
            pasteboardService: pasteboardService,
            stateService: stateService,
            vaultRepository: vaultRepository
        )

        subject = VaultListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: VaultListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        authService = nil
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

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository.
    func test_perform_appeared() async {
        await subject.perform(.appeared)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.appeared` handles any pending login requests for the user to address.
    func test_perform_appeared_checkPendingLoginRequests() async {
        // Set up the mock data.
        stateService.activeAccount = .fixture()
        stateService.loginRequest = .init(id: "2", userId: Account.fixture().profile.userId)
        authService.getPendingLoginRequestResult = .success([.fixture()])
        notificationService.authorizationStatus = .authorized

        // Test.
        await subject.perform(.appeared)

        // Verify the results.
        XCTAssertEqual(coordinator.routes.last, .loginRequest(.fixture()))
        XCTAssertNil(stateService.loginRequest)
    }

    /// `perform(_:)` with `.appeared` requests notification permissions.
    func test_perform_appeared_requestNotifications_error() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .notDetermined
        notificationService.requestAuthorizationResult = .failure(BitwardenTestError.example)
        stateService.loginRequest = .init(id: "2", userId: Account.fixture().profile.userId)
        authService.getPendingLoginRequestResult = .success([.fixture()])

        // Test.
        await subject.perform(.appeared)

        // Verify the results.
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .pushNotificationsInformation {})

        // Trigger the request
        let requestPermissionAction = try XCTUnwrap(alert.alertActions.first)
        await requestPermissionAction.handler?(requestPermissionAction, [])

        let error = try XCTUnwrap(errorReporter.errors.last as? BitwardenTestError)
        XCTAssertEqual(error, .example)
    }

    /// `perform(_:)` with `.appeared` requests notification permissions.
    func test_perform_appeared_requestNotifications_success() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .notDetermined
        stateService.loginRequest = .init(id: "2", userId: Account.fixture().profile.userId)
        authService.getPendingLoginRequestResult = .success([.fixture()])

        // Test.
        await subject.perform(.appeared)

        // Verify the results.
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .pushNotificationsInformation {})

        // Trigger the request
        let requestPermissionAction = try XCTUnwrap(alert.alertActions.first)
        await requestPermissionAction.handler?(requestPermissionAction, [])

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertEqual(
            [.alert, .sound, .badge],
            notificationService.requestedOptions
        )
    }

    /// `perform(_:)` with `.refreshed` requests a fetch sync update with the vault repository.
    func test_perform_refresh() async {
        await subject.perform(.refreshVault)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.refreshed` records an error if applicable.
    func test_perform_refreshed_error() async {
        vaultRepository.fetchSyncResult = .failure(BitwardenTestError.example)

        await subject.perform(.refreshVault)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(.refreshAccountProfiles)` without profiles for the profile switcher.
    func test_perform_refresh_profiles_empty() async {
        await subject.perform(.refreshAccountProfiles)

        XCTAssertEqual(subject.state.profileSwitcherState.activeAccountInitials, "..")
        XCTAssertEqual(subject.state.profileSwitcherState.alternateAccounts, [])
    }

    /// `perform(.refreshAccountProfiles)` with mismatched active account and accounts should yield an empty
    /// profile switcher state.
    func test_perform_refresh_profiles_mismatch() async {
        let profile = ProfileSwitcherItem.fixture()
        authRepository.profileSwitcherState = .init(
            accounts: [],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: false
        )
        await subject.perform(.refreshAccountProfiles)

        XCTAssertEqual(subject.state.profileSwitcherState.activeAccountInitials, "..")
        XCTAssertEqual(subject.state.profileSwitcherState.alternateAccounts, [])
    }

    /// `perform(.refreshAccountProfiles)` with an active account and accounts should yield a profile switcher state.
    func test_perform_refresh_profiles_single_active() async {
        authRepository.profileSwitcherState = .init(
            accounts: [profile1],
            activeAccountId: profile1.userId,
            allowLockAndLogout: true,
            isVisible: false
        )
        await subject.perform(.refreshAccountProfiles)

        XCTAssertEqual(profile1, subject.state.profileSwitcherState.activeAccountProfile)
    }

    /// `perform(.refreshAccountProfiles)` with no active account and accounts should yield an empty
    /// profile switcher state.
    func test_perform_refresh_profiles_single_notActive() async {
        authRepository.profileSwitcherState = .init(
            accounts: [profile1],
            activeAccountId: nil,
            allowLockAndLogout: true,
            isVisible: false
        )
        await subject.perform(.refreshAccountProfiles)

        XCTAssertEqual(subject.state.profileSwitcherState.activeAccountInitials, "..")
        XCTAssertEqual(subject.state.profileSwitcherState.alternateAccounts, [profile1])
        XCTAssertEqual(subject.state.profileSwitcherState.accounts, [profile1])
    }

    /// `perform(.refreshAccountProfiles)` with an active account and multiple accounts should yield a
    /// profile switcher state.
    func test_perform_refresh_profiles_single_multiAccount() async {
        authRepository.profileSwitcherState = .init(
            accounts: [profile1, profile2],
            activeAccountId: profile1.userId,
            allowLockAndLogout: true,
            isVisible: false
        )
        await subject.perform(.refreshAccountProfiles)

        XCTAssertEqual([profile2], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile1, subject.state.profileSwitcherState.activeAccountProfile)
    }

    /// `perform(.search)` with a keyword should update search results in state.
    func test_perform_search() async {
        let searchResult: [CipherView] = [.fixture(name: "example")]
        vaultRepository.searchVaultListSubject.value = searchResult.compactMap { VaultListItem(cipherView: $0) }
        await subject.perform(.search("example"))

        XCTAssertEqual(subject.state.searchResults.count, 1)
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
    func test_perform_streamVaultList_doesntNeedSync() throws {
        let vaultListItem = VaultListItem.fixture()
        vaultRepository.vaultListSubject.send([
            VaultListSection(
                id: "1",
                items: [vaultListItem],
                name: "Name"
            ),
        ])

        let task = Task {
            await subject.perform(.streamVaultList)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        let sections = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].items, [vaultListItem])
    }

    /// `perform(_:)` with `.streamVaultList` records any errors.
    func test_perform_streamVaultList_error() throws {
        vaultRepository.vaultListSubject.send(completion: .failure(BitwardenTestError.example))

        let task = Task {
            await subject.perform(.streamVaultList)
        }

        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.streamVaultList` updates the state's vault list whenever it changes.
    func test_perform_streamVaultList_needsSync_emptyData() throws {
        vaultRepository.needsSyncResult = .success(true)

        let task = Task {
            await subject.perform(.streamVaultList)
        }

        vaultRepository.vaultListSubject.send([])
        waitFor(vaultRepository.needsSyncCalled)
        task.cancel()

        XCTAssertEqual(subject.state.loadingState, .loading([]))
    }

    /// `perform(_:)` with `.streamVaultList` updates the state's vault list whenever it changes.
    func test_perform_streamVaultList_needsSync_hasData() throws {
        let vaultListItem = VaultListItem.fixture()
        vaultRepository.needsSyncResult = .success(true)

        let task = Task {
            await subject.perform(.streamVaultList)
        }

        vaultRepository.vaultListSubject.send([
            VaultListSection(
                id: "1",
                items: [vaultListItem],
                name: "Name"
            ),
        ])
        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        let sections = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].items, [vaultListItem])
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` shows the alert and allows the user to
    /// lock the selected account, which navigates back to the vault unlock page for the active account.
    func test_receive_accountLongPressed_lock_activeAccount() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture(isUnlocked: true, userId: "1")
        let otherProfile = ProfileSwitcherItem.fixture(isUnlocked: true, userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.activeAccount = .fixture()
        authRepository.vaultTimeout = [
            "1": .fiveMinutes,
            "42": .fifteenMinutes,
        ]

        await subject.perform(.profileSwitcher(.accountLongPressed(activeProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to lock the account.
        let lockAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await lockAction.handler?(lockAction, [])

        // Verify the results.
        XCTAssertEqual(coordinator.events.last, .lockVault(userId: activeProfile.userId))
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` shows the alert and allows the user to
    /// lock the selected account, which displays a toast.
    func test_receive_accountLongPressed_lock_otherAccount() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture(userId: "1")
        let otherProfile = ProfileSwitcherItem.fixture(isUnlocked: true, userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.activeAccount = .fixture()
        authRepository.vaultTimeout = [
            "1": .fiveMinutes,
            "42": .fifteenMinutes,
        ]

        await subject.perform(.profileSwitcher(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to lock the account.
        let lockAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await lockAction.handler?(lockAction, [])

        // Verify the results.
        XCTAssertEqual(coordinator.events.last, .lockVault(userId: otherProfile.userId))
        XCTAssertEqual(subject.state.toast?.text, Localizations.accountLockedSuccessfully)
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` records any errors from locking the account.
    func test_receive_accountLongPressed_lock_error() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture(userId: "1")
        let otherProfile = ProfileSwitcherItem.fixture(isUnlocked: true, userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        stateService.activeAccount = nil

        await subject.perform(.profileSwitcher(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to lock the account.
        let lockAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await lockAction.handler?(lockAction, [])

        // Verify the results.
        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, .noActiveAccount)
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` shows the alert and allows the user to
    /// log out of the selected account, which navigates back to the landing page for the active account.
    func test_receive_accountLongPressed_logout_activeAccount() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture(userId: "1")
        let otherProfile = ProfileSwitcherItem.fixture(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.activeAccount = .fixture()

        await subject.perform(.profileSwitcher(.accountLongPressed(activeProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to log out from the account.
        let logoutAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await logoutAction.handler?(logoutAction, [])

        // Confirm logging out on the second alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(coordinator.events.last, .logout(userId: activeProfile.userId, userInitiated: true))
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` shows the alert and allows the user to
    /// log out of the selected account, which displays a toast.
    func test_receive_accountLongPressed_logout_otherAccount() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture()
        let otherProfile = ProfileSwitcherItem.fixture(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.activeAccount = .fixture()
        await subject.perform(.profileSwitcher(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to log out from the account.
        let logoutAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await logoutAction.handler?(logoutAction, [])

        // Confirm logging out on the second alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(
            coordinator.events.last,
            .logout(userId: otherProfile.userId, userInitiated: true)
        )
        XCTAssertEqual(subject.state.toast?.text, Localizations.accountLoggedOutSuccessfully)
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` records any errors from logging out the
    /// account.
    func test_receive_accountLongPressed_logout_error() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture()
        let otherProfile = ProfileSwitcherItem.fixture(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.getAccountError = BitwardenTestError.example

        await subject.perform(.profileSwitcher(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to log out from the account.
        let logoutAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await logoutAction.handler?(logoutAction, [])

        // Confirm logging out on the second alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `receive(_:)` with `.addAccountPressed` updates the state correctly
    func test_receive_accountPressed() async {
        subject.state.profileSwitcherState.isVisible = true
        await subject.perform(.profileSwitcher(.accountPressed(ProfileSwitcherItem.fixture())))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.addAccountPressed` updates the state correctly
    func test_receive_addAccountPressed() async {
        subject.state.profileSwitcherState.isVisible = true
        await subject.perform(.profileSwitcher(.addAccountPressed))

        XCTAssertEqual(coordinator.routes.last, .addAccount)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should not update the state for add Account
    func test_perform_rowAppeared_add() async {
        let profile = ProfileSwitcherItem.fixture()
        let alternate = ProfileSwitcherItem.fixture()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        await subject.perform(.profileSwitcher(.rowAppeared(.addAccount)))

        XCTAssertFalse(subject.state.profileSwitcherState.hasSetAccessibilityFocus)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should not update the state for alternate account
    func test_perform_rowAppeared_alternate() async {
        let profile = ProfileSwitcherItem.fixture()
        let alternate = ProfileSwitcherItem.fixture()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        await subject.perform(.profileSwitcher(.rowAppeared(.alternate(alternate))))

        XCTAssertFalse(subject.state.profileSwitcherState.hasSetAccessibilityFocus)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should update the state for active account
    func test_perform_rowAppeared_active() {
        let profile = ProfileSwitcherItem.fixture()
        let alternate = ProfileSwitcherItem.fixture()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        let task = Task {
            await subject.perform(.profileSwitcher(.rowAppeared(.active(profile))))
        }

        waitFor(subject.state.profileSwitcherState.hasSetAccessibilityFocus, timeout: 0.5)
        task.cancel()
        XCTAssertTrue(subject.state.profileSwitcherState.hasSetAccessibilityFocus)
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route.
    func test_receive_addItemPressed() {
        subject.receive(.addItemPressed)

        XCTAssertEqual(coordinator.routes.last, .addItem())
    }

    /// `receive(_:)` with `.addItemPressed` hides the profile switcher view
    func test_receive_addItemPressed_hideProfiles() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.addItemPressed)

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.clearURL` clears the url in the state.
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `receive` with `.copyTOTPCode` does nothing.
    func test_receive_copyTOTPCode() {
        subject.receive(.copyTOTPCode("123456"))
        XCTAssertNil(pasteboardService.copiedString)
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.viewItem` route for a cipher.
    func test_receive_itemPressed_cipher() {
        let item = VaultListItem.fixture()
        subject.receive(.itemPressed(item: item))

        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id))
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.group` route for a group.
    func test_receive_itemPressed_group() {
        subject.receive(.itemPressed(item: VaultListItem(id: "1", itemType: .group(.card, 1))))

        XCTAssertEqual(coordinator.routes.last, .group(.init(group: .card, filter: .allVaults)))
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.totp` route for a totp code.
    func test_receive_itemPressed_totp() {
        subject.receive(.itemPressed(item: .fixtureTOTP(totp: .fixture())))

        XCTAssertEqual(coordinator.routes.last, .viewItem(id: "123"))
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

        // A card with data should show the copy actions.
        let cardWithData = CipherView.cardFixture(card: .fixture(
            code: "123",
            number: "123456789"
        ))
        item = try XCTUnwrap(VaultListItem(cipherView: cardWithData))
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
        authRepository.validatePasswordResult = .success(true)

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
        authRepository.validatePasswordResult = .success(false)

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

        // A login with data should show the copy and launch actions.
        let loginWithData = CipherView.loginFixture(login: .fixture(
            password: "password",
            uris: [.init(uri: URL.example.relativeString, match: nil)],
            username: "username"
        ))
        item = try XCTUnwrap(VaultListItem(cipherView: loginWithData))
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

        // An identity option can be viewed or edited.
        vaultRepository.fetchCipherResult = .success(.fixture(type: .identity))
        subject.receive(.morePressed(item))
        let alert = try XCTUnwrap(coordinator.alertShown.last)
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

        // A note with data should show the copy action.
        let noteWithData = CipherView.fixture(notes: "Test Note", type: .secureNote)
        item = try XCTUnwrap(VaultListItem(cipherView: noteWithData))
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

    /// `receive(_:)` with `ProfileSwitcherAction.backgroundPressed` turns off the Profile Switcher Visibility.
    func test_receive_profileSwitcherBackgroundPressed() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.profileSwitcher(.backgroundPressed))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `ProfileSwitcherAction.scrollOffsetChanged` updates the scroll offset.
    func test_receive_profileSwitcherScrollOffset() {
        subject.state.profileSwitcherState.scrollOffset = .zero
        subject.receive(.profileSwitcher(.scrollOffsetChanged(CGPoint(x: 10, y: 10))))
        XCTAssertEqual(subject.state.profileSwitcherState.scrollOffset, CGPoint(x: 10, y: 10))
    }

    /// `receive(_:)` with `.searchStateChanged(isSearching: false)` hides the profile switcher
    func test_receive_searchTextChanged_false_noProfilesChange() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.searchStateChanged(isSearching: false))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.searchStateChanged(isSearching: true)` hides the profile switcher
    func test_receive_searchStateChanged_true_profilesHide() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.searchStateChanged(isSearching: true))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.searchTextChanged` without a matching search term updates the state correctly.
    func test_receive_searchTextChanged_withoutResult() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("search"))

        XCTAssertEqual(subject.state.searchText, "search")
        XCTAssertEqual(subject.state.searchResults.count, 0)
    }

    /// `receive(_:)` with `.searchVaultFilterChanged` updates the state correctly.
    func test_receive_searchVaultFilterChanged() {
        let organization = Organization.fixture()

        subject.state.searchVaultFilterType = .myVault
        subject.receive(.searchVaultFilterChanged(.organization(organization)))

        XCTAssertEqual(subject.state.searchVaultFilterType, .organization(organization))
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.totpCodeExpired` does nothing.
    func test_receive_totpCodeExpired() {
        let initialState = subject.state

        subject.receive(.totpCodeExpired(.fixture()))

        XCTAssertEqual(subject.state, initialState)
    }

    /// `receive(_:)` with `.toggleProfilesViewVisibility` updates the state correctly.
    func test_receive_toggleProfilesViewVisibility() {
        subject.state.profileSwitcherState.isVisible = false
        subject.receive(.profileSwitcher(.requestedProfileSwitcher(visible: true)))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.vaultFilterChanged` updates the state correctly.
    func test_receive_vaultFilterChanged() {
        let organization = Organization.fixture()

        subject.state.vaultFilterType = .myVault
        subject.receive(.vaultFilterChanged(.organization(organization)))

        XCTAssertEqual(subject.state.vaultFilterType, .organization(organization))
    }

    /// `didSetVaultFilter(_:)` udpates the filters.
    func test_didSetVaultFilter() {
        subject.didSetVaultFilter(.myVault)
        XCTAssertEqual(subject.state.vaultFilterType, .myVault)
    }
}
