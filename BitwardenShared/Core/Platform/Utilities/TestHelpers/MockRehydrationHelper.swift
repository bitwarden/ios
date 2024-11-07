@testable import BitwardenShared

class MockRehydrationHelper: RehydrationHelper {
    var clearAppRehydrationStateCalled = false
    var clearAppRehydrationStateError: Error?
    var getLastTargetStateResult: RehydrationState?
    var getSavedRehydratableTargetResult: Result<RehydratableTarget?, Error> = .success(nil)
    var rehydratableTargets: [Rehydratable] = []
    var saveRehydrationStateIfNeededCalled = false

    func clearAppRehydrationState() async throws {
        clearAppRehydrationStateCalled = true
        if let clearAppRehydrationStateError {
            throw clearAppRehydrationStateError
        }
    }

    func getSavedRehydratableTarget() async throws -> BitwardenShared.RehydratableTarget? {
        try getSavedRehydratableTargetResult.get()
    }

    func saveRehydrationStateIfNeeded() async {
        saveRehydrationStateIfNeededCalled = true
    }

    func addRehydratableTarget(_ target: Rehydratable) {
        rehydratableTargets.append(target)
    }

    func getLastTargetState() -> RehydrationState? {
        getLastTargetStateResult
    }
}
