import BitwardenKit
import Combine

/// The processor for the scenario picker screen.
///
class ScenarioPickerProcessor: StateProcessor<ScenarioPickerState, ScenarioPickerAction, ScenarioPickerEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    // MARK: Initialization

    /// Initialize a `ScenarioPickerProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<RootRoute, Void>) {
        self.coordinator = coordinator
        super.init(state: ScenarioPickerState())
    }

    // MARK: Methods

    override func receive(_ action: ScenarioPickerAction) {
        switch action {
        case .simpleLoginFormTapped:
            coordinator.navigate(to: .simpleLoginForm)
        case .passkeyAutofillTapped:
            // Not yet implemented
            break
        case .createPasskeyTapped:
            // Not yet implemented
            break
        }
    }
}
