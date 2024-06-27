// swiftlint:disable file_length

// MARK: - VaultItemSelectionProcessor

/// The processor used to manage state and handle actions for the vault item selection screen.
///
class VaultItemSelectionProcessor: StateProcessor<
    VaultItemSelectionState,
    VaultItemSelectionAction,
    VaultItemSelectionEffect
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter
        & HasEventService
        & HasPasteboardService
        & HasStateService
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultRoute, AuthAction>

    /// The services used by this processor.
    private var services: Services

    /// The helper to execute user verification flows.
    private let userVerificationHelper: UserVerificationHelper

    // MARK: Initialization

    /// Initialize a `VaultItemSelectionProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///   - userVerificationHelper: The helper to execute user verification flows.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
        services: Services,
        state: VaultItemSelectionState,
        userVerificationHelper: UserVerificationHelper
    ) {
        self.coordinator = coordinator
        self.services = services
        self.userVerificationHelper = userVerificationHelper
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultItemSelectionEffect) async {
        switch effect {
        case .loadData:
            await refreshProfileState()
        case let .morePressed(item):
            await showMoreOptionsAlert(for: item)
        case let .profileSwitcher(profileEffect):
            await handle(profileEffect)
        case let .search(text):
            await searchVault(for: text)
        case .streamShowWebIcons:
            for await value in await services.stateService.showWebIconsPublisher().values {
                state.showWebIcons = value
            }
        case .streamVaultItems:
            await streamVaultItems()
        case let .vaultListItemTapped(item):
            await showEditForNewOtpKey(vaultListItem: item)
        }
    }

    override func receive(_ action: VaultItemSelectionAction) {
        switch action {
        case .addTapped:
            state.profileSwitcherState.setIsVisible(false)
            coordinator.navigate(
                to: .addItem(
                    allowTypeSelection: false,
                    group: .login,
                    newCipherOptions: NewCipherOptions(
                        name: state.ciphersMatchingName,
                        totpKey: state.otpAuthModel.uri
                    )
                ),
                context: self
            )
        case .cancelTapped:
            coordinator.navigate(to: .dismiss)
        case .clearURL:
            state.url = nil
        case let .profileSwitcher(action):
            handle(action)
        case let .searchStateChanged(isSearching: isSearching):
            guard isSearching else {
                state.searchText = ""
                state.searchResults = []
                state.showNoResults = false
                return
            }
            state.profileSwitcherState.isVisible = false
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }
}

extension VaultItemSelectionProcessor {
    // MARK: Private Methods

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

    /// Handles receiving a `ProfileSwitcherAction`.
    ///
    /// - Parameter action: The `ProfileSwitcherAction` to handle.
    ///
    private func handle(_ profileSwitcherAction: ProfileSwitcherAction) {
        switch profileSwitcherAction {
        case let .accessibility(accessibilityAction):
            switch accessibilityAction {
            case .logout:
                // No-op: account logout not supported in the extension.
                break
            }
        default:
            handleProfileSwitcherAction(profileSwitcherAction)
        }
    }

    /// Handles receiving a `ProfileSwitcherEffect`.
    ///
    /// - Parameter action: The `ProfileSwitcherEffect` to handle.
    ///
    private func handle(_ profileSwitcherEffect: ProfileSwitcherEffect) async {
        switch profileSwitcherEffect {
        case let .accessibility(accessibilityAction):
            switch accessibilityAction {
            case .lock:
                // No-op: account lock not supported in the extension.
                break
            default:
                await handleProfileSwitcherEffect(profileSwitcherEffect)
            }
        default:
            await handleProfileSwitcherEffect(profileSwitcherEffect)
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

    /// Searches the list of ciphers for those matching the search term.
    ///
    private func searchVault(for searchText: String) async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.searchResults = []
            state.showNoResults = false
            return
        }
        do {
            let searchPublisher = try await services.vaultRepository.searchVaultListPublisher(
                searchText: searchText,
                group: .login,
                filterType: .allVaults
            )
            for try await items in searchPublisher {
                state.searchResults = items
                state.showNoResults = items.isEmpty
            }
        } catch {
            state.searchResults = []
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Shows the edit item screen for the cipher within the specified vault list item with the OTP
    /// key added.
    ///
    /// - Parameter vaultListItem: The vault list item containing a cipher which the user selected
    ///     to add the OTP key to.
    ///
    private func showEditForNewOtpKey(vaultListItem: VaultListItem) async {
        guard case let .cipher(cipherView, _) = vaultListItem.itemType,
              cipherView.type == .login,
              let login = cipherView.login else {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            return
        }

        do {
            if try await services.authRepository.shouldPerformMasterPasswordReprompt(reprompt: cipherView.reprompt) {
                guard try await userVerificationHelper.verifyMasterPassword() == .verified else {
                    return
                }
            }

            let updatedCipherView = cipherView.update(login: login.update(totp: state.otpAuthModel.uri))
            coordinator.navigate(to: .editItem(updatedCipherView), context: self)
        } catch UserVerificationError.cancelled {
            // No-op: don't log or alert for cancellation errors.
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
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
                canCopyTotp: hasPremium || cipherView.organizationUseTotp,
                cipherView: cipherView,
                hasMasterPassword: hasMasterPassword,
                id: item.id,
                showEdit: true,
                action: handleMoreOptionsAction
            ))
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Streams the list of vault items.
    ///
    private func streamVaultItems() async {
        guard let searchName = state.ciphersMatchingName else { return }
        do {
            for try await items in try await services.vaultRepository.searchVaultListPublisher(
                searchText: searchName,
                group: .login,
                filterType: .allVaults
            ) {
                guard !items.isEmpty else {
                    state.vaultListSections = []
                    continue
                }

                state.vaultListSections = [
                    VaultListSection(
                        id: Localizations.matchingItems,
                        items: items,
                        name: Localizations.matchingItems
                    ),
                ]
            }
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }
}

// MARK: - CipherItemOperationDelegate

extension VaultItemSelectionProcessor: CipherItemOperationDelegate {
    func itemAdded() -> Bool {
        coordinator.navigate(to: .dismiss)
        // Return false to notify the calling processor that the dismissal occurs here.
        return false
    }

    func itemUpdated() -> Bool {
        coordinator.navigate(to: .dismiss)
        // Return false to notify the calling processor that the dismissal occurs here.
        return false
    }
}

// MARK: - ProfileSwitcherHandler

extension VaultItemSelectionProcessor: ProfileSwitcherHandler {
    var allowLockAndLogout: Bool {
        false
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
        true
    }

    var switchAccountAuthCompletionRoute: AppRoute? {
        .tab(.vault(.vaultItemSelection(state.otpAuthModel)))
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
        // No-Op for the VaultItemSelectionProcessor.
    }

    func showAlert(_ alert: Alert) {
        // No-Op for the VaultItemSelectionProcessor.
    }
}
