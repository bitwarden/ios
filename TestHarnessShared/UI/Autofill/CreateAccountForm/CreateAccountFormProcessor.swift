import BitwardenKit
import Combine

/// The processor for the create account form test screen.
///
class CreateAccountFormProcessor: StateProcessor<
    CreateAccountFormState,
    CreateAccountFormAction,
    CreateAccountFormEffect,
> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    // MARK: Initialization

    /// Initialize a `CreateAccountFormProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<RootRoute, Void>) {
        self.coordinator = coordinator
        super.init(state: CreateAccountFormState())
    }

    // MARK: Methods

    override func receive(_ action: CreateAccountFormAction) {
        switch action {
        case let .confirmPasswordChanged(newValue):
            state.confirmPassword = newValue
        case let .emailChanged(newValue):
            state.email = newValue
        case let .passwordChanged(newValue):
            state.password = newValue
            state.errorMessage = nil
        }
    }

    override func perform(_ effect: CreateAccountFormEffect) async {
        switch effect {
        case .createAccount:
            guard !state.email.isEmpty, !state.password.isEmpty, !state.confirmPassword.isEmpty else {
                return
            }
            guard state.password == state.confirmPassword else {
                state.errorMessage = Localizations.passwordsDoNotMatch
                return
            }
            state.errorMessage = nil
            // Mark the account as created. The view observes this flag and resigns
            // focus from all fields, which causes iOS to detect the completed
            // .newPassword form and prompt the active credential provider to save.
            state.isAccountCreated = true
        }
    }
}
