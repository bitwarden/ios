import BitwardenKit
import Foundation

protocol RehydrationHelper {
    /// Adds a new target to be considered for rehydration.
    func addRehydratableTarget(_ target: Rehydratable) async
    /// Clears the app rehydration state from the storage.
    func clearAppRehydrationState() async throws
    /// Gets the last target state for rehydartion.
    func getLastTargetState() async -> RehydrationState?
    /// Attempts to get the saved rehydratable target if there's one and if the expiration time hasn't been reached.
    func getSavedRehydratableTarget() async throws -> RehydratableTarget?
    /// Saves the rehydration state if the last view seen by the user is one that we need to save
    /// so after the user unlocks it navigates back to such screen.
    func saveRehydrationStateIfNeeded() async
}

actor DefaultRehydrationHelper: RehydrationHelper {
    /// The total seconds the rehydration state should be taken under consideration
    /// when restoring targets after unlocking.
    private static let rehydrationTimeoutInSecs: TimeInterval = 5 * 60

    /// The service used by the application to report non-fatal errors
    private let errorReporter: ErrorReporter
    /// The service used by the application to manage account state.
    private let stateService: StateService
    /// A provider of time.
    private let timeProvider: TimeProvider

    /// The weak rehydratable targets.
    private var weakTargets: [WeakWrapper] = []

    /// Initializes a `DefaultRehydrationHelper`
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    ///   - timeProvider: A provider of time.
    init(errorReporter: ErrorReporter, stateService: StateService, timeProvider: TimeProvider) {
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    /// Adds a rehydratable target.
    /// - Parameter target: Target to rehydrate.
    func addRehydratableTarget(_ target: Rehydratable) async {
        weakTargets.append(WeakWrapper(value: target))
    }

    /// Clears the app rehydration state.
    func clearAppRehydrationState() async throws {
        try await stateService.setAppRehydrationState(nil)
    }

    /// Gets the last target state available, i.e. which its weak reference hasn't been cleared.
    /// This would get the last topmost view that is marked as rehydratable.
    /// - Returns: The last `RehydrationState` if available.
    func getLastTargetState() async -> RehydrationState? {
        guard let target = weakTargets.filter({ $0.weakValue != nil }).last?.weakValue as? Rehydratable else {
            return nil
        }

        return target.rehydrationState
    }

    /// Gets the in-disk saved rehydratable target, if available.
    /// - Returns: The saved `RehydratableTarget`, if available.
    func getSavedRehydratableTarget() async throws -> RehydratableTarget? {
        guard let rehydrationState = try await stateService.getAppRehydrationState() else {
            return nil
        }
        guard rehydrationState.expirationTime >= timeProvider.presentTime else {
            try await clearAppRehydrationState()
            return nil
        }

        return rehydrationState.target
    }

    /// Saves the rehydration state if needed.
    func saveRehydrationStateIfNeeded() async {
        guard let state = await getLastTargetState() else {
            return
        }

        do {
            try await stateService.setAppRehydrationState(
                AppRehydrationState(
                    target: state.target,
                    expirationTime: timeProvider.presentTime.addingTimeInterval(
                        Self.rehydrationTimeoutInSecs,
                    ),
                ),
            )
        } catch {
            errorReporter.log(error: error)
        }
    }
}

/// A protocol to be conformed by targets that need to be considered for rehydration when the vault unlocks
/// after being automatically locked.
protocol Rehydratable: AnyObject {
    /// The state for rehydration.
    var rehydrationState: RehydrationState? { get }
}

/// The state for rehydration.
struct RehydrationState: Codable, Equatable {
    let target: RehydratableTarget
}

/// A wrapper object to store weak reference and that can be used in an array.
class WeakWrapper {
    /// The actual weak object.
    weak var weakValue: AnyObject?

    /// Initializes a wrapper with a weak reference to `value`
    /// - Parameter value: Weak value to assign.
    init(value: AnyObject) {
        weakValue = value
    }
}
