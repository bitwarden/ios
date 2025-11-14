import BitwardenKit
import Combine

/// The processor for the password autofill test screen.
///
class PasswordAutofillProcessor: StateProcessor<
    PasswordAutofillState,
    PasswordAutofillAction,
    PasswordAutofillEffect
> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    // MARK: Initialization

    /// Initialize a `PasswordAutofillProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<RootRoute, Void>) {
        self.coordinator = coordinator
        super.init(state: PasswordAutofillState())
    }

    // MARK: Methods

    override func receive(_ action: PasswordAutofillAction) {
        switch action {
        case let .usernameChanged(newValue):
            state.username = newValue
        case let .passwordChanged(newValue):
            state.password = newValue
        }
    }
}
