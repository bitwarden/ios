import XCTest

// MARK: - RobotFlows

/// Shared multi-screen flows.
///
@MainActor
enum RobotFlows {
    /// Logs in as `account` from the intro carousel and ends on the vault.
    ///
    /// - Parameters:
    ///   - app: The application under test.
    ///   - account: The account to log in with.
    ///
    static func logIn(app: XCUIApplication, account: SeededAccount) {
        IntroCarouselRobot(app: app).tapLogIn()
        LandingRobot(app: app).enterEmail(account.email).submitEmail()
        LoginRobot(app: app).enterMasterPassword(account.password).tapLogIn()
        VaultRobot(app: app, timeout: E2ETimeouts.login).assertNoAlertIsShown()
    }
}
