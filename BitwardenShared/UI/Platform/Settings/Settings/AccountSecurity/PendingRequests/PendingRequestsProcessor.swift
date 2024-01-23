// MARK: - PendingRequestsProcessor

/// The processor used to manage state and handle actions for the `PendingRequestsView`.
///
final class PendingRequestsProcessor: StateProcessor<
    PendingRequestsState,
    PendingRequestsAction,
    PendingRequestsEffect
> {
    // MARK: Types

    typealias Services = HasAuthService
        & HasErrorReporter

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a `PendingRequestsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        services: Services,
        state: PendingRequestsState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: PendingRequestsEffect) async {
        switch effect {
        case .loadData:
            await loadData()
        }
    }

    override func receive(_ action: PendingRequestsAction) {
        switch action {
        case .declineAllRequestsTapped:
            confirmDenyAllRequests()
        case .dismiss:
            coordinator.navigate(to: .dismiss, context: self)
        case let .requestTapped(request):
            // TODO: BIT-807
            break
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Present an alert to confirm denying all the requests.
    private func confirmDenyAllRequests() {
        // Present an alert to confirm denying all the requests.
        coordinator.showAlert(.confirmDenyingAllRequests { await self.denyAllRequests() })
    }

    /// Deny all the login requests.
    private func denyAllRequests() async {
        guard case let .data(requests) = state.loadingState else { return }
        do {
            // Deny all the requests.
            coordinator.showLoadingOverlay(title: Localizations.loading)
            // TODO: BIT-441

            // Refresh the view.
            await loadData()

            // Show the success toast.
            coordinator.hideLoadingOverlay()
            state.toast = Toast(text: Localizations.requestsDeclined)
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Load the pending login requests to display.
    private func loadData() async {
        do {
            let data = try await services.authService.getPendingLoginRequests()
            state.loadingState = .data(data)
        } catch {
            state.loadingState = .data([])
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }
}
