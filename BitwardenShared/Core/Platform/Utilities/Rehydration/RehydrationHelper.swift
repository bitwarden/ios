import Foundation

protocol RehydrationHelper {
    /// Adds a new target to be considered for rehydration.
    func addRehydratableTarget(_ target: Rehydratable)
    /// Clears the app rehydration state from the storage.
    func clearAppRehydrationState() async throws
    /// Gets the last target state for rehydartion.
    func getLastTargetState() -> RehydrationState?
    /// Attemps to get the saved rehydratable target if there's one and if the expiration time hasn't been reached.
    func getSavedRehydratableTarget() async throws -> RehydratableTarget?
    /// Saves the rehydration state if the last view seen by the user is one that we need to save
    /// so after the user unlocks it navigates back to such screen.
    func saveRehydrationStateIfNeeded() async throws
}

class DefaultRehydrationHelper: RehydrationHelper {
    /// The total seconds the rehydration state should be taken under consideration
    /// when restoring targets after unlocking.
    private static let rehydrationTimeoutInSecs: TimeInterval = 5 * 60

    private let stateService: StateService
    private let timeProvider: TimeProvider

    var weakTargets = NSPointerArray.weakObjects()

    init(stateService: StateService, timeProvider: TimeProvider) {
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    func addRehydratableTarget(_ target: Rehydratable) {
        objc_sync_enter(self)

        unowned let weakTarget = target as AnyObject
        let pointer = Unmanaged.passUnretained(weakTarget).toOpaque()
        weakTargets.compact()
        weakTargets.addPointer(pointer)

        objc_sync_exit(self)
    }
    
    func clearAppRehydrationState() async throws {
        try await stateService.setAppRehydrationState(nil)
    }

    func getLastTargetState() -> RehydrationState? {
        var rehydrationState: RehydrationState?
        objc_sync_enter(self)

        weakTargets.compact()
        if let target = weakTargets.allObjects.last as? Rehydratable {
            rehydrationState = target.rehydrationState
        }

        objc_sync_exit(self)
        return rehydrationState
    }

    func getSavedRehydratableTarget() async throws -> RehydratableTarget? {
        guard let rehydrationState = try await stateService.getAppRehydrationState() else {
            return nil
        }
        guard rehydrationState.expirationTime >= timeProvider.presentTime else {
            try await stateService.setAppRehydrationState(nil)
            return nil
        }

        return rehydrationState.target
    }

    func saveRehydrationStateIfNeeded() async throws {
        guard let state = getLastTargetState() else {
            return
        }

        try await stateService.setAppRehydrationState(
            AppRehydrationState(
                target: state.target,
                expirationTime: timeProvider.presentTime.addingTimeInterval(
                    Self.rehydrationTimeoutInSecs
                )
            )
        )
    }
}

/// A protocol to be conformed by targets that need to be considered for rehydration when the vault unlocks
/// after being automatically locked.
protocol Rehydratable: AnyObject {
    /// The state for rehydration.
    var rehydrationState: RehydrationState? { get }
}

/// The state for rehydration.
struct RehydrationState: Codable {
    let target: RehydratableTarget
}
