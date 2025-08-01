import BitwardenResources
import Foundation

// MARK: - LoginRequestDelegate

/// An object that is notified when specific circumstances in the login request view have occurred.
///
@MainActor
protocol LoginRequestDelegate: AnyObject {
    /// The login request has been answered.
    ///
    /// - Parameter approved: Whether the request was approved or not.
    ///
    func loginRequestAnswered(approved: Bool)
}

// MARK: - LoginRequestProcessor

/// The processor used to manage state and handle actions for the `LoginRequestView`.
///
final class LoginRequestProcessor: StateProcessor<LoginRequestState, LoginRequestAction, LoginRequestEffect> {
    // MARK: Types

    typealias Services = HasAuthService
        & HasErrorReporter
        & HasStateService

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<LoginRequestRoute, Void>

    /// The delegate that is notified when login requests have been answered.
    private weak var delegate: LoginRequestDelegate?

    /// The services used by the processor.
    private let services: Services

    /// The timer used to automatically update the login request details.
    private var updateTimer: Timer?

    // MARK: Initialization

    /// Initializes a `LoginRequestProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - delegate: The object that is notified when login requests have been answered.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<LoginRequestRoute, Void>,
        delegate: LoginRequestDelegate?,
        services: Services,
        state: LoginRequestState
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services

        super.init(state: state)
        setUpdateTimer()
    }

    deinit {
        updateTimer?.invalidate()
    }

    // MARK: Methods

    override func perform(_ effect: LoginRequestEffect) async {
        switch effect {
        case let .answerRequest(approve):
            await answerRequest(approve: approve)
        case .loadData:
            await loadData()
        case .reloadData:
            await reloadData()
        }
    }

    override func receive(_ action: LoginRequestAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss())
        }
    }

    // MARK: Private Methods

    /// Answer the request.
    ///
    /// - Parameter approve: Whether to approve the login request.
    ///
    private func answerRequest(approve: Bool) async {
        do {
            coordinator.showLoadingOverlay(title: Localizations.loading)

            // First reload the request to ensure it hasn't expired or been answered already.
            await reloadData()

            // Answer the login request.
            try await services.authService.answerLoginRequest(state.request, approve: approve)

            // Dismiss the view and pass the success to the delegate.
            coordinator.hideLoadingOverlay()
            let dismissAction = DismissAction {
                self.delegate?.loginRequestAnswered(approved: approve)
            }
            coordinator.navigate(to: .dismiss(dismissAction))
        } catch {
            coordinator.hideLoadingOverlay()
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }

    /// Load the user's email.
    private func loadData() async {
        do {
            state.email = try await services.stateService.getActiveAccount().profile.email
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }

    /// Reload the login request.
    private func reloadData() async {
        do {
            // Reload the request.
            let request = try await services.authService.getPendingLoginRequest(withId: state.request.id).first
            guard let request else { return }

            // Show an alert and dismiss the view if the request has expired or been answered.
            guard !request.isExpired else {
                return coordinator.showAlert(.requestExpired {
                    self.coordinator.navigate(to: .dismiss())
                })
            }
            guard !request.isAnswered else {
                return coordinator.showAlert(.requestAnswered {
                    self.coordinator.navigate(to: .dismiss())
                })
            }

            // Update the data.
            state.request = request

            // Reset the timer.
            setUpdateTimer()
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Set or reset the auto-update timer.
    private func setUpdateTimer() {
        updateTimer?.invalidate()

        // Set the timer to auto-update the data in five minutes. Repeating is not necessary,
        // since the timer will be reset after reloading the data.
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: false) { _ in
            Task { await self.reloadData() }
        }
    }
}
