// MARK: - AddFillAssistRuleProcessor

/// The processor used to manage state and handle actions for the `AddFillAssistRuleView`.
///
final class AddFillAssistRuleProcessor: StateProcessor<
    AddFillAssistRuleState,
    AddFillAssistRuleAction,
    AddFillAssistRuleEffect,
> {
    // MARK: Types

    typealias Services = HasDebugStateService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<DebugMenuRoute, Void>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `AddFillAssistRuleProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<DebugMenuRoute, Void>,
        services: Services,
        state: AddFillAssistRuleState,
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AddFillAssistRuleEffect) async {
        switch effect {
        case .saveTapped:
            await saveRule()
        }
    }

    override func receive(_ action: AddFillAssistRuleAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismissAddFillAssistRule)
        case let .domainChanged(domain):
            state.domain = domain
        case let .passwordFieldIdChanged(id):
            state.passwordFieldId = id
        case let .usernameFieldIdChanged(id):
            state.usernameFieldId = id
        }
    }

    // MARK: Private Methods

    /// Validates the entered fields and adds the rule to the active account's cached Fill
    /// Assist rules.
    ///
    private func saveRule() async {
        do {
            try EmptyInputValidator(fieldName: "Domain").validate(input: state.domain)
            try EmptyInputValidator(fieldName: "Username field id").validate(input: state.usernameFieldId)
            try EmptyInputValidator(fieldName: "Password field id").validate(input: state.passwordFieldId)

            try await services.debugStateService.addFillAssistDebugRule(
                domain: state.domain,
                usernameFieldId: state.usernameFieldId,
                passwordFieldId: state.passwordFieldId,
            )
            coordinator.navigate(to: .dismissAddFillAssistRule)
        } catch let error as InputValidationError {
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
