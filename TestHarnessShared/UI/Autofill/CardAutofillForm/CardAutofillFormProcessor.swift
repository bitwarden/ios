import BitwardenKit
import Combine

/// The processor for the card autofill form test screen.
///
@available(iOS 17, *)
class CardAutofillFormProcessor: StateProcessor<
    CardAutofillFormState,
    CardAutofillFormAction,
    CardAutofillFormEffect,
> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    // MARK: Initialization

    /// Initialize a `CardAutofillFormProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<RootRoute, Void>) {
        self.coordinator = coordinator
        super.init(state: CardAutofillFormState())
    }

    // MARK: Methods

    override func receive(_ action: CardAutofillFormAction) {
        switch action {
        case let .cardholderNameChanged(newValue):
            state.cardholderName = newValue
        case let .cardNumberChanged(newValue):
            state.cardNumber = newValue
        case let .expirationMonthChanged(newValue):
            state.expirationMonth = newValue
        case let .expirationYearChanged(newValue):
            state.expirationYear = newValue
        case let .securityCodeChanged(newValue):
            state.securityCode = newValue
        }
    }
}
