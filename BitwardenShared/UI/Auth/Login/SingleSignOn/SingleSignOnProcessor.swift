// MARK: - SingleSignOnProcessor

/// The processor used to manage state and handle actions for the `SingleSignOnView`.
///
final class SingleSignOnProcessor: StateProcessor<SingleSignOnState, SingleSignOnAction, SingleSignOnEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasStateService

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `SingleSignOnProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute>,
        services: Services,
        state: SingleSignOnState
    ) {
        self.coordinator = coordinator
        self.services = services

        // Set the initial value of the organization identifier, if applicable.
        var state = state
        state.identifierText = self.services.stateService.rememberedOrgIdentifier ?? ""

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SingleSignOnEffect) async {
        switch effect {
        case .loginTapped:
            await handleLoginTapped()
        }
    }

    override func receive(_ action: SingleSignOnAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .identifierTextChanged(newValue):
            state.identifierText = newValue
        }
    }

    // MARK: Private Methods

    /// Handle attempting to login.
    private func handleLoginTapped() async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            try EmptyInputValidator(fieldName: Localizations.orgIdentifier)
                .validate(input: state.identifierText)
            coordinator.showLoadingOverlay(title: Localizations.loggingIn)

            // TODO: BIT-1308

            services.stateService.rememberedOrgIdentifier = state.identifierText
        } catch let error as InputValidationError {
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
            return
        } catch {
            coordinator.showAlert(.networkResponseError(error) { await self.handleLoginTapped() })
            services.errorReporter.log(error: error)
        }
    }
}
