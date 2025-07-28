import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// swiftlint:disable file_length

// MARK: - VaultListProcessor

/// The processor used to manage state and handle actions for the vault list screen.
///
final class VaultListProcessor: StateProcessor<
    VaultListState,
    VaultListAction,
    VaultListEffect
> {
    // MARK: Types

    typealias Services = HasApplication
        & HasAuthRepository
        & HasAuthService
        & HasErrorReporter
        & HasEventService
        & HasFlightRecorder
        & HasNotificationService
        & HasPasteboardService
        & HasPolicyService
        & HasReviewPromptService
        & HasStateService
        & HasTimeProvider
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<VaultRoute, AuthAction>

    /// Whether the cipher decryption failure alert was shown to the user, if the vault has any
    /// ciphers which failed to decrypt.
    private(set) var hasShownCipherDecryptionFailureAlert = false

    /// The helper to handle master password reprompts.
    private let masterPasswordRepromptHelper: MasterPasswordRepromptHelper

    /// The task that schedules the app review prompt.
    private(set) var reviewPromptTask: Task<Void, Never>?

    /// The services used by this processor.
    private let services: Services

    /// The helper to handle the more options menu for a vault item.
    private let vaultItemMoreOptionsHelper: VaultItemMoreOptionsHelper

    // MARK: Initialization

    /// Creates a new `VaultListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - masterPasswordRepromptHelper: The helper to handle master password reprompts.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///   - vaultItemMoreOptionsHelper: The helper to handle the more options menu for a vault item.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
        masterPasswordRepromptHelper: MasterPasswordRepromptHelper,
        services: Services,
        state: VaultListState,
        vaultItemMoreOptionsHelper: VaultItemMoreOptionsHelper
    ) {
        self.coordinator = coordinator
        self.masterPasswordRepromptHelper = masterPasswordRepromptHelper
        self.services = services
        self.vaultItemMoreOptionsHelper = vaultItemMoreOptionsHelper
        super.init(state: state)
    }

    deinit {
        reviewPromptTask?.cancel()
    }

    // MARK: Methods

    override func perform(_ effect: VaultListEffect) async {
        switch effect {
        case .appeared:
            await appeared()
        case .checkAppReviewEligibility:
            if await services.reviewPromptService.isEligibleForReviewPrompt() {
                await scheduleReviewPrompt()
            } else {
                state.isEligibleForAppReview = false
            }
        case .dismissFlightRecorderToastBanner:
            await dismissFlightRecorderToastBanner()
        case .dismissImportLoginsActionCard:
            await setImportLoginsProgress(.setUpLater)
        case let .morePressed(item):
            await vaultItemMoreOptionsHelper.showMoreOptionsAlert(
                for: item,
                handleDisplayToast: { [weak self] toast in
                    self?.state.toast = toast
                },
                handleOpenURL: { [weak self] url in
                    self?.state.url = url
                }
            )
        case let .profileSwitcher(profileEffect):
            await handleProfileSwitcherEffect(profileEffect)
        case .refreshAccountProfiles:
            await refreshProfileState()
        case .refreshVault:
            await refreshVault(syncWithPeriodicCheck: false)
        case let .search(text):
            state.searchResults = await searchVault(for: text)
        case .streamAccountSetupProgress:
            await streamAccountSetupProgress()
        case .streamFlightRecorderLog:
            await streamFlightRecorderLog()
        case .streamOrganizations:
            await streamOrganizations()
        case .streamShowWebIcons:
            for await value in await services.stateService.showWebIconsPublisher().values {
                state.showWebIcons = value
            }
        case .streamVaultList:
            await streamVaultList()
        case .tryAgainTapped:
            state.loadingState = .loading(nil)
            await appeared()
        }
    }

    override func receive(_ action: VaultListAction) {
        switch action {
        case .addFolder:
            coordinator.navigate(to: .addFolder)
        case let .addItemPressed(type):
            addItem(type: type)
        case .clearURL:
            state.url = nil
        case .copyTOTPCode:
            break
        case .disappeared:
            reviewPromptTask?.cancel()
        case let .itemPressed(item):
            handleItemTapped(item)
        case .navigateToFlightRecorderSettings:
            coordinator.navigate(to: .flightRecorderSettings)
        case let .profileSwitcher(profileAction):
            handleProfileSwitcherAction(profileAction)
        case let .searchStateChanged(isSearching: isSearching):
            guard isSearching else {
                state.searchText = ""
                state.searchResults = []
                return
            }
            state.profileSwitcherState.isVisible = !isSearching
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .searchVaultFilterChanged(newValue):
            state.searchVaultFilterType = newValue
        case .appReviewPromptShown:
            state.isEligibleForAppReview = false
            Task {
                await services.reviewPromptService.setReviewPromptShownVersion()
                await services.reviewPromptService.clearUserActions()
            }
        case .showImportLogins:
            coordinator.navigate(to: .importLogins)
        case let .toastShown(newValue):
            state.toast = newValue
        case .totpCodeExpired:
            // No-op: TOTP codes aren't shown on the list view and can't be copied.
            break
        case let .vaultFilterChanged(newValue):
            state.vaultFilterType = newValue
        }
    }
}

