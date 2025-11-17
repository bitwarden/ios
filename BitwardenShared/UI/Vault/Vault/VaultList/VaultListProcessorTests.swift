import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - VaultListProcessorTests

// swiftlint:disable file_length

class VaultListProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var application: MockApplication!
    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var changeKdfService: MockChangeKdfService!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var flightRecorder: MockFlightRecorder!
    var masterPasswordRepromptHelper: MockMasterPasswordRepromptHelper!
    var notificationService: MockNotificationService!
    var pasteboardService: MockPasteboardService!
    var policyService: MockPolicyService!
    var reviewPromptService: MockReviewPromptService!
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
        changeKdfService = MockChangeKdfService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        flightRecorder = MockFlightRecorder()
        masterPasswordRepromptHelper = MockMasterPasswordRepromptHelper()
        notificationService = MockNotificationService()
        pasteboardService = MockPasteboardService()
        policyService = MockPolicyService()
        reviewPromptService = MockReviewPromptService()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 6, day: 28)))
        vaultItemMoreOptionsHelper = MockVaultItemMoreOptionsHelper()
        vaultRepository = MockVaultRepository()
        let services = ServiceContainer.withMocks(
            application: application,
            authRepository: authRepository,
            authService: authService,
            changeKdfService: changeKdfService,
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            notificationService: notificationService,
            pasteboardService: pasteboardService,
            policyService: policyService,
            reviewPromptService: reviewPromptService,
            stateService: stateService,
            timeProvider: timeProvider,
            vaultRepository: vaultRepository,
        )

        subject = VaultListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            masterPasswordRepromptHelper: masterPasswordRepromptHelper,
            services: services,
            state: VaultListState(),
            vaultItemMoreOptionsHelper: vaultItemMoreOptionsHelper,
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        authService = nil
        changeKdfService = nil
        coordinator = nil
        errorReporter = nil
        flightRecorder = nil
        masterPasswordRepromptHelper = nil
        pasteboardService = nil
        policyService = nil
        reviewPromptService = nil
        stateService = nil
        subject = nil
        vaultItemMoreOptionsHelper = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `.appReviewPromptShown` sets the state's `isEligibleForAppReview` to `false`.
    @MainActor
    func test_appReviewPromptShown() {
        subject.state.isEligibleForAppReview = true

        subject.receive(.appReviewPromptShown)
        waitFor(reviewPromptService.setReviewPromptShownVersionCalled)

        XCTAssertFalse(subject.state.isEligibleForAppReview)
        XCTAssertEqual(reviewPromptService.userActions, [])
    }

    /// `perform(_:)` with `.checkAppReviewEligibility` schedules a review prompt if the user is eligible
    /// and the feature flags are enabled.
    @MainActor
    func test_perform_checkAppReviewEligibility_eligible() async {
        reviewPromptService.isEligibleForReviewPromptResult = true
        await subject.perform(.checkAppReviewEligibility)
        await subject.reviewPromptTask?.value
        XCTAssertTrue(subject.state.isEligibleForAppReview)
    }

    /// `perform(_:)` with `.checkAppReviewEligibility` does not schedule a review prompt if the user is not eligible.
    @MainActor
    func test_perform_checkAppReviewEligibility_notEligible() async {
        reviewPromptService.isEligibleForReviewPromptResult = false
        await subject.perform(.checkAppReviewEligibility)
        await subject.reviewPromptTask?.value
        XCTAssertFalse(subject.state.isEligibleForAppReview)
        XCTAssertNil(subject.state.toast?.title)
    }

    /// `itemDeleted()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_itemDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemDeleted()
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.itemDeleted))
    }

    /// `itemSoftDeleted()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_itemSoftDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemSoftDeleted()
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.itemSoftDeleted))
    }

    /// `itemRestored()` delegate method shows the expected toast.
    @MainActor
    func test_delegate_itemRestored() {
        XCTAssertNil(subject.state.toast)

        subject.itemRestored()
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.itemRestored))
    }

    /// `init()` has default values set in the state.
    @MainActor
    func test_init_defaultValues() {
        XCTAssertEqual(
            subject.state.searchVaultFilterState,
            SearchVaultFilterRowState(
                canShowVaultFilter: true,
                isPersonalOwnershipDisabled: false,
                organizations: [],
                searchVaultFilterType: .allVaults,
            ),
        )
        XCTAssertEqual(subject.state.searchVaultFilterType, .allVaults)
        XCTAssertEqual(
            subject.state.vaultFilterState,
            SearchVaultFilterRowState(
                canShowVaultFilter: true,
                isPersonalOwnershipDisabled: false,
                organizations: [],
                searchVaultFilterType: .allVaults,
            ),
        )
        XCTAssertEqual(subject.state.vaultFilterType, .allVaults)
    }

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository.
    /// In this case sync is flagged as periodic.
    @MainActor
    func test_perform_appeared() async {
        await subject.perform(.appeared)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
        XCTAssertTrue(try XCTUnwrap(vaultRepository.fetchSyncIsPeriodic))
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

    /// `perform(_:)` with `appeared` checks if the user's KDF settings need to be updated and logs
    /// an error and shows an alert if updating the settings fails.
    @MainActor
    func test_perform_appeared_checkIfForceKdfUpdateRequired_error() async throws {
        changeKdfService.needsKdfUpdateToMinimumsResult = true
        changeKdfService.updateKdfToMinimumsResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = .fixture()

        await subject.perform(.appeared)

        XCTAssertTrue(changeKdfService.needsKdfUpdateToMinimumsCalled)

        let updateEncryptionSettingsAlert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(updateEncryptionSettingsAlert, .updateEncryptionSettings { _ in })

        try updateEncryptionSettingsAlert.setText("password123!", forTextFieldWithId: "password")
        try await updateEncryptionSettingsAlert.tapAction(title: Localizations.submit)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `perform(_:)` with `appeared` checks if the user's KDF settings need to be updated and does
    /// nothing if they already meet the minimums.
    @MainActor
    func test_perform_appeared_checkIfForceKdfUpdateRequired_false() async {
        notificationService.authorizationStatus = .denied
        stateService.activeAccount = .fixture()

        await subject.perform(.appeared)

        XCTAssertTrue(changeKdfService.needsKdfUpdateToMinimumsCalled)
        XCTAssertFalse(changeKdfService.updateKdfToMinimumsCalled)
        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `appeared` checks if the user's KDF settings need to be updated and
    /// shows an alert asking the user for their master password to update the KDF settings.
    @MainActor
    func test_perform_appeared_checkIfForceKdfUpdateRequired_true() async throws {
        changeKdfService.needsKdfUpdateToMinimumsResult = true
        stateService.activeAccount = .fixture()

        await subject.perform(.appeared)

        XCTAssertTrue(changeKdfService.needsKdfUpdateToMinimumsCalled)

        let updateEncryptionSettingsAlert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(updateEncryptionSettingsAlert, .updateEncryptionSettings { _ in })

        try await updateEncryptionSettingsAlert.tapCancel()
        XCTAssertFalse(changeKdfService.updateKdfToMinimumsCalled)

        try updateEncryptionSettingsAlert.setText("password123!", forTextFieldWithId: "password")
        try await updateEncryptionSettingsAlert.tapAction(title: Localizations.submit)

        XCTAssertTrue(changeKdfService.updateKdfToMinimumsCalled)
        XCTAssertEqual(changeKdfService.updateKdfToMinimumsPassword, "password123!")
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.updating)])
        XCTAssertEqual(coordinator.toastsShown, [Toast(title: Localizations.encryptionSettingsUpdated)])
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
            timeProvider.presentTime.addingTimeInterval(-86399),
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
            [.allVaults, .myVault, .organization(.fixture())],
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
            notificationService.requestedOptions,
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
            notificationService.requestedOptions,
        )
        XCTAssertTrue(application.registerForRemoteNotificationsCalled)
        XCTAssertEqual(stateService.notificationsLastRegistrationDates["1"], timeProvider.presentTime)
    }

    /// `perform(_:)` with `.dismissFlightRecorderToastBanner` hides the flight recorder toast banner.
    @MainActor
    func test_perform_dismissFlightRecorderToastBanner() async {
        stateService.activeAccount = .fixture()

        await subject.perform(.dismissFlightRecorderToastBanner)

        XCTAssertTrue(flightRecorder.setFlightRecorderBannerDismissedCalled)
    }

    /// `perform(_:)` with `.dismissImportLoginsActionCard` sets the user's import logins setup
    /// progress to complete.
    @MainActor
    func test_perform_dismissSetUpUnlockActionCard() async {
        stateService.activeAccount = .fixture()
        stateService.accountSetupImportLogins["1"] = .incomplete

        await subject.perform(.dismissImportLoginsActionCard)

        XCTAssertEqual(stateService.accountSetupImportLogins["1"], .setUpLater)
    }

    /// `perform(_:)` with `.dismissImportLoginsActionCard` logs an error and shows an alert if an
    /// error occurs.
    @MainActor
    func test_perform_dismissSetUpUnlockActionCard_error() async {
        await subject.perform(.dismissImportLoginsActionCard)

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(error: StateServiceError.noActiveAccount)])
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
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

    /// `perform(_:)` with `.refreshed` requests a fetch sync update, but does not force a sync.
    @MainActor
    func test_perform_refresh() async {
        await subject.perform(.refreshVault)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
        XCTAssertFalse(try XCTUnwrap(vaultRepository.fetchSyncIsPeriodic))
        XCTAssertEqual(vaultRepository.fetchSyncForceSync, false)
    }

    /// `perform(_:)` with `.refreshVault` requests a vault sync and sets the loading state if the
    /// vault is empty; in this case sync is not flagged as periodic.
    @MainActor
    func test_perform_refreshVault_emptyVault() async {
        vaultRepository.isVaultEmptyResult = .success(true)

        await subject.perform(.refreshVault)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
        XCTAssertFalse(try XCTUnwrap(vaultRepository.fetchSyncIsPeriodic))
        XCTAssertEqual(vaultRepository.fetchSyncForceSync, false)
        XCTAssertEqual(subject.state.loadingState, .data([]))
    }

    /// `perform(_:)` with `.refreshed` records an error and change the loading state
    /// to `.error` if there is no cached data.
    @MainActor
    func test_perform_refreshed_error_emptyState() async {
        vaultRepository.fetchSyncResult = .failure(BitwardenTestError.example)
        vaultRepository.needsSyncResult = .success(true)
        await subject.perform(.refreshVault)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
        XCTAssertNil(coordinator.alertShown.last)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
        XCTAssertEqual(
            subject.state.loadingState,
            .error(
                errorMessage: Localizations.weAreUnableToProcessYourRequestPleaseTryAgainOrContactUs,
            ),
        )
    }

    /// `perform(_:)` with `.refreshed` records an error and shows an alert to user if there is cached data.
    @MainActor
    func test_perform_refreshed_error_nonEmptyState() async {
        let section = VaultListSection(id: "1", items: [.fixture()], name: "Section")
        subject.state.loadingState = .data([section])
        vaultRepository.fetchSyncResult = .failure(BitwardenTestError.example)
        vaultRepository.needsSyncResult = .success(true)
        await subject.perform(.refreshVault)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
        XCTAssertEqual(subject.state.loadingState, .data([section]))
    }

    /// `perform(_:)` with `.refreshed` records an error and shows alert if it does not need sync.
    @MainActor
    func test_perform_refreshed_error_doesNotNeedsSync() async {
        let section = VaultListSection(id: "1", items: [.fixture()], name: "Section")
        subject.state.loadingState = .data([section])
        vaultRepository.fetchSyncResult = .failure(BitwardenTestError.example)
        vaultRepository.needsSyncResult = .success(false)
        await subject.perform(.refreshVault)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
        XCTAssertEqual(subject.state.loadingState, .data([section]))
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
            isVisible: false,
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
            isVisible: false,
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
            isVisible: false,
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
            isVisible: false,
        )
        await subject.perform(.refreshAccountProfiles)

        XCTAssertEqual([profile2], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile1, subject.state.profileSwitcherState.activeAccountProfile)
    }

    /// `perform(_:)` with `.requestedProfileSwitcher(visible:)` updates the state correctly.
    @MainActor
    func test_perform_requestedProfileSwitcher() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25906 - Backfill tests for new account switcher
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }

        let annAccount = ProfileSwitcherItem.anneAccount
        let beeAccount = ProfileSwitcherItem.beeAccount

        subject.state.profileSwitcherState.accounts = [annAccount, beeAccount]
        subject.state.profileSwitcherState.isVisible = false

        authRepository.profileSwitcherState = ProfileSwitcherState.maximumAccounts
        await subject.perform(.profileSwitcher(.requestedProfileSwitcher(visible: true)))

        // Ensure that the profile switcher state is updated
        waitFor(subject.state.profileSwitcherState == authRepository.profileSwitcherState)
        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
        XCTAssertTrue(authRepository.checkSessionTimeoutCalled)
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
            isVisible: true,
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
            isVisible: true,
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
            isVisible: true,
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
    func test_perform_search() {
        let searchResult: [CipherListView] = [.fixture(name: "example")]
        vaultRepository.vaultListSubject.value = VaultListData(sections: [
            VaultListSection(
                id: "",
                items: searchResult.compactMap { VaultListItem(cipherListView: $0) },
                name: "",
            ),
        ])
        let task = Task {
            await subject.perform(.search("example"))
        }

        waitFor(!subject.state.searchResults.isEmpty)
        XCTAssertEqual(
            subject.state.searchResults,
            try [VaultListItem.fixture(cipherListView: XCTUnwrap(searchResult.first))],
        )

        task.cancel()
    }

    /// `perform(.search)` throws error and error is logged.
    @MainActor
    func test_perform_search_error() async {
        vaultRepository.vaultListSubject.send(completion: .failure(BitwardenTestError.example))
        await subject.perform(.search("example"))

        XCTAssertEqual(subject.state.searchResults.count, 0)
        XCTAssertEqual(
            subject.state.searchResults,
            [],
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
            [],
        )
    }

    /// `perform(_:)` with `.streamAccountSetupProgress` updates the state's import logins process
    /// whenever it changes.
    @MainActor
    func test_perform_streamAccountSetupProgress() {
        stateService.activeAccount = .fixture()

        let task = Task {
            await subject.perform(.streamAccountSetupProgress)
        }
        defer { task.cancel() }

        let badgeState = SettingsBadgeState.fixture(importLoginsSetupProgress: .complete)
        stateService.settingsBadgeSubject.send(badgeState)
        waitFor { subject.state.importLoginsSetupProgress == .complete }

        XCTAssertEqual(subject.state.importLoginsSetupProgress, .complete)
    }

    /// `perform(_:)` with `.streamAccountSetupProgress` logs an error if streaming the account
    /// setup progress fails.
    @MainActor
    func test_perform_streamAccountSetupProgress_error() async {
        await subject.perform(.streamAccountSetupProgress)

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `perform(_:)` with `.streamFlightRecorderLog` streams the flight recorder log and displays
    /// the flight recorder banner if the user hasn't dismissed it previously.
    @MainActor
    func test_perform_streamFlightRecorderLog() async throws {
        stateService.activeAccount = .fixture()

        let task = Task {
            await subject.perform(.streamFlightRecorderLog)
        }
        defer { task.cancel() }

        flightRecorder.activeLogSubject.send(FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now))
        try await waitForAsync { self.subject.state.flightRecorderToastBanner.isToastBannerVisible }
        XCTAssertEqual(subject.state.flightRecorderToastBanner.isToastBannerVisible, true)

        flightRecorder.activeLogSubject.send(nil)
        try await waitForAsync { !self.subject.state.flightRecorderToastBanner.isToastBannerVisible }
        XCTAssertEqual(subject.state.flightRecorderToastBanner.isToastBannerVisible, false)
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

    /// `perform(_:)` with `.streamVaultList` displays an alert if the vault has any cipher
    /// decryption failures.
    @MainActor
    func test_perform_streamVaultList_cipherDecryptionFailure() async throws {
        stateService.activeAccount = .fixture()

        let task = Task {
            await subject.perform(.streamVaultList)
        }
        defer { task.cancel() }

        vaultRepository.vaultListSubject.send(
            VaultListData(cipherDecryptionFailureIds: ["1", "2"], sections: []),
        )

        try await waitForAsync { !self.coordinator.alertShown.isEmpty }
        XCTAssertEqual(
            coordinator.alertShown.last,
            .cipherDecryptionFailure(cipherIds: ["1", "2"], isFromCipherTap: false) { _ in },
        )
        try await coordinator.alertShown.last?.tapAction(title: Localizations.copyErrorReport)
        XCTAssertEqual(
            pasteboardService.copiedString,
            """
            \(Localizations.decryptionError)
            \(Localizations.bitwardenCouldNotDecryptXVaultItemsDescriptionLong(2))

            1
            2
            """,
        )
        XCTAssertTrue(subject.hasShownCipherDecryptionFailureAlert)

        // As more data is published, the alert isn't shown again.
        coordinator.alertShown.removeAll()
        vaultRepository.vaultListSubject.send(
            VaultListData(
                cipherDecryptionFailureIds: ["1", "2"],
                sections: [VaultListSection(id: "", items: [.fixture()], name: "")],
            ),
        )
        try await waitForAsync { self.subject.state.loadingState.data?.isEmpty == false }
        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.streamVaultList` dismisses the coach marks if the vault contains any
    /// login items.
    @MainActor
    func test_perform_streamVaultList_coachMarkDismiss_vaultContainsLogins() async throws {
        stateService.activeAccount = .fixture()

        let task = Task {
            await subject.perform(.streamVaultList)
        }
        defer { task.cancel() }

        let section = VaultListSection(
            id: "1",
            items: [.fixtureGroup(id: "1", group: .login, count: 1)],
            name: "Section",
        )
        vaultRepository.vaultListSubject.send(VaultListData(sections: [section]))

        try await waitForAsync { self.subject.state.loadingState == .data([section]) }
        XCTAssertEqual(stateService.learnGeneratorActionCardStatus, .complete)
        XCTAssertEqual(stateService.learnNewLoginActionCardStatus, .complete)
    }

    /// `perform(_:)` with `.streamVaultList` doesn't dismiss the coach marks if the vault contains
    /// no login items.
    @MainActor
    func test_perform_streamVaultList_coachMarkDismiss_vaultWithoutLogins() async throws {
        stateService.activeAccount = .fixture()

        let task = Task {
            await subject.perform(.streamVaultList)
        }
        defer { task.cancel() }

        let section = VaultListSection(
            id: "1",
            items: [.fixtureGroup(id: "1", group: .card, count: 1)],
            name: "Section",
        )
        vaultRepository.vaultListSubject.send(VaultListData(sections: [section]))

        try await waitForAsync { self.subject.state.loadingState == .data([section]) }
        XCTAssertNil(stateService.learnGeneratorActionCardStatus)
        XCTAssertNil(stateService.learnNewLoginActionCardStatus)
    }

    /// `perform(_:)` with `.streamVaultList` updates the state's vault list whenever it changes.
    @MainActor
    func test_perform_streamVaultList_doesntNeedSync() throws {
        let vaultListItem = VaultListItem.fixture()
        vaultRepository.vaultListSubject.send(VaultListData(
            sections: [
                VaultListSection(
                    id: "1",
                    items: [vaultListItem],
                    name: "Name",
                ),
            ],
        ))

        let task = Task {
            await subject.perform(.streamVaultList)
        }

        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        let sections = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].items, [vaultListItem])
    }

    /// `perform(_:)` with `.streamVaultList` dismisses the import logins action card if the
    /// vault list isn't empty.
    @MainActor
    func test_perform_streamVaultList_dismissImportLoginsActionCard() async throws {
        stateService.activeAccount = .fixture()
        stateService.accountSetupImportLogins["1"] = .incomplete

        let task = Task {
            await subject.perform(.streamVaultList)
        }
        defer { task.cancel() }

        let section = VaultListSection(id: "1", items: [.fixture()], name: "Section")
        vaultRepository.vaultListSubject.send(VaultListData(sections: [section]))
        try await waitForAsync { self.subject.state.loadingState == .data([section]) }

        XCTAssertEqual(stateService.accountSetupImportLogins["1"], .complete)
    }

    /// `perform(_:)` with `.streamVaultList` doesn't dismiss the import logins action card if the
    /// vault list is empty.
    @MainActor
    func test_perform_streamVaultList_emptyImportLoginsActionCard() async throws {
        stateService.activeAccount = .fixture()
        stateService.accountSetupImportLogins["1"] = .incomplete

        let task = Task {
            await subject.perform(.streamVaultList)
        }
        defer { task.cancel() }

        vaultRepository.vaultListSubject.send(VaultListData(sections: []))
        try await waitForAsync { self.subject.state.loadingState == .data([]) }

        XCTAssertEqual(stateService.accountSetupImportLogins["1"], .incomplete)
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

        vaultRepository.vaultListSubject.send(VaultListData(sections: []))
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

        vaultRepository.vaultListSubject.send(VaultListData(
            sections: [
                VaultListSection(
                    id: "1",
                    items: [vaultListItem],
                    name: "Name",
                ),
            ],
        ))
        waitFor(subject.state.loadingState != .loading(nil))
        task.cancel()

        let sections = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].items, [vaultListItem])
    }

    /// `perform(_:)` with `.tryAgainTapped` will reset the loading state to `.loading(nil)`.
    @MainActor
    func test_perform_tryAgain() async throws {
        subject.state.loadingState = .error(errorMessage: "error")
        vaultRepository.needsSyncResult = .success(false)
        vaultRepository.fetchSyncResult = .failure(BitwardenTestError.example)
        let task = Task {
            await subject.perform(.tryAgainTapped)
        }
        defer { task.cancel() }
        try await waitForAsync { self.subject.state.loadingState == .loading(nil) }
        XCTAssertTrue(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.tryAgainTapped` will fetch the data again and set the state to '.data(sections)'
    @MainActor
    func test_perform_tryAgain_success() async throws {
        let section = VaultListSection(id: "1", items: [.fixture()], name: "Section")
        subject.state.loadingState = .error(errorMessage: "error")
        vaultRepository.fetchSyncResult = .success(())

        await subject.perform(.tryAgainTapped)
        let task = Task {
            await subject.perform(.streamVaultList)
        }
        defer { task.cancel() }
        vaultRepository.vaultListSubject.send(VaultListData(sections: [section]))

        try await waitForAsync { self.subject.state.loadingState == .data([section]) }
        XCTAssertTrue(vaultRepository.fetchSyncCalled)
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` shows the alert and allows the user to
    /// lock the selected account, which navigates back to the vault unlock page for the active account.
    @MainActor
    func test_receive_accountLongPressed_lock_activeAccount() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25906 - Backfill tests for new account switcher
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }

        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture(isUnlocked: true, userId: "1")
        let otherProfile = ProfileSwitcherItem.fixture(isUnlocked: true, userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true,
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
        XCTAssertEqual(coordinator.events.last, .lockVault(userId: activeProfile.userId, isManuallyLocking: true))
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` shows the alert and allows the user to
    /// lock the selected account, which displays a toast.
    @MainActor
    func test_receive_accountLongPressed_lock_otherAccount() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25906 - Backfill tests for new account switcher
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }

        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture(userId: "1")
        let otherProfile = ProfileSwitcherItem.fixture(isUnlocked: true, userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true,
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
        XCTAssertEqual(coordinator.events.last, .lockVault(userId: otherProfile.userId, isManuallyLocking: true))
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.accountLockedSuccessfully))
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` records any errors from locking the account.
    @MainActor
    func test_receive_accountLongPressed_lock_error() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25906 - Backfill tests for new account switcher
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }

        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture(userId: "1")
        let otherProfile = ProfileSwitcherItem.fixture(isUnlocked: true, userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true,
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
        guard #unavailable(iOS 26) else {
            // TODO: PM-25906 - Backfill tests for new account switcher
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }

        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture(userId: "1")
        let otherProfile = ProfileSwitcherItem.fixture(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true,
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
        guard #unavailable(iOS 26) else {
            // TODO: PM-25906 - Backfill tests for new account switcher
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }

        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture()
        let otherProfile = ProfileSwitcherItem.fixture(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true,
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
            .logout(userId: otherProfile.userId, userInitiated: true),
        )
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.accountLoggedOutSuccessfully))
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` records any errors from logging out the
    /// account.
    @MainActor
    func test_receive_accountLongPressed_logout_error() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25906 - Backfill tests for new account switcher
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }

        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture()
        let otherProfile = ProfileSwitcherItem.fixture(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true,
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
    func test_receive_accountPressed() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25906 - Backfill tests for new account switcher
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }

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

    /// `receive(_:)` with `.addFolder` navigates to the `.addFolder` route.
    @MainActor
    func test_receive_addFolder() {
        subject.receive(.addFolder)

        XCTAssertEqual(coordinator.routes.last, .addFolder)
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route.
    @MainActor
    func test_receive_addItemPressed() {
        subject.receive(.addItemPressed(.login))

        XCTAssertEqual(coordinator.routes.last, .addItem(type: .login))
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route for a new secure note.
    @MainActor
    func test_receive_addItemPressed_secureNote() {
        subject.receive(.addItemPressed(.secureNote))

        XCTAssertEqual(coordinator.routes.last, .addItem(type: .secureNote))
    }

    /// `receive(_:)` with `.addItemPressed` hides the profile switcher view
    @MainActor
    func test_receive_addItemPressed_hideProfiles() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.addItemPressed(.login))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(.addItemPressed)` cancels the review prompt task.
    @MainActor
    func test_receive_addItemPressed_cancelsReviewPromptTask() async {
        reviewPromptService.isEligibleForReviewPromptResult = true
        await subject.perform(.checkAppReviewEligibility)
        waitFor(subject.reviewPromptTask != nil)
        subject.receive(.addItemPressed(.login))
        XCTAssertTrue(subject.reviewPromptTask!.isCancelled)
    }

    /// `receive(_:)` with `.addItemPressed` when an organization was selected in the filter navigates
    /// to the `.addItem` route with the corresponding organization id.
    @MainActor
    func test_receive_addItemPressed_organizationSelected() {
        subject.state.vaultFilterType = .organization(Organization.fixture())

        subject.receive(.addItemPressed(.login))

        XCTAssertEqual(coordinator.routes.last, .addItem(organizationId: "organization-1", type: .login))
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

    /// `receive(.disappeared)` cancels the review prompt task.
    @MainActor
    func test_receive_disappeared() async {
        reviewPromptService.isEligibleForReviewPromptResult = true
        await subject.perform(.checkAppReviewEligibility)
        waitFor(subject.reviewPromptTask != nil)
        subject.receive(.disappeared)
        XCTAssertTrue(subject.reviewPromptTask!.isCancelled)
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.viewItem` route for a cipher.
    @MainActor
    func test_receive_itemPressed_cipher() async throws {
        let cipherListView = CipherListView.fixture()
        let item = VaultListItem.fixture(cipherListView: cipherListView)

        subject.receive(.itemPressed(item: item))
        try await waitForAsync { !self.coordinator.routes.isEmpty }

        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id, masterPasswordRepromptCheckCompleted: true))
        XCTAssertEqual(masterPasswordRepromptHelper.repromptForMasterPasswordCipherListView, cipherListView)
    }

    /// `receive(_:)` with `.itemPressed` shows an alert when tapping on a cipher which failed to decrypt.
    @MainActor
    func test_receive_itemPressed_cipherDecryptionFailure() async throws {
        let cipherListView = CipherListView.fixture(name: Localizations.errorCannotDecrypt)
        let item = VaultListItem.fixture(cipherListView: cipherListView)

        subject.receive(.itemPressed(item: item))

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

    /// `receive(_:)` with `.itemPressed` navigates to the `.group` route for a group.
    @MainActor
    func test_receive_itemPressed_group() {
        subject.receive(.itemPressed(item: VaultListItem(id: "1", itemType: .group(.card, 1))))

        XCTAssertEqual(coordinator.routes.last, .group(.card, filter: .allVaults))
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.totp` route for a totp code.
    @MainActor
    func test_receive_itemPressed_totp() async throws {
        let cipherListView = CipherListView.fixture()
        let totpItem = VaultListItem.fixtureTOTP(totp: .fixture(cipherListView: cipherListView))

        subject.receive(.itemPressed(item: totpItem))
        try await waitForAsync { !self.coordinator.routes.isEmpty }

        XCTAssertEqual(coordinator.routes.last, .viewItem(id: "123", masterPasswordRepromptCheckCompleted: true))
        XCTAssertEqual(masterPasswordRepromptHelper.repromptForMasterPasswordCipherListView, cipherListView)
    }

    /// `receive(_:)` with `.navigateToFlightRecorderSettings` navigates to the flight recorder settings.
    @MainActor
    func test_receive_navigateToFlightRecorderSettings() {
        subject.receive(.navigateToFlightRecorderSettings)

        XCTAssertEqual(coordinator.routes.last, .flightRecorderSettings)
    }

    /// `receive(_:)` with `ProfileSwitcherAction.backgroundPressed` turns off the Profile Switcher Visibility.
    @MainActor
    func test_receive_profileSwitcherBackgroundPressed() throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25906 - Backfill tests for new account switcher
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }

        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.profileSwitcher(.backgroundTapped))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
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
        subject.state.organizations = [organization]
        subject.state.searchVaultFilterType = .myVault

        subject.receive(.searchVaultFilterChanged(.organization(organization)))

        XCTAssertEqual(subject.state.searchVaultFilterType, .organization(organization))
        XCTAssertEqual(
            subject.state.searchVaultFilterState,
            SearchVaultFilterRowState(
                canShowVaultFilter: true,
                isPersonalOwnershipDisabled: false,
                organizations: [organization],
                searchVaultFilterType: .organization(organization),
            ),
        )
    }

    /// `receive(_:)` with `showImportLogins(:)` has the coordinator navigate to the import logins
    /// screen.
    @MainActor
    func test_receive_showImportLogins() throws {
        subject.receive(.showImportLogins)

        XCTAssertEqual(coordinator.routes, [.importLogins])
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
        subject.state.organizations = [organization]
        subject.state.vaultFilterType = .myVault

        subject.receive(.vaultFilterChanged(.organization(organization)))

        XCTAssertEqual(subject.state.vaultFilterType, .organization(organization))
        XCTAssertEqual(
            subject.state.vaultFilterState,
            SearchVaultFilterRowState(
                canShowVaultFilter: true,
                isPersonalOwnershipDisabled: false,
                organizations: [organization],
                searchVaultFilterType: .organization(organization),
            ),
        )
    }

    // MARK: ProfileSwitcherHandler

    /// `dismissProfileSwitcher` calls the coordinator to dismiss the profile switcher.
    @MainActor
    func test_dismissProfileSwitcher() {
        subject.dismissProfileSwitcher()

        XCTAssertEqual(coordinator.routes, [.dismiss])
    }

    /// `showProfileSwitcher` calls the coordinator to show the profile switcher.
    @MainActor
    func test_showProfileSwitcher() {
        subject.showProfileSwitcher()

        XCTAssertEqual(coordinator.routes, [.viewProfileSwitcher])
    }
}
