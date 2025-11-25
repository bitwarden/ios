import BitwardenKit
import Combine

/// The processor for the simple login form test screen.
///
class SimpleLoginFormProcessor: StateProcessor<
    SimpleLoginFormState,
    SimpleLoginFormAction,
    SimpleLoginFormEffect,
> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    // MARK: Initialization

    /// Initialize a `SimpleLoginFormProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<RootRoute, Void>) {
        self.coordinator = coordinator
        super.init(state: SimpleLoginFormState())
    }

    // MARK: Methods

    override func receive(_ action: SimpleLoginFormAction) {
        switch action {
        case let .usernameChanged(newValue):
            state.username = newValue
        case let .passwordChanged(newValue):
            state.password = newValue
        }
    }
}
