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

    typealias Services = HasAuthRepository
        & HasAuthService
        & HasErrorReporter
        & HasEventService
        & HasNotificationService
        & HasPasteboardService
        & HasPolicyService
        & HasStateService
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<VaultRoute, AuthAction>

    /// The services used by this processor.
    private let services: Services

    /// `true` if we're currently showing notification permissions.
    /// This is used to prevent both the notification permissions and unused ciphers alert
    /// from appearing at the same time.
    private var isShowingNotificationPermissions = false

    // MARK: Initialization

    /// Creates a new `VaultListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
        services: Services,
        state: VaultListState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultListEffect) async {
        switch effect {
        case .appeared:
            await refreshVault(isManualRefresh: false)
            await requestNotificationPermissions()
            await checkPendingLoginRequests()
            await checkPersonalOwnershipPolicy()
            if !isShowingNotificationPermissions {
                await checkUnassignedCiphers()
            }
        case let .morePressed(item):
            await showMoreOptionsAlert(for: item)
        case let .profileSwitcher(profileEffect):
            await handleProfileSwitcherEffect(profileEffect)
        case .refreshAccountProfiles:
            await refreshProfileState()
        case .refreshVault:
            await refreshVault(isManualRefresh: true)
        case let .search(text):
            state.searchResults = await searchVault(for: text)
        case .streamOrganizations:
            await streamOrganizations()
        case .streamShowWebIcons:
            for await value in await services.stateService.showWebIconsPublisher().values {
                state.showWebIcons = value
            }
        case .streamVaultList:
            await streamVaultList()
        }
    }

    override func receive(_ action: VaultListAction) {
        switch action {
        case .addItemPressed:
            setProfileSwitcher(visible: false)
            coordinator.navigate(to: .addItem())
        case .clearURL:
            state.url = nil
        case .copyTOTPCode:
            break
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
    }

    /// Checks if we need to display the unassigned ciphers alert, and displays if necessary.
    ///
    private func checkUnassignedCiphers() async {
        guard state.shouldCheckUnassignedCiphers else { return }
        state.shouldCheckUnassignedCiphers = false

        guard await services.vaultRepository.shouldShowUnassignedCiphersAlert()
        else { return }

        showAlert(.unassignedCiphers {
            do {
                try await self.services.stateService.setShouldCheckOrganizationUnassignedItems(false, userId: nil)
            } catch {
                self.services.errorReporter.log(error: error)
            }
        })
    }

    /// Generates and copies a TOTP code for the cipher's TOTP key.
    ///
    /// - Parameter totpKey: The TOTP key used to generate a TOTP code.
    ///
    private func generateAndCopyTotpCode(totpKey: TOTPKeyModel) async {
        do {
            let response = try await services.vaultRepository.refreshTOTPCode(for: totpKey)
            if let code = response.codeModel?.code {
                services.pasteboardService.copy(code)
                state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp))
            } else {
                coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            }
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Refreshes the vault's contents.
    ///
    /// - Parameter isManualRefresh: Whether the sync is being performed as a manual refresh.
    ///
    private func refreshVault(isManualRefresh: Bool) async {
        do {
            guard let sections = try await services.vaultRepository.fetchSync(
                isManualRefresh: isManualRefresh,
                filter: state.vaultFilterType
            ) else { return }
            state.loadingState = .data(sections)
        } catch URLError.cancelled {
            // No-op: don't log or alert for cancellation errors.
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Request permission to send push notifications if the user hasn't granted or denied permissions before.
    private func requestNotificationPermissions() async {
        // Don't do anything if the user has already responded to the permission request.
        let notificationAuthorization = await services.notificationService.notificationAuthorization()
        guard notificationAuthorization == .notDetermined else { return }

        isShowingNotificationPermissions = true

        // Show the explanation alert before asking for permissions.
        coordinator.showAlert(
            .pushNotificationsInformation { [services] in
                do {
                    _ = try await services.notificationService
                        .requestAuthorization(options: [.alert, .sound, .badge])
                } catch {
                    self.services.errorReporter.log(error: error)
                }
            }, onDismissed: {
                Task {
                    self.isShowingNotificationPermissions = false
                    await self.checkUnassignedCiphers()
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
                filterType: state.searchVaultFilterType
            )
            for try await ciphers in result {
                return ciphers
            }
        } catch {
            services.errorReporter.log(error: error)
        }
        return []
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
                .vaultListPublisher(filter: state.vaultFilterType) {
                // Check if the vault needs a sync.
                let needsSync = try await services.vaultRepository.needsSync()

                // If the data is empty, check to ensure that a sync is not needed.
                if !needsSync || !value.isEmpty {
                    // If the data is not empty or if a sync is not needed, set the data.
                    state.loadingState = .data(value)
                } else {
                    // Otherwise mark the state as `.loading` until the sync is complete.
                    state.loadingState = .loading(value)
                }
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Show the more options alert for the selected item.
    ///
    /// - Parameter item: The selected item to show the options for.
    ///
    private func showMoreOptionsAlert(for item: VaultListItem) async {
        do {
            // Only ciphers have more options.
            guard case let .cipher(cipherView, _) = item.itemType else { return }

            let hasPremium = await (try? services.vaultRepository.doesActiveAccountHavePremium()) ?? false
            let hasMasterPassword = try await services.stateService.getUserHasMasterPassword()

            coordinator.showAlert(.moreOptions(
                cipherView: cipherView,
                hasMasterPassword: hasMasterPassword,
                hasPremium: hasPremium,
                id: item.id,
                showEdit: true,
                action: handleMoreOptionsAction
            ))
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Handle the result of the selected option on the More Options alert..
    ///
    /// - Parameter action: The selected action.
    ///
    private func handleMoreOptionsAction(_ action: MoreOptionsAction) async {
        switch action {
        case let .copy(toast, value, requiresMasterPasswordReprompt, event, cipherId):
            let copyBlock = {
                self.services.pasteboardService.copy(value)
                self.state.toast = Toast(text: Localizations.valueHasBeenCopied(toast))
                if let event {
                    Task {
                        await self.services.eventService.collect(
                            eventType: event,
                            cipherId: cipherId
                        )
                    }
                }
            }
            if requiresMasterPasswordReprompt {
                presentMasterPasswordRepromptAlert(completion: copyBlock)
            } else {
                copyBlock()
            }
        case let .copyTotp(totpKey, requiresMasterPasswordReprompt):
            if requiresMasterPasswordReprompt {
                presentMasterPasswordRepromptAlert {
                    await self.generateAndCopyTotpCode(totpKey: totpKey)
                }
            } else {
                await generateAndCopyTotpCode(totpKey: totpKey)
            }
        case let .edit(cipherView, requiresMasterPasswordReprompt):
            if requiresMasterPasswordReprompt {
                presentMasterPasswordRepromptAlert {
                    self.coordinator.navigate(to: .editItem(cipherView), context: self)
                }
            } else {
                coordinator.navigate(to: .editItem(cipherView), context: self)
            }
        case let .launch(url):
            state.url = url.sanitized
        case let .view(id):
            coordinator.navigate(to: .viewItem(id: id))
        }
    }

    /// Presents the master password reprompt alert and calls the completion handler when the user's
    /// master password has been confirmed.
    ///
    /// - Parameter completion: A completion handler that is called when the user's master password
    ///     has been confirmed.
    ///
    private func presentMasterPasswordRepromptAlert(completion: @escaping () async -> Void) {
        let alert = Alert.masterPasswordPrompt { [weak self] password in
            guard let self else { return }

            do {
                let isValid = try await services.authRepository.validatePassword(password)
                guard isValid else {
                    coordinator.showAlert(.defaultAlert(title: Localizations.invalidMasterPassword))
                    return
                }
                await completion()
            } catch {
                services.errorReporter.log(error: error)
            }
        }
        coordinator.showAlert(alert)
    }
}

// MARK: - CipherItemOperationDelegate

extension VaultListProcessor: CipherItemOperationDelegate {
    func itemDeleted() {
        state.toast = Toast(text: Localizations.itemDeleted)
    }

    func itemSoftDeleted() {
        state.toast = Toast(text: Localizations.itemSoftDeleted)
    }

    func itemRestored() {
        state.toast = Toast(text: Localizations.itemRestored)
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
