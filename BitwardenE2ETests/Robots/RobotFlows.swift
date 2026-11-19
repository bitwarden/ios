import XCTest

// MARK: - RobotFlows

/// Shared multi-screen flows.
///
@MainActor
enum RobotFlows {
    /// Logs in as `account` from the intro carousel and ends on the vault.
    ///
    /// The first login on an install is followed by the app's "Allow automatic syncing" alert and
    /// the system notification prompt. XCUITest's default interruption handler accepts both at the
    /// next interaction, so no step here waits for them.
    ///
    /// - Parameters:
    ///   - app: The application under test.
    ///   - account: The account to log in with.
    ///
    static func logIn(app: XCUIApplication, account: SeededAccount) {
        IntroCarouselRobot(app: app).tapLogIn()
        LandingRobot(app: app).enterEmail(account.email).submitEmail()
        LoginRobot(app: app).enterMasterPassword(account.password).tapLogIn()
        _ = VaultRobot(app: app, timeout: E2ETimeouts.login)
    }
}
