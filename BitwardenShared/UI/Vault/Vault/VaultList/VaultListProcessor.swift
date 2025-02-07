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
        & HasConfigService
        & HasErrorReporter
        & HasEventService
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

    /// The task that schedules the app review prompt.
    private(set) var reviewPromptTask: Task<Void, Never>?

    /// The services used by this processor.
    private let services: Services

    /// The helper to handle the two-factor notice.
    private let twoFactorNoticeHelper: TwoFactorNoticeHelper

    /// The helper to handle the more options menu for a vault item.
    private let vaultItemMoreOptionsHelper: VaultItemMoreOptionsHelper

    // MARK: Initialization

    /// Creates a new `VaultListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///   - vaultItemMoreOptionsHelper: The helper to handle the more options menu for a vault item.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
        services: Services,
        state: VaultListState,
        twoFactorNoticeHelper: TwoFactorNoticeHelper,
        vaultItemMoreOptionsHelper: VaultItemMoreOptionsHelper
    ) {
        self.coordinator = coordinator
        self.services = services
        self.twoFactorNoticeHelper = twoFactorNoticeHelper
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
            await refreshVault()
            await handleNotifications()
            await checkPendingLoginRequests()
            await checkPersonalOwnershipPolicy()
            await twoFactorNoticeHelper.maybeShowTwoFactorNotice()
        case .checkAppReviewEligibility:
            if await services.reviewPromptService.isEligibleForReviewPrompt() {
                await scheduleReviewPrompt()
            } else {
                state.isEligibleForAppReview = false
            }
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
            await refreshVault()
        case let .search(text):
            state.searchResults = await searchVault(for: text)
        case .streamAccountSetupProgress:
            await streamAccountSetupProgress()
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
        }
    }

    override func receive(_ action: VaultListAction) {
        switch action {
        case .addItemPressed:
            setProfileSwitcher(visible: false)
            coordinator.navigate(to: .addItem())
            reviewPromptTask?.cancel()
        case .clearURL:
            state.url = nil
        case .copyTOTPCode:
            break
        case .disappeared:
            reviewPromptTask?.cancel()
        case let .itemPressed(item):
            switch item.itemType {
            case .cipher:
                coordinator.navigate(to: .viewItem(id: item.id), context: self)
            case let .group(group, _):
                coordinator.navigate(to: .group(group, filter: state.vaultFilterType))
            case let .totp(_, model):
                coordinator.navigate(to: .viewItem(id: model.id))
            }
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

    /// Refreshes the vault's contents.
    ///
    private func refreshVault() async {
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
            guard let sections = try await services.vaultRepository.fetchSync(
                forceSync: false,
                filter: state.vaultFilterType
            ) else { return }
            state.loadingState = .data(sections)
        } catch URLError.cancelled {
            // No-op: don't log or alert for cancellation errors.
        } catch {
            let needsSync = try? await services.vaultRepository.needsSync()
            if needsSync == true {
                state.loadingState = .error(
                    errorMessage: Localizations.weAreUnableToProcessYourRequestPleaseTryAgainOrContactUs
                )
            }
            services.errorReporter.log(error: error)
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
                if await services.configService.getFeatureFlag(.appReviewPrompt) {
                    state.isEligibleForAppReview = true
                }
                if await services.configService.getFeatureFlag(.enableDebugAppReviewPrompt) {
                    state.toast = Toast(title: Constants.appReviewPromptEligibleDebugMessage)
                }
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
        guard await services.configService.getFeatureFlag(.importLoginsFlow) else { return }
        do {
            for await badgeState in try await services.stateService.settingsBadgePublisher().values {
                state.importLoginsSetupProgress = badgeState.importLoginsSetupProgress
            }
        } catch {
            services.errorReporter.log(error: error)
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
            for try await value in try await services.vaultRepository
                .vaultListPublisher(filter: VaultListFilter(filterType: state.vaultFilterType)) {
                // Check if the vault needs a sync.
                let needsSync = try await services.vaultRepository.needsSync()

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
                if !value.isEmpty, await services.configService.getFeatureFlag(.nativeCreateAccountFlow) {
                    await setImportLoginsProgress(.complete)
                }
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
    case copyTotp(totpKey: TOTPKeyModel, requiresMasterPasswordReprompt: Bool)

    /// Navigate to the view to edit the `cipherView`.
    case edit(cipherView: CipherView, requiresMasterPasswordReprompt: Bool)

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
