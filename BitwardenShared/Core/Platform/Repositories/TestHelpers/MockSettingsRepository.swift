@testable import BitwardenShared

class MockSettingsRepository: SettingsRepository {
    var logoutCalled = false

    func logout() async throws {
        logoutCalled = true
    }
}
