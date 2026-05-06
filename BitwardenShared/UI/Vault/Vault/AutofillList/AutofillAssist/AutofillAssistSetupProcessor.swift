import BitwardenKit
import Foundation

// MARK: - AutofillAssistSetupProcessor

/// Processor for the Autofill Assist setup screen.
///
class AutofillAssistSetupProcessor: StateProcessor<
    AutofillAssistSetupState,
    AutofillAssistSetupAction,
    AutofillAssistSetupEffect,
> {
    // MARK: Types

    typealias Services = HasAutofillAssistService
        & HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<VaultRoute, AuthAction>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `AutofillAssistSetupProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state for the processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
        services: Services,
        state: AutofillAssistSetupState,
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AutofillAssistSetupEffect) async {
        switch effect {
        case .saveTapped:
            await saveMapping()
        }
    }

    override func receive(_ action: AutofillAssistSetupAction) {
        switch action {
        case .cancelTapped:
            coordinator.navigate(to: .dismiss())
        case let .passwordFieldChanged(opId):
            state.passwordFieldOpId = opId
        case let .toastShown(toast):
            state.toast = toast
        case let .urlChanged(url):
            state.url = url
        case let .usernameFieldChanged(opId):
            state.usernameFieldOpId = opId
        }
    }

    // MARK: Private

    /// Saves the current field mapping configuration.
    ///
    private func saveMapping() async {
        guard let urlHost = URL(string: state.url)?.host else { return }

        let usernameFieldIdentifier = state.usernameFieldOpId.flatMap { opId in
            state.pageFields.first { $0.opId == opId }?.stableIdentifier
        }
        let passwordFieldIdentifier = state.passwordFieldOpId.flatMap { opId in
            state.pageFields.first { $0.opId == opId }?.stableIdentifier
        }

        let mapping = AutofillAssistMapping(
            passwordFieldIdentifier: passwordFieldIdentifier,
            urlHost: urlHost,
            usernameFieldIdentifier: usernameFieldIdentifier,
        )

        do {
            let userId = try await services.stateService.getActiveAccountId()
            try await services.autofillAssistService.saveMapping(mapping, userId: userId)
            coordinator.navigate(to: .dismiss())
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
