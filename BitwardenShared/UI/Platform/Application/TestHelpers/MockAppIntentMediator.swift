@testable import BitwardenShared

class MockAppIntentMediator: AppIntentMediator {
    var canRunAppIntentsResult = false
    var lockAllUsersCalled = false
    var lockCurrentUserCalled = false

    func canRunAppIntents() async -> Bool {
        canRunAppIntentsResult
    }

    func lockAllUsers() async throws {
        lockAllUsersCalled = true
    }
}
