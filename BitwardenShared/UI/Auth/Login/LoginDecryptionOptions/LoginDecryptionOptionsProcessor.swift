import BitwardenResources

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
        & HasTrustDeviceService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by the processor.
    private let services: Services

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
        case .approveWithMasterPasswordPressed:
            await approveWithMasterPassword()
        case .approveWithOtherDevicePressed:
            await setTrustAndNavigate(route: .loginWithDevice(
                email: state.email,
                authRequestType: AuthRequestType.authenticateAndUnlock,
                isAuthenticated: true
            ))
        case .continuePressed:
            await createNewSsoUser()
        case .loadLoginDecryptionOptions:
            await loadUserDecryptionOptions()
        case .notYouPressed:
            await coordinator.handleEvent(.action(.logout(userId: nil, userInitiated: true)))
        case .requestAdminApprovalPressed:
            await setTrustAndNavigate(route: .loginWithDevice(
                email: state.email,
                authRequestType: AuthRequestType.adminApproval,
                isAuthenticated: true
            ))
        }
    }

    override func receive(_ action: LoginDecryptionOptionsAction) {
        switch action {
        case let .toggleRememberDevice(newValue):
            state.isRememberDeviceToggleOn = newValue
        }
    }

    // MARK: Private Methods

    /// Approves user vault decryption with master password
    private func approveWithMasterPassword() async {
        do {
            let userAccount = try await services.authRepository.getAccount()

            await setTrustAndNavigate(route: .vaultUnlock(
                userAccount,
                animated: true,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false
            ))
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

            await coordinator.handleEvent(.didCompleteAuth)
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
            let userAccount = try await services.authRepository.getAccount()
            let userDecryptionOptions = userAccount.profile.userDecryptionOptions
            let trustedDeviceOption = userDecryptionOptions?.trustedDeviceOption
            state.email = userAccount.profile.email
            state.shouldShowAdminApprovalButton = trustedDeviceOption?.hasAdminApproval ?? false
            state.shouldShowApproveMasterPasswordButton = userDecryptionOptions?.hasMasterPassword ?? false
            state.shouldShowApproveWithOtherDeviceButton = trustedDeviceOption?.hasLoginApprovingDevice ?? false
            state.shouldShowContinueButton = !state.shouldShowAdminApprovalButton
                && !state.shouldShowApproveMasterPasswordButton

            if try await hasApprovedPendingAdminRequest() {
                state.toast = Toast(title: Localizations.loginApproved)
                await coordinator.handleEvent(.didCompleteAuth)
            }
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    /// Sets if the device should be trusted and navigates to given route
    /// - Parameter route: route to navigate the user after setting if device should be trusted
    ///
    private func setTrustAndNavigate(route: AuthRoute) async {
        do {
            try await services.trustDeviceService.setShouldTrustDevice(state.isRememberDeviceToggleOn)
            coordinator.navigate(to: route, context: self)
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }
}
