@testable import BitwardenShared

class MockAppIntentMediator: AppIntentMediator {
    var canRunAppIntentsResult = false
    var lockAllUsersCalled = false
    var logoutAllUsersCalled = false

    func canRunAppIntents() async -> Bool {
        canRunAppIntentsResult
    }

    func lockAllUsers() async throws {
        lockAllUsersCalled = true
    }

    func logoutAllUsers() async throws {
        logoutAllUsersCalled = true
    }
}
