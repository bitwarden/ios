import BitwardenResources
import Foundation

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
        & HasConfigService
        & HasErrorReporter

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by the processor.
    private let services: Services

    /// The timer used to automatically update the login requests.
    private var updateTimer: Timer?

    // MARK: Initialization

    /// Initializes a `PendingRequestsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: PendingRequestsState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    deinit {
        updateTimer?.invalidate()
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
            coordinator.navigate(to: .loginRequest(request), context: self)
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
        defer { coordinator.hideLoadingOverlay() }
        do {
            // Deny all the requests.
            coordinator.showLoadingOverlay(title: Localizations.loading)
            try await services.authService.denyAllLoginRequests(requests)

            // Refresh the view.
            await loadData()

            // Show the success toast.
            state.toast = Toast(title: Localizations.requestsDeclined)
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }

    /// Load the pending login requests to display.
    private func loadData() async {
        do {
            // Update the data.
            let data = try await services.authService.getPendingLoginRequests()
            state.loadingState = .data(data)

            // Set or reset the timer.
            setUpdateTimer()
        } catch {
            state.loadingState = .data([])
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }

    /// Set or reset the auto-update timer.
    private func setUpdateTimer() {
        updateTimer?.invalidate()

        // Set the timer to auto-update the data in five minutes. Repeating is not necessary,
        // since the timer will be reset after reloading the data.
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: false) { _ in
            Task { await self.loadData() }
        }
    }
}

extension PendingRequestsProcessor: LoginRequestDelegate {
    /// Update the data and display a success toast after a login request has been answered.
    func loginRequestAnswered(approved: Bool) {
        Task { await loadData() }
        state.toast = Toast(title: approved ? Localizations.loginApproved : Localizations.logInDenied)
    }
}
