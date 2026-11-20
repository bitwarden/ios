import XCTest

/// Drives the device auth key POC flows in the installed Bitwarden app:
/// self-hosted environment, signup with a device auth key, lock + unlock, logout + login.
///
/// Environment variables (pass with `SIMCTL_CHILD_<NAME>` on `simctl launch`):
/// - `DEMO_EMAIL`: the email of the new account. Defaults to a time-based address.
/// - `DEMO_SERVER_URL`: the self-hosted server URL. Defaults to `https://localhost:8080`.
/// - `DEMO_PAUSE`: seconds to pause on key screens (for the video). Defaults to 1.
///
/// The shell side must post the Face ID match notification while the test waits for the vault.
final class DeviceAuthKeyDemoUITests: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "com.8bit.bitwarden")

    var env: [String: String] { ProcessInfo.processInfo.environment }
    var pause: TimeInterval { TimeInterval(env["DEMO_PAUSE"] ?? "1") ?? 1 }
    lazy var email = env["DEMO_EMAIL"] ?? "dak-demo-\(Int(Date().timeIntervalSince1970))@example.com"

    override func setUp() {
        continueAfterFailure = false
    }

    func testDeviceAuthKeyFlows() {
        app.terminate()
        app.launch()
        step("launched, email \(email)")

        setSelfHostedEnvironment()
        signUpWithDeviceAuthKey()
        lockAndUnlock()
        logOutAndLogIn()
        step("ALL FLOWS PASSED")
    }

    // MARK: Flows

    func setSelfHostedEnvironment() {
        // Intro carousel -> landing.
        if element("Log in", timeout: 5).exists, !element("LoginEmailAddressEntry", timeout: 1).exists {
            tap("Log in")
        }
        waitFor("LoginEmailAddressEntry")
        tap("RegionSelectorDropdown")
        tap("Self-hosted")
        // One HTTPS server URL. The app derives `/api` and `/identity` from it. The SDK refuses
        // plain HTTP, and the web vault URL must equal the server's WebAuthn origin.
        type("ServerUrlEntry", env["DEMO_SERVER_URL"] ?? "https://localhost:8080")
        hold("self-hosted")
        tap("Save")
        waitFor("LoginEmailAddressEntry")
        step("self-hosted environment saved")
    }

    func signUpWithDeviceAuthKey() {
        tap("CreateAccountButton")
        type("EmailAddressEntry", email)
        type("NameEntry", "DAK Demo")
        tap("ContinueButton")
        let button = waitFor("CreateAccountWithDeviceAuthKeyButton", timeout: 30, scroll: true)
        hold("complete-registration")
        button.tap()
        step("tapped create account with device auth key")

        // Autofill setup screen, then the vault.
        let turnOnLater = element("Turn on later", timeout: 60)
        if turnOnLater.exists {
            turnOnLater.tap()
            tap("Confirm")
        }
        waitForVault()
        hold("vault-after-signup", seconds: 3)
        step("SIGNUP PASSED")
    }

    func lockAndUnlock() {
        app.terminate()
        app.launch()
        let button = waitFor("UnlockWithDeviceAuthKeyButton", timeout: 30)
        XCTAssertFalse(app.secureTextFields["MasterPasswordEntry"].exists, "master password field is shown")
        hold("unlock-screen", seconds: 3)
        button.tap()
        waitForVault()
        hold("vault-after-unlock")
        step("UNLOCK PASSED")
    }

    func logOutAndLogIn() {
        tap("Settings")
        tap("Account security")
        waitFor("Log out", scroll: true).tap()
        tap("Yes")
        waitFor("LoginEmailAddressEntry", timeout: 30)
        step("logged out")
        type("LoginEmailAddressEntry", email)
        tap("ContinueButton")
        let button = waitFor("LogInWithDeviceAuthKeyButton", timeout: 30)
        hold("login-screen", seconds: 3)
        button.tap()
        waitForVault()
        hold("vault-after-login", seconds: 3)
        step("LOGIN PASSED")
    }

    // MARK: Helpers

    func waitForVault() {
        waitFor("My vault", timeout: 90)
    }

    func step(_ message: String) {
        print("DEMO: \(message)")
        fflush(stdout)
    }

    /// Pauses on a key screen and saves a screenshot marker for the shell side.
    func hold(_ name: String, seconds: TimeInterval? = nil) {
        print("DEMO-SCREEN: \(name)")
        fflush(stdout)
        Thread.sleep(forTimeInterval: seconds ?? pause)
    }

    /// Finds an element by accessibility identifier or label.
    func element(_ id: String, timeout: TimeInterval = 15) -> XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@ OR label == %@", id, id)
        let found = app.descendants(matching: .any).matching(predicate).firstMatch
        _ = found.waitForExistence(timeout: timeout)
        return found
    }

    @discardableResult
    func waitFor(_ id: String, timeout: TimeInterval = 15, scroll: Bool = false) -> XCUIElement {
        let found = element(id, timeout: timeout)
        if !found.exists {
            print("DEMO-FAIL: \(id) not found\n\(app.debugDescription)")
            XCTFail("\(id) not found")
        }
        if scroll {
            var swipes = 0
            while !found.isHittable, swipes < 6 {
                app.swipeUp()
                swipes += 1
            }
        }
        return found
    }

    func tap(_ id: String) {
        waitFor(id).tap()
    }

    func type(_ id: String, _ text: String) {
        let field = waitFor(id)
        field.tap()
        field.typeText(text)
    }
}
