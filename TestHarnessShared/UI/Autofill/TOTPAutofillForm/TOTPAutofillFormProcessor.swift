import BitwardenKit
import Combine

/// The processor for the TOTP autofill form test screen.
///
class TOTPAutofillFormProcessor: StateProcessor<
    TOTPAutofillFormState,
    TOTPAutofillFormAction,
    TOTPAutofillFormEffect,
> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    // MARK: Initialization

    /// Initialize a `TOTPAutofillFormProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<RootRoute, Void>) {
        self.coordinator = coordinator
        super.init(state: TOTPAutofillFormState())
    }

    // MARK: Methods

    override func receive(_ action: TOTPAutofillFormAction) {
        switch action {
        case let .totpCodeChanged(newValue):
            state.totpCode = newValue
        }
    }
}
