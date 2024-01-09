import OSLog

// MARK: - LoginWithPINProcessor

/// The processor used to manage state and handle actions for the login with PIN screen.
///
class LoginWithPINProcessor: StateProcessor<LoginWithPINState, LoginWithPINAction, LoginWithPINEffect> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter

    // MARK: Properties

    /// The coordinator used for navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Initializes an `LoginWithPINProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute>,
        services: Services,
        state: LoginWithPINState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: LoginWithPINEffect) async {
        switch effect {
        case .appeared:
            await performAppeared()
        case .logout:
            await showLogoutConfirmation()
        case let .profileSwitcher(effect):
            await performProfileSwitcherEffect(effect)
        case .unlockWithPIN:
            await unlockWithPIN()
        }
    }

    override func receive(_ action: LoginWithPINAction) {
        switch action {
        case let .pinChanged(pin):
            state.pinCode = pin
        case let .profileSwitcherAction(action):
            executeProfileSwitcherAction(action)
        case let .showPIN(isVisible):
            state.isPINVisible = isVisible
        }
    }

    // MARK: Private methods

    /// Handles a tap of an account in the profile switcher.
    ///
    /// - Parameter selectedAccount: The `ProfileSwitcherItem` selected by the user.
    ///
    private func didTapProfileSwitcherItem(_ selectedAccount: ProfileSwitcherItem) {
        defer { setProfileSwitcher(visible: false) }
        guard state.profileSwitcherState.activeAccountId != selectedAccount.userId else { return }
        coordinator.navigate(
            to: .switchAccount(userId: selectedAccount.userId)
        )
    }

    /// Executes the profile switcher action.
    ///
    /// - Parameter action: The profile switcher action.
    ///
    private func executeProfileSwitcherAction(_ action: ProfileSwitcherAction) {
        switch action {
        case let .accountPressed(account):
            didTapProfileSwitcherItem(account)
        case .addAccountPressed:
            coordinator.navigate(to: .landing)
        case .backgroundPressed:
            setProfileSwitcher(visible: false)
        case let .requestedProfileSwitcher(visible: isVisible):
            state.profileSwitcherState.isVisible = isVisible
        case let .scrollOffsetChanged(newOffset):
            state.profileSwitcherState.scrollOffset = newOffset
        }
    }

    /// The block of code to execute when the view appears.
    ///
    private func performAppeared() async {
        var accounts = [ProfileSwitcherItem]()
        var activeAccount: ProfileSwitcherItem?
        do {
            accounts = try await services.authRepository.getAccounts()
            guard !accounts.isEmpty else { return }
            activeAccount = try? await services.authRepository.getActiveAccount()
            state.profileSwitcherState = ProfileSwitcherState(
                accounts: accounts,
                activeAccountId: activeAccount?.userId,
                isVisible: state.profileSwitcherState.isVisible
            )
        } catch {
            state.profileSwitcherState = .empty(shouldAlwaysHideAddAccount: true)
        }
    }

    /// Performs a profile switcher effect.
    ///
    /// - Parameter effect: The effect to perform.
    ///
    private func performProfileSwitcherEffect(_ effect: ProfileSwitcherEffect) async {
        switch effect {
        case let .rowAppeared(rowType):
            guard state.profileSwitcherState.shouldSetAccessibilityFocus(for: rowType) == true else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.state.profileSwitcherState.hasSetAccessibilityFocus = true
            }
        }
    }

    /// Sets the visibility of the profiles view and updates accessbility focus.
    ///
    /// - Parameter visible: the intended visibility of the view.
    ///
    private func setProfileSwitcher(visible: Bool) {
        if !visible {
            state.profileSwitcherState.hasSetAccessibilityFocus = false
        }
        state.profileSwitcherState.isVisible = visible
    }

    /// Shows the logout confirmation alert.
    ///
    private func showLogoutConfirmation() async {
        let alert = Alert.logoutConfirmation {
            do {
                try await self.services.authRepository.logout()
            } catch {
                self.services.errorReporter.log(error: BitwardenError.logoutError(error: error))
            }
            self.coordinator.navigate(to: .landing)
        }
        coordinator.showAlert(alert)
    }

    /// Unlocks the vault using the user's PIN.
    ///
    private func unlockWithPIN() async {
        do {
            try EmptyInputValidator(fieldName: Localizations.pin).validate(input: state.pinCode)
            try await services.authRepository.unlockWithPIN(state.pinCode)
            coordinator.navigate(to: .complete)
        } catch let error as InputValidationError {
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
        } catch {
            coordinator.showAlert(
                Alert.defaultAlert(
                    title: Localizations.anErrorHasOccurred,
                    message: Localizations.invalidPIN
                )
            )
            Logger.processor.error("Error unlocking vault: \(error)")
        }
    }
}
