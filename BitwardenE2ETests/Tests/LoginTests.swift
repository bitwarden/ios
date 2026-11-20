import XCTest

// MARK: - LoginTests

/// End-to-end tests for logging in.
///
final class LoginTests: E2ETestCase {
    /// Testmo 22270: logging in with a master password reaches the vault.
    @MainActor
    func test_logIn_showsVault() throws {
        let account = try seeder.createFreeUser()

        RobotFlows.logIn(app: app, account: account)
    }
}
