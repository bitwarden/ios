import BitwardenKit

// MARK: - PendingAppIntentActionMediator

/// A mediator to execute pending `AppIntent` actions.
protocol PendingAppIntentActionMediator {
    /// Executes pending app intent actions if necessary.
    func executePendingAppIntentActions() async

    /// Sets the delegate to interact from the mediator.
    /// - Parameter delegate: The delegate to set.
    func setDelegate(_ delegate: PendingAppIntentActionMediatorDelegate)
}

// MARK: - PendingAppIntentActionMediatorDelegate

/// The delegate to interact from the mediator.
protocol PendingAppIntentActionMediatorDelegate: AnyObject {
    /// The action to take when a pending app intent action has been executed successfully.
    /// - Parameters:
    ///   - pendingAppIntentAction: The pending action executed.
    ///   - data: Additional data if necessary.
    func onPendingAppIntentActionSuccess(
        _ pendingAppIntentAction: PendingAppIntentAction,
        data: Any?,
    ) async
}

// MARK: - DefaultPendingAppIntentActionMediator

/// The default implementation of `PendingAppIntentActionMediator`.
class DefaultPendingAppIntentActionMediator: PendingAppIntentActionMediator {
    // MARK: - Properties

    /// The repository used by the application to manage auth data for the UI layer.
    private let authRepository: AuthRepository
    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter
    /// The delegate to interact from the mediator.
    weak var delegate: PendingAppIntentActionMediatorDelegate?
    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: - Init

    /// Initializes a `DefaultPendingAppIntentActionMediator`.
    /// - Parameters:
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    init(
        authRepository: AuthRepository,
        errorReporter: ErrorReporter,
        stateService: StateService,
    ) {
        self.authRepository = authRepository
        self.errorReporter = errorReporter
        self.stateService = stateService
    }

    // MARK: Methods

    func executePendingAppIntentActions() async {
        guard var actions = await stateService.getPendingAppIntentActions(),
              !actions.isEmpty else {
            return
        }

        if actions.contains(.lockAll) {
            await executeLockAll(currentActions: &actions)
            await stateService.setPendingAppIntentActions(actions: actions)
            return
        }

        if actions.contains(.logOutAll) {
            await executeLogOutAll(currentActions: &actions)
            await stateService.setPendingAppIntentActions(actions: actions)
            return
        }

        if actions.contains(.openGenerator) {
            actions.removeAll(where: { $0 == .openGenerator })
            await stateService.setPendingAppIntentActions(actions: actions)
            await delegate?.onPendingAppIntentActionSuccess(.openGenerator, data: nil)
        }
    }

    func setDelegate(_ delegate: PendingAppIntentActionMediatorDelegate) {
        self.delegate = delegate
    }

    // MARK: Private Methods

    /// Executes the `.lockAll` pending action.
    /// - Parameter currentActions: The current pending actions to update if necessary.
    func executeLockAll(currentActions: inout [PendingAppIntentAction]) async {
        do {
            guard let account = try? await stateService.getActiveAccount() else {
                return
            }

            try await authRepository.lockAllVaults(isManuallyLocking: true)

            await delegate?.onPendingAppIntentActionSuccess(.lockAll, data: account)

            currentActions.removeAll(where: { $0 == .lockAll })
        } catch {
            errorReporter.log(error: error)
        }
    }

    /// Executes the `.logOutAll` pending action.
    /// - Parameter currentActions: The current pending actions to update if necessary.
    private func executeLogOutAll(currentActions: inout [PendingAppIntentAction]) async {
        await delegate?.onPendingAppIntentActionSuccess(.logOutAll, data: nil)

        currentActions.removeAll(where: { $0 == .logOutAll })
    }
}
