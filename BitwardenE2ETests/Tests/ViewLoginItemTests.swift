import XCTest

// MARK: - ViewLoginItemTests

/// End-to-end tests for viewing a login item.
///
final class ViewLoginItemTests: E2ETestCase {
    /// Testmo 22279: a seeded login item shows its username, password and URI.
    @MainActor
    func test_viewLoginItem_showsUsernamePasswordAndURI() throws {
        let account = try seeder.createFreeUser()
        let item = SeededLoginItem(
            name: "Cipher-22279",
            username: "Cipher-22279-User",
            password: "Cipher-22279-Password",
            uri: "www.test.com",
        )
        try seeder.addLoginItem(item, for: account)

        RobotFlows.logIn(app: app, account: account)
        VaultRobot(app: app).openItem(named: item.name)

        ViewLoginItemRobot(app: app)
            .assertUsername(item.username)
            .assertPasswordIsHidden()
            .revealPassword()
            .assertPassword(item.password)
            .assertURIsContain(item.uri)
    }
}
