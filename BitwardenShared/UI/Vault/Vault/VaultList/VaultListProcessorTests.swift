import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - VaultListProcessorTests

// swiftlint:disable file_length

class VaultListProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var application: MockApplication!
    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var notificationService: MockNotificationService!
    var pasteboardService: MockPasteboardService!
    var policyService: MockPolicyService!
    var stateService: MockStateService!
    var subject: VaultListProcessor!
    var timeProvider: MockTimeProvider!
    var vaultItemMoreOptionsHelper: MockVaultItemMoreOptionsHelper!
    var vaultRepository: MockVaultRepository!

    let profile1 = ProfileSwitcherItem.fixture()
    let profile2 = ProfileSwitcherItem.fixture()

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        application = MockApplication()
        authRepository = MockAuthRepository()
        authService = MockAuthService()
        errorReporter = MockErrorReporter()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        notificationService = MockNotificationService()
        pasteboardService = MockPasteboardService()
        policyService = MockPolicyService()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 6, day: 28)))
        vaultItemMoreOptionsHelper = MockVaultItemMoreOptionsHelper()
        vaultRepository = MockVaultRepository()
        let services = ServiceContainer.withMocks(
            application: application,
            authRepository: authRepository,
            authService: authService,
            errorReporter: errorReporter,
            notificationService: notificationService,
            pasteboardService: pasteboardService,
            policyService: policyService,
            stateService: stateService,
            timeProvider: timeProvider,
            vaultRepository: vaultRepository
        )

        subject = VaultListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: VaultListState(),
            vaultItemMoreOptionsHelper: vaultItemMoreOptionsHelper
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        authService = nil
        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        policyService = nil
        stateService = nil
        subject = nil
        vaultItemMoreOptionsHelper = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `itemDeleted()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_itemDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemDeleted()
        XCTAssertEqual(subject.state.toast?.text, Localizations.itemDeleted)
    }

    /// `itemSoftDeleted()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_itemSoftDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemSoftDeleted()
        XCTAssertEqual(subject.state.toast?.text, Localizations.itemSoftDeleted)
    }

    /// `itemRestored()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_itemRestored() {
        XCTAssertNil(subject.state.toast)

        subject.itemRestored()
        XCTAssertEqual(subject.state.toast?.text, Localizations.itemRestored)
    }

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository.
    @MainActor
    func test_perform_appeared() async {
        await subject.perform(.appeared)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.appeared` doesn't show an alert or log an error if the request was cancelled.
    @MainActor
    func test_perform_appeared_cancelled() async {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .authorized
        vaultRepository.fetchSyncResult = .failure(URLError(.cancelled))

        await subject.perform(.appeared)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
        XCTAssertTrue(coordinator.alertShown.isEmpty)
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `perform(_:)` with `.appeared` handles any pending login requests for the user to address.
    @MainActor
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

    /// `perform(_:)` with `appeared` does not register the device for notifications
    /// if the user has denied notifications
    func test_perform_appeared_notificationRegistration_denied() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .denied

        await subject.perform(.appeared)

        XCTAssertFalse(application.registerForRemoteNotificationsCalled)
    }

    /// `perform(_:)` with `appeared` does not register the device for notifications
    /// if there is an error
    func test_perform_appeared_notificationRegistration_errored() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .authorized
        stateService.notificationsLastRegistrationError = BitwardenTestError.example

        await subject.perform(.appeared)

        XCTAssertFalse(application.registerForRemoteNotificationsCalled)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `perform(_:)` with `appeared` registers the device for notifications
    /// if the device attempted registration exactly one day (that is, 86400 seconds) ago.
    func test_perform_appeared_notificationRegistration_exactlyADay() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .authorized
        stateService.notificationsLastRegistrationDates["1"] = timeProvider.presentTime.addingTimeInterval(-86400)

        await subject.perform(.appeared)

        XCTAssertTrue(application.registerForRemoteNotificationsCalled)
        XCTAssertEqual(stateService.notificationsLastRegistrationDates["1"], timeProvider.presentTime)
    }

    /// `perform(_:)` with `appeared` does not register the device for notifications
    /// if the device attempted registration less than one day (that is, 86400 seconds) ago.
    func test_perform_appeared_notificationRegistration_lessThanADay() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .authorized
        stateService.notificationsLastRegistrationDates["1"] = timeProvider.presentTime.addingTimeInterval(-86399)

        await subject.perform(.appeared)

        XCTAssertFalse(application.registerForRemoteNotificationsCalled)
        XCTAssertEqual(
            stateService.notificationsLastRegistrationDates["1"],
            timeProvider.presentTime.addingTimeInterval(-86399)
        )
    }

    /// `perform(_:)` with `appeared` registers the device for notifications
    /// if the device attempted registration more than one day (that is, 86400 seconds) ago.
    func test_perform_appeared_notificationRegistration_moreThanADay() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .authorized
        stateService.notificationsLastRegistrationDates["1"] = timeProvider.presentTime.addingTimeInterval(-86401)

        await subject.perform(.appeared)

        XCTAssertTrue(application.registerForRemoteNotificationsCalled)
        XCTAssertEqual(stateService.notificationsLastRegistrationDates["1"], timeProvider.presentTime)
    }

    /// `perform(_:)` with `appeared` registers the device for notifications
    /// if the user has approved notifications and we have never registered before
    func test_perform_appeared_notificationRegistration_never() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .authorized

        await subject.perform(.appeared)

        XCTAssertTrue(application.registerForRemoteNotificationsCalled)
        XCTAssertEqual(stateService.notificationsLastRegistrationDates["1"], timeProvider.presentTime)
    }

    /// `perform(_:)` with `.appeared` updates the state depending on if the
    /// personal ownership policy is enabled.
    @MainActor
    func test_perform_appeared_personalOwnershipPolicy() async {
        policyService.policyAppliesToUserResult[.personalOwnership] = true

        await subject.perform(.appeared)

        XCTAssertTrue(subject.state.isPersonalOwnershipDisabled)
    }

    /// `perform(_:)` with `appeared` determines whether the vault filter can be shown based on
    /// policy settings.
    @MainActor
    func test_perform_appeared_policyCanShowVaultFilterDisabled() async {
        vaultRepository.canShowVaultFilter = false
        subject.state.organizations = [.fixture()]

        await subject.perform(.appeared)

        XCTAssertFalse(subject.state.canShowVaultFilter)
        XCTAssertFalse(subject.state.vaultFilterState.canShowVaultFilter)
        XCTAssertEqual(subject.state.vaultFilterState.vaultFilterOptions, [])
    }

    /// `perform(_:)` with `appeared` determines whether the vault filter can be shown based on
    /// policy settings.
    @MainActor
    func test_perform_appeared_policyCanShowVaultFilterEnabled() async {
        vaultRepository.canShowVaultFilter = true
        subject.state.organizations = [.fixture()]

        await subject.perform(.appeared)

        XCTAssertTrue(subject.state.canShowVaultFilter)
        XCTAssertTrue(subject.state.vaultFilterState.canShowVaultFilter)
        XCTAssertEqual(
            subject.state.vaultFilterState.vaultFilterOptions,
            [.allVaults, .myVault, .organization(.fixture())]
        )
    }

    /// `perform(_:)` with `.appeared` requests notification permissions.
    @MainActor
    func test_perform_appeared_requestNotifications_denied() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .notDetermined
        notificationService.requestAuthorizationResult = .success(false)
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
        XCTAssertFalse(application.registerForRemoteNotificationsCalled)
        XCTAssertNil(stateService.notificationsLastRegistrationDates["1"])
    }

    /// `perform(_:)` with `.appeared` requests notification permissions.
    @MainActor
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
        XCTAssertFalse(application.registerForRemoteNotificationsCalled)
        XCTAssertNil(stateService.notificationsLastRegistrationDates["1"])
    }

    /// `perform(_:)` with `.appeared` requests notification permissions.
    @MainActor
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
        XCTAssertTrue(application.registerForRemoteNotificationsCalled)
        XCTAssertEqual(stateService.notificationsLastRegistrationDates["1"], timeProvider.presentTime)
    }

    /// `perform(_:)` with `.appeared` checks for unassigned ciphers
    /// and updates state if the user taps "OK".
    @MainActor
    func test_perform_appeared_unassignedCiphers() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .authorized
        vaultRepository.shouldShowUnassignedCiphersAlert = true

        await subject.perform(.appeared)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .unassignedCiphers {})

        let requestPermissionAction = try XCTUnwrap(alert.alertActions.last)
        await requestPermissionAction.handler?(requestPermissionAction, [])

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertEqual(stateService.shouldCheckOrganizationUnassignedItems["1"], false)
    }

    /// `perform(_:)` with `.appeared` checks for unassigned ciphers
    /// and updates state if the user taps "OK".
    @MainActor
    func test_perform_appeared_requestNotifications() throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .notDetermined
        vaultRepository.shouldShowUnassignedCiphersAlert = true

        Task {
            await subject.perform(.appeared)

            let pushNotificationsAlert = try XCTUnwrap(coordinator.alertShown.last)
            XCTAssertEqual(pushNotificationsAlert, .pushNotificationsInformation {})

            let requestPermissionAction = try XCTUnwrap(pushNotificationsAlert.alertActions.first)
            await requestPermissionAction.handler?(requestPermissionAction, [])
            if let onDismissed = coordinator.alertOnDismissed {
                onDismissed()
            }
        }

        waitFor(coordinator.alertShown.count == 2)
        let unassignedCiphersAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(unassignedCiphersAlert, .unassignedCiphers {})
    }

    /// `perform(_:)` with `.appeared` checks for unassigned ciphers
    /// and does not update state if the user taps "Remind me later".
    @MainActor
    func test_perform_appeared_unassignedCiphers_cancelled() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .authorized
        vaultRepository.shouldShowUnassignedCiphersAlert = true

        await subject.perform(.appeared)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .unassignedCiphers {})

        let requestPermissionAction = try XCTUnwrap(alert.alertActions.first)
        await requestPermissionAction.handler?(requestPermissionAction, [])

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertEqual(stateService.shouldCheckOrganizationUnassignedItems["1"], nil)
    }

    /// `perform(_:)` with `.appeared` does not check for unassigned ciphers
    /// when the vault repository returns false.
    @MainActor
    func test_perform_appeared_unassignedCiphers_shouldNot() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .authorized
        vaultRepository.shouldShowUnassignedCiphersAlert = false

        await subject.perform(.appeared)

        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.appeared` does not check for unassigned ciphers
    /// on the second call.
    @MainActor
    func test_perform_appeared_unassignedCiphers_shouldNot_secondCall() async throws {
        stateService.activeAccount = .fixture()
        notificationService.authorizationStatus = .authorized
        vaultRepository.shouldShowUnassignedCiphersAlert = true

        await subject.perform(.appeared)

        XCTAssertEqual(coordinator.alertShown.count, 1)

        await subject.perform(.appeared)

        XCTAssertEqual(coordinator.alertShown.count, 1)
    }

    /// `perform(_:)` with `.morePressed` has the vault item more options helper display the alert.
    @MainActor
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
    @MainActor
    func test_perform_refresh() async {
        await subject.perform(.refreshVault)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.refreshed` records an error if applicable.
    @MainActor
    func test_perform_refreshed_error() async {
        vaultRepository.fetchSyncResult = .failure(BitwardenTestError.example)

        await subject.perform(.refreshVault)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(.refreshAccountProfiles)` without profiles for the profile switcher.
    @MainActor
    func test_perform_refresh_profiles_empty() async {
        await subject.perform(.refreshAccountProfiles)

        XCTAssertEqual(subject.state.profileSwitcherState.activeAccountInitials, "..")
        XCTAssertEqual(subject.state.profileSwitcherState.alternateAccounts, [])
    }

    /// `perform(.refreshAccountProfiles)` with mismatched active account and accounts should yield an empty
    /// profile switcher state.
    @MainActor
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
    @MainActor
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
    @MainActor
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
    @MainActor
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

    /// `perform(_:)` with `.requestedProfileSwitcher(visible:)` updates the state correctly.
    @MainActor
    func test_perform_requestedProfileSwitcher() async {
        let annAccount = ProfileSwitcherItem.anneAccount
        let beeAccount = ProfileSwitcherItem.beeAccount

        subject.state.profileSwitcherState.accounts = [annAccount, beeAccount]
        subject.state.profileSwitcherState.isVisible = false

        authRepository.profileSwitcherState = ProfileSwitcherState.maximumAccounts
        await subject.perform(.profileSwitcher(.requestedProfileSwitcher(visible: true)))

        // Ensure that the profile switcher state is updated
        waitFor(subject.state.profileSwitcherState == authRepository.profileSwitcherState)
        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should not update the state for add Account
    @MainActor
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
    @MainActor
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
    @MainActor
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

    /// `perform(.search)` with a keyword should update search results in state.
    @MainActor
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
    @MainActor
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
    @MainActor
    func test_perform_search_emptyString() async {
        await subject.perform(.search("   "))
        XCTAssertEqual(subject.state.searchResults.count, 0)
        XCTAssertEqual(
            subject.state.searchResults,
            []
        )
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

    /// `perform(_:)` with `.streamVaultList` updates the state's vault list whenever it changes.
    @MainActor
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
    @MainActor
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
    @MainActor
    func test_perform_streamVaultList_needsSync_emptyData() throws {
        vaultRepository.needsSyncResult = .success(true)

        let task = Task {
            await subject.perform(.streamVaultList)
        }

        vaultRepository.vaultListSubject.send([])
        waitFor(subject.state.loadingState == .loading([]))
        task.cancel()

        XCTAssertTrue(vaultRepository.needsSyncCalled)
        XCTAssertEqual(subject.state.loadingState, .loading([]))
    }

    /// `perform(_:)` with `.streamVaultList` updates the state's vault list whenever it changes.
    @MainActor
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
    @MainActor
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
    @MainActor
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
    @MainActor
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
    @MainActor
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
    @MainActor
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
    @MainActor
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
    @MainActor
    func test_receive_accountPressed() async {
        subject.state.profileSwitcherState.isVisible = true
        await subject.perform(.profileSwitcher(.accountPressed(ProfileSwitcherItem.fixture())))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.addAccountPressed` updates the state correctly
    @MainActor
    func test_receive_addAccountPressed() async {
        subject.state.profileSwitcherState.isVisible = true
        await subject.perform(.profileSwitcher(.addAccountPressed))

        XCTAssertEqual(coordinator.routes.last, .addAccount)
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route.
    @MainActor
    func test_receive_addItemPressed() {
        subject.receive(.addItemPressed)

        XCTAssertEqual(coordinator.routes.last, .addItem())
    }

    /// `receive(_:)` with `.addItemPressed` hides the profile switcher view
    @MainActor
    func test_receive_addItemPressed_hideProfiles() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.addItemPressed)

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.clearURL` clears the url in the state.
    @MainActor
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `receive` with `.copyTOTPCode` does nothing.
    @MainActor
    func test_receive_copyTOTPCode() {
        subject.receive(.copyTOTPCode("123456"))
        XCTAssertNil(pasteboardService.copiedString)
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.viewItem` route for a cipher.
    @MainActor
    func test_receive_itemPressed_cipher() {
        let item = VaultListItem.fixture()
        subject.receive(.itemPressed(item: item))

        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id))
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.group` route for a group.
    @MainActor
    func test_receive_itemPressed_group() {
        subject.receive(.itemPressed(item: VaultListItem(id: "1", itemType: .group(.card, 1))))

        XCTAssertEqual(coordinator.routes.last, .group(.card, filter: .allVaults))
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.totp` route for a totp code.
    @MainActor
    func test_receive_itemPressed_totp() {
        subject.receive(.itemPressed(item: .fixtureTOTP(totp: .fixture())))

        XCTAssertEqual(coordinator.routes.last, .viewItem(id: "123"))
    }

    /// `receive(_:)` with `ProfileSwitcherAction.backgroundPressed` turns off the Profile Switcher Visibility.
    @MainActor
    func test_receive_profileSwitcherBackgroundPressed() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.profileSwitcher(.backgroundPressed))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `ProfileSwitcherAction.scrollOffsetChanged` updates the scroll offset.
    @MainActor
    func test_receive_profileSwitcherScrollOffset() {
        subject.state.profileSwitcherState.scrollOffset = .zero
        subject.receive(.profileSwitcher(.scrollOffsetChanged(CGPoint(x: 10, y: 10))))
        XCTAssertEqual(subject.state.profileSwitcherState.scrollOffset, CGPoint(x: 10, y: 10))
    }

    /// `receive(_:)` with `.searchStateChanged(isSearching: false)` hides the profile switcher
    @MainActor
    func test_receive_searchTextChanged_false_noProfilesChange() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.searchStateChanged(isSearching: false))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.searchStateChanged(isSearching: true)` hides the profile switcher
    @MainActor
    func test_receive_searchStateChanged_true_profilesHide() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.searchStateChanged(isSearching: true))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.searchTextChanged` without a matching search term updates the state correctly.
    @MainActor
    func test_receive_searchTextChanged_withoutResult() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("search"))

        XCTAssertEqual(subject.state.searchText, "search")
        XCTAssertEqual(subject.state.searchResults.count, 0)
    }

    /// `receive(_:)` with `.searchVaultFilterChanged` updates the state correctly.
    @MainActor
    func test_receive_searchVaultFilterChanged() {
        let organization = Organization.fixture()

        subject.state.searchVaultFilterType = .myVault
        subject.receive(.searchVaultFilterChanged(.organization(organization)))

        XCTAssertEqual(subject.state.searchVaultFilterType, .organization(organization))
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    @MainActor
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.totpCodeExpired` does nothing.
    @MainActor
    func test_receive_totpCodeExpired() {
        let initialState = subject.state

        subject.receive(.totpCodeExpired(.fixture()))

        XCTAssertEqual(subject.state, initialState)
    }

    /// `receive(_:)` with `.vaultFilterChanged` updates the state correctly.
    @MainActor
    func test_receive_vaultFilterChanged() {
        let organization = Organization.fixture()

        subject.state.vaultFilterType = .myVault
        subject.receive(.vaultFilterChanged(.organization(organization)))

        XCTAssertEqual(subject.state.vaultFilterType, .organization(organization))
    }
}
