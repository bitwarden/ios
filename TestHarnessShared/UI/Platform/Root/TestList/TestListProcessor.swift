import BitwardenKit
import Combine

/// The processor for the test list screen.
///
class TestListProcessor: StateProcessor<TestListState, TestListAction, TestListEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    // MARK: Initialization

    /// Initialize a `TestListProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<RootRoute, Void>) {
        self.coordinator = coordinator
        super.init(state: TestListState())
    }

    // MARK: Methods

    override func receive(_ action: TestListAction) {
        switch action {
        case .passwordAutofillTapped:
            coordinator.navigate(to: .passwordAutofill)
        case .passkeyAutofillTapped:
            // Not yet implemented
            break
        case .createPasskeyTapped:
            // Not yet implemented
            break
        }
    }
}
