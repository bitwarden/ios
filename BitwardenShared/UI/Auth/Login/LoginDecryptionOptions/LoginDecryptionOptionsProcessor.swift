// MARK: - LoginDecryptionOptionsProcessor

/// The processor used to manage state and handle actions for the login with decryption option screen.
///
class LoginDecryptionOptionsProcessor: StateProcessor<
    LoginDecryptionOptionsState,
    LoginDecryptionOptionsAction,
    LoginDecryptionOptionsEffect
> {
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasAuthRepository
        & HasAuthService
        & HasCaptchaService
        & HasClientAuth
        & HasStateService
        & HasTrustDeviceService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by the processor.
    private let services: Services

    private var userAccount: Account?

    private var userDecryptionOptions: UserDecryptionOptions?

    // MARK: Initialization

    /// Creates a new `LoginDecryptionOptionsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: LoginDecryptionOptionsState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: LoginDecryptionOptionsEffect) async {
        switch effect {
        case .loadLoginDecryptionOptions:
            await loadUserDecryptionOptions()
        case .approveWithOtherDevicePressed:
            await setTrustAndNavigate(route: .loginWithDevice(
                email: state.email,
                authRequestType: AuthRequestType.authenticateAndUnlock
            ))
        case .requestAdminApprovalPressed:
            await setTrustAndNavigate(route: .loginWithDevice(
                email: state.email,
                authRequestType: AuthRequestType.adminApproval
            ))
        case .approveWithMasterPasswordPressed:
            await approveWithMasterPassword()
        case .continuePressed:
            await createNewSsoUser()
        case .notYouPressed:
            coordinator.navigate(to: .dismiss)
            await coordinator.handleEvent(.action(.logout(userId: nil, userInitiated: true)))
        }
    }

    override func receive(_ action: LoginDecryptionOptionsAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .toggleRememberDevice(newValue):
            state.isRememberDeviceToggleOn = newValue
        }
    }

    // MARK: Private Methods

    /// Approves user vault decryption with master password
    private func approveWithMasterPassword() async {
        do {
            userAccount = try await services.authRepository.getAccount()
            guard let userAccount else {
                coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
                return
            }
            await setTrustAndNavigate(route: .vaultUnlock(
                userAccount,
                animated: true,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false
            ))
            coordinator.navigate(to: .dismiss)
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    /// Creates a new SSO user
    private func createNewSsoUser() async {
        do {
            guard let orgIdentifier = state.orgIdentifier else { throw AuthError.missingData }
            try await services.authRepository.createNewSsoUser(
                orgIdentifier: orgIdentifier,
                rememberDevice: state.isRememberDeviceToggleOn
            )

            coordinator.navigate(to: .complete)
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    private func hasApprovedPendingAdminRequest() async throws -> Bool {
        if let savedPendingAdminLoginRequest = try await services.authService.getPendingAdminLoginRequest(userId: nil),
           let adminAuthRequest = try await services.authService.getPendingLoginRequest(
               withId: savedPendingAdminLoginRequest.id
           ).first,
           let key = adminAuthRequest.key,
           let approved = adminAuthRequest.requestApproved,
           approved {
            // Attempt to unlock the vault.
            try await services.authRepository.unlockVaultFromLoginWithDevice(
                privateKey: savedPendingAdminLoginRequest.privateKey,
                key: key,
                masterPasswordHash: adminAuthRequest.masterPasswordHash
            )

            // Remove admin pending login request if exists
            try await services.authService.setPendingAdminLoginRequest(nil, userId: nil)

            return true
        }
        return false
    }

    /// Loads user decryption option used to show/hide buttons on screen
    private func loadUserDecryptionOptions() async {
        do {
            userAccount = try await services.authRepository.getAccount()
            guard let userAccount else {
                coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
                return
            }

            state.email = userAccount.profile.email
            userDecryptionOptions = userAccount.profile.userDecryptionOptions
            let trustedDeviceOption = userDecryptionOptions?.trustedDeviceOption
            state.requestAdminApprovalEnabled = trustedDeviceOption?.hasAdminApproval ?? false
            state.approveWithMasterPasswordEnabled = userDecryptionOptions?.hasMasterPassword ?? false
            state.approveWithOtherDeviceEnabled = trustedDeviceOption?.hasLoginApprovingDevice ?? false
            state.continueButtonEnabled = !state.requestAdminApprovalEnabled && !state.approveWithMasterPasswordEnabled

            if try await hasApprovedPendingAdminRequest() {
                state.toast = Toast(text: Localizations.loginApproved)
                coordinator.navigate(to: .complete)
            }
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    /// Sets if the device should be trusted and navigates to given route
    /// - Parameter route: route to navigate the user after setting if device should be trusted
    ///
    private func setTrustAndNavigate(route: AuthRoute) async {
        coordinator.navigate(to: route, context: self)
        do {
            try await services.trustDeviceService.setShouldTrustDevice(state.isRememberDeviceToggleOn)
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }
}
