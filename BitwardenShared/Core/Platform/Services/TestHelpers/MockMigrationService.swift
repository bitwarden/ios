@testable import BitwardenShared

class MockMigrationService: MigrationService {
    var didPerformMigrations: Bool?

    func performMigrations() async {
        didPerformMigrations = true
    }
}
