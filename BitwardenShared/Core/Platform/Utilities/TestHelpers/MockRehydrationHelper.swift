@testable import BitwardenShared

class MockRehydrationHelper: RehydrationHelper {
    var rehydratableTargets: [Rehydratable] = []
    var getLastTargetStateResult: RehydrationState?

    /// Adds a new target to be considered for rehydration.
    func addRehydratableTarget(_ target: Rehydratable) {
        rehydratableTargets.append(target)
    }

    /// Gets the last target state for rehydartion.
    func getLastTargetState() -> RehydrationState? {
        getLastTargetStateResult
    }
}
