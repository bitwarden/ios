@testable import AuthenticatorShared

class MockMigrationService: MigrationService {
    var didPerformMigrations: Bool?

    func performMigrations() async {
        didPerformMigrations = true
    }
}