extension VaultListProcessor {
    // MARK: Private Methods

    /// Navigates to the add vault item screen.
    ///
    /// - Parameter type: The type of vault item to add.
    ///
    private func addItem(type: CipherType) {
        setProfileSwitcher(visible: false)
        switch state.vaultFilterType {
        case let .organization(organization):
            coordinator.navigate(to: .addItem(organizationId: organization.id, type: type))
        default:
            coordinator.navigate(to: .addItem(type: type))
        }
        reviewPromptTask?.cancel()
    }

    /// Called when the vault list appears on screen.
    private func appeared() async {
        await refreshVault(syncWithPeriodicCheck: true)
        await handleNotifications()
        await checkPendingLoginRequests()
        await checkPersonalOwnershipPolicy()
        await loadItemTypesUserCanCreate()
    }

    /// Check if there are any pending login requests for the user to deal with.
    private func checkPendingLoginRequests() async {
        do {
            // If the user had previously received a notification for a login request
            // but hasn't been able to view it yet, open the request now.
            let userId = try await services.stateService.getActiveAccountId()
            if let loginRequestData = await services.stateService.getLoginRequest(),
               loginRequestData.userId == userId {
                // Show the login request if it's still valid.
                if let loginRequest = try await services.authService.getPendingLoginRequest(withId: loginRequestData.id)
                    .first,
                    !loginRequest.isAnswered,
                    !loginRequest.isExpired {
                    coordinator.navigate(to: .loginRequest(loginRequest))
                }

                // Since the request has been handled, remove it from local storage.
                await services.stateService.setLoginRequest(nil)
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Checks if the personal ownership policy is enabled.
    ///
    private func checkPersonalOwnershipPolicy() async {
        let isPersonalOwnershipDisabled = await services.policyService.policyAppliesToUser(.personalOwnership)
        state.isPersonalOwnershipDisabled = isPersonalOwnershipDisabled
        state.canShowVaultFilter = await services.vaultRepository.canShowVaultFilter()
    }

    /// Checks available item types user can create.
    ///
    private func loadItemTypesUserCanCreate() async {
        state.itemTypesUserCanCreate = await services.vaultRepository.getItemTypesUserCanCreate()
    }

    /// Dismisses the flight recorder toast banner for the active user.
    ///
    private func dismissFlightRecorderToastBanner() async {
        state.isFlightRecorderToastBannerVisible = false
        await services.flightRecorder.setFlightRecorderBannerDismissed()
    }

    /// If the vault has ciphers which failed to decrypt, and the cipher decryption failure alert
    /// hasn't been shown yet, notify the user that a cipher(s) failed to decrypt.
    ///
    /// - Parameter cipherIds: The list of identifiers for ciphers which failed to decrypt.
    ///
    private func handleCipherDecryptionFailures(cipherIds: [Uuid]) {
        guard !cipherIds.isEmpty, !hasShownCipherDecryptionFailureAlert else { return }
        coordinator.showAlert(.cipherDecryptionFailure(cipherIds: cipherIds, isFromCipherTap: false) { stringToCopy in
            self.services.pasteboardService.copy(stringToCopy)
        })
        hasShownCipherDecryptionFailureAlert = true
    }

    /// Handles the primary action for when a `VaultListItem` is tapped in the list.
    ///
    /// - Parameter item: The `VaultListItem` that was tapped.
    ///
    private func handleItemTapped(_ item: VaultListItem) {
        switch item.itemType {
        case let .cipher(cipherListView, _):
            if cipherListView.isDecryptionFailure, let cipherId = cipherListView.id {
                coordinator.showAlert(.cipherDecryptionFailure(cipherIds: [cipherId]) { stringToCopy in
                    self.services.pasteboardService.copy(stringToCopy)
                })
            } else {
                navigateToViewItem(cipherListView: cipherListView, id: item.id)
            }
        case let .group(group, _):
            coordinator.navigate(to: .group(group, filter: state.vaultFilterType))
        case let .totp(_, model):
            navigateToViewItem(cipherListView: model.cipherListView, id: model.id)
        }
    }

    /// Entry point to handling things around push notifications.
    private func handleNotifications() async {
        switch await services.notificationService.notificationAuthorization() {
        case .authorized:
            await registerForNotifications()
        case .notDetermined:
            await requestNotificationPermissions()
        default:
            break
        }
    }

    /// Navigates to the view item view for the specified cipher. If the cipher requires master
    /// password reprompt, this will prompt the user before navigation.
    ///
    /// - Parameters:
    ///     - cipherListView: The cipher list view item for the cipher that will be shown in the view item view.
    ///     - id: The cipher's identifier.
    ///
    private func navigateToViewItem(cipherListView: CipherListView, id: String) {
        Task {
            await masterPasswordRepromptHelper.repromptForMasterPasswordIfNeeded(cipherListView: cipherListView) {
                self.coordinator.navigate(to: .viewItem(id: id, masterPasswordRepromptCheckCompleted: true))
            }
        }
    }

    /// Refreshes the vault's contents.
    ///
    /// - Parameter syncWithPeriodicCheck: Whether the sync should take into consideration
    /// the periodic check.
    private func refreshVault(syncWithPeriodicCheck: Bool) async {
        do {
            let takingTimeTask = Task {
                try await Task.sleep(forSeconds: 5)
                // If we already have data, don't show the toast
                guard case .loading = self.state.loadingState else { return }
                self.state.toast = Toast(title: Localizations.thisIsTakingLongerThanExpected, mode: .manualDismiss)
            }
            defer {
                state.toast = nil
                takingTimeTask.cancel()
            }

            try await services.vaultRepository.fetchSync(
                forceSync: false,
                filter: state.vaultFilterType,
                isPeriodic: syncWithPeriodicCheck
            )

            if try await services.vaultRepository.isVaultEmpty() {
                // Normally after syncing the database will publish the contents of the vault which is
                // used to transition from the loading to loaded state. If the vault is empty, nothing
                // will be published by the database, so it needs to be manually updated.
                state.loadingState = .data([])
            }
        } catch URLError.cancelled {
            // No-op: don't log or alert for cancellation errors.
        } catch {
            services.errorReporter.log(error: error)

            let needsSync = try? await services.vaultRepository.needsSync()
            if needsSync == true {
                // If the vault needs a sync and there are cached items,
                // display the cached data and show an error alert.
                if let sections = state.loadingState.data, !sections.isEmpty {
                    await coordinator.showErrorAlert(error: error)
                } else {
                    // If the vault needs a sync and there were no cached items,
                    // show the full screen error view.
                    state.loadingState = .error(
                        errorMessage: Localizations.weAreUnableToProcessYourRequestPleaseTryAgainOrContactUs
                    )
                }
            } else {
                await coordinator.showErrorAlert(error: error)
            }
        }
    }

    /// Attempts to register the device for push notifications.
    /// We only need to register once a day.
    private func registerForNotifications() async {
        do {
            let lastReg = try await services.stateService.getNotificationsLastRegistrationDate() ?? Date.distantPast
            if services.timeProvider.timeSince(lastReg) >= 86400 { // One day
                services.application?.registerForRemoteNotifications()
                try await services.stateService.setNotificationsLastRegistrationDate(services.timeProvider.presentTime)
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Request permission to send push notifications.
    private func requestNotificationPermissions() async {
        // Show the explanation alert before asking for permissions.
        coordinator.showAlert(
            .pushNotificationsInformation { [services] in
                do {
                    let authorized = try await services.notificationService
                        .requestAuthorization(options: [.alert, .sound, .badge])
                    if authorized {
                        await self.registerForNotifications()
                    }
                } catch {
                    self.services.errorReporter.log(error: error)
                }
            }
        )
    }

    /// Searches the vault using the provided string, and returns any matching results.
    ///
    /// - Parameter searchText: The string to use when searching the vault.
    /// - Returns: An array of `VaultListItem`s. If no results can be found, an empty array will be returned.
    ///
    private func searchVault(for searchText: String) async -> [VaultListItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        do {
            let result = try await services.vaultRepository.searchVaultListPublisher(
                searchText: searchText,
                filter: VaultListFilter(filterType: state.searchVaultFilterType)
            )
            for try await ciphers in result {
                return ciphers
            }
        } catch {
            services.errorReporter.log(error: error)
        }
        return []
    }

    /// Sets the user's import logins progress.
    ///
    /// - Parameter progress: The user's import logins progress.
    ///
    private func setImportLoginsProgress(_ progress: AccountSetupProgress) async {
        do {
            try await services.stateService.setAccountSetupImportLogins(progress)
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(error: error))
        }
    }

    /// Sets the visibility of the profiles view and updates accessibility focus.
    ///
    /// - Parameter visible: the intended visibility of the view.
    ///
    private func setProfileSwitcher(visible: Bool) {
        if !visible {
            state.profileSwitcherState.hasSetAccessibilityFocus = false
        }
        state.profileSwitcherState.isVisible = visible
    }

    /// Triggers the app review prompt after a delay.
    private func scheduleReviewPrompt() async {
        reviewPromptTask?.cancel()
        reviewPromptTask = Task {
            do {
                try await Task.sleep(nanoseconds: Constants.appReviewPromptDelay)
                state.isEligibleForAppReview = true
            } catch is CancellationError {
                // Task was cancelled, no need to handle this error
            } catch {
                services.errorReporter.log(error: error)
            }
        }
    }

    /// Streams the user's account setup progress.
    ///
    private func streamAccountSetupProgress() async {
        do {
            for await badgeState in try await services.stateService.settingsBadgePublisher().values {
                state.importLoginsSetupProgress = badgeState.importLoginsSetupProgress
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Streams the flight recorder enabled status.
    ///
    private func streamFlightRecorderLog() async {
        for await log in await services.flightRecorder.activeLogPublisher().values {
            state.activeFlightRecorderLog = log
            state.isFlightRecorderToastBannerVisible = !(log?.isBannerDismissed ?? true)
        }
    }

    /// Streams the user's organizations.
    private func streamOrganizations() async {
        do {
            for try await organizations in try await services.vaultRepository.organizationsPublisher() {
                state.organizations = organizations
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Streams the user's vault list.
    private func streamVaultList() async {
        do {
            for try await vaultList in try await services.vaultRepository
                .vaultListPublisher(filter: VaultListFilter(filterType: state.vaultFilterType)) {
                // Check if the vault needs a sync.
                let needsSync = try await services.vaultRepository.needsSync()

                let value = vaultList.sections

                // If the data is empty, check to ensure that a sync is not needed.
                if !needsSync || !value.isEmpty {
                    // Dismiss the "this is taking a while" toast now that we have data,
                    // since this might not happen because of the sync in `refreshVault()`.
                    state.toast = nil
                    // If the data is not empty or if a sync is not needed, set the data.
                    state.loadingState = .data(value)
                } else {
                    // Otherwise mark the state as `.loading` until the sync is complete.
                    state.loadingState = .loading(value)
                }

                // Dismiss the import logins action card once the vault has items in it.
                if !value.isEmpty {
                    await setImportLoginsProgress(.complete)
                }
                // Dismiss the coach mark action cards once the vault has at least one login item in it.
                if value.hasLoginItems {
                    await services.stateService.setLearnNewLoginActionCardStatus(.complete)
                    await services.stateService.setLearnGeneratorActionCardStatus(.complete)
                }
                // Alert the user of any cipher decryption failures.
                handleCipherDecryptionFailures(cipherIds: vaultList.cipherDecryptionFailureIds)
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}

// MARK: - CipherItemOperationDelegate

extension VaultListProcessor: CipherItemOperationDelegate {
    func itemDeleted() {
        state.toast = Toast(title: Localizations.itemDeleted)
    }

    func itemSoftDeleted() {
        state.toast = Toast(title: Localizations.itemSoftDeleted)
    }

    func itemRestored() {
        state.toast = Toast(title: Localizations.itemRestored)
    }
}

// MARK: - MoreOptionsAction

/// The actions available from the More Options alert.
enum MoreOptionsAction: Equatable {
    /// Copy the `value` and show a toast with the `toast` string.
    case copy(
        toast: String,
        value: String,
        requiresMasterPasswordReprompt: Bool,
        logEvent: EventType?,
        cipherId: String?
    )

    /// Generate and copy the TOTP code for the given `totpKey`.
    case copyTotp(totpKey: TOTPKeyModel)

    /// Navigate to the view to edit the `cipherView`.
    case edit(cipherView: CipherView)

    /// Launch the `url` in the device's browser.
    case launch(url: URL)

    /// Navigate to view the item with the given `id`.
    case view(id: String)
}

// MARK: - ProfileSwitcherHandler

extension VaultListProcessor: ProfileSwitcherHandler {
    var allowLockAndLogout: Bool {
        true
    }

    var profileServices: ProfileServices {
        services
    }

    var profileSwitcherState: ProfileSwitcherState {
        get {
            state.profileSwitcherState
        }
        set {
            state.profileSwitcherState = newValue
        }
    }

    var shouldHideAddAccount: Bool {
        false
    }

    var toast: Toast? {
        get {
            state.toast
        }
        set {
            state.toast = newValue
        }
    }

    func handleAuthEvent(_ authEvent: AuthEvent) async {
        guard case let .action(authAction) = authEvent else { return }
        await coordinator.handleEvent(authAction)
    }

    func showAddAccount() {
        coordinator.navigate(to: .addAccount)
    }

    func showAlert(_ alert: Alert) {
        coordinator.showAlert(alert)
    }
}
