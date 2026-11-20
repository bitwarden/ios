import XCTest

/// Drives the device auth key POC flows in the installed Bitwarden app:
/// self-hosted environment, signup with a device auth key, lock + unlock, logout + login.
///
/// Environment variables (pass with `SIMCTL_CHILD_<NAME>` on `simctl launch`):
/// - `DEMO_EMAIL`: the email of the new account. Defaults to a time-based address.
/// - `DEMO_SERVER_URL`: the self-hosted server URL. Defaults to `https://localhost:8080`.
/// - `DEMO_NAME`: the name of the new account. Defaults to "DAK Demo".
/// - `DEMO_PAUSE`: seconds to pause on key screens (for the video). Defaults to 1.
/// - `DEMO_RESTART`: set to 1 to terminate and start the app for the unlock flow. The default is
///   "Lock now" in the settings, which keeps the app on screen.
/// - `DEMO_SKIP_UNLOCK`: set to 1 to skip the lock + unlock flow.
/// - `DEMO_FLOW`: `crossdevice` runs `testCrossDeviceSignIn` instead of `testDeviceAuthKeyFlows`.
///
/// The test prints `DEMO-RECORD-START` when the environment is set and the app is on the landing
/// screen, and `DEMO-RECORD-STOP` after the last screen. `demo.sh` records the video in between.
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

    func testDeviceAuthKeyFlows() throws {
        try XCTSkipIf(env["DEMO_FLOW"] == "crossdevice")
        app.terminate()
        app.launch()
        step("launched, email \(email)")

        setSelfHostedEnvironment()
        // Let the "environment URLs have been saved" toast go away before the recording starts.
        Thread.sleep(forTimeInterval: 5)
        marker("DEMO-RECORD-START")
        Thread.sleep(forTimeInterval: 5)
        signUpWithDeviceAuthKey()
        if env["DEMO_SKIP_UNLOCK"] != "1" {
            lockAndUnlock()
        }
        logOutAndLogIn()
        marker("DEMO-RECORD-STOP")
        Thread.sleep(forTimeInterval: 3)
        step("ALL FLOWS PASSED")
    }

    /// Signs up, turns on Bitwarden as the passkey provider, then logs in to the web vault in
    /// Safari with the device auth key, as a passkey. Records only the Safari part.
    func testCrossDeviceSignIn() throws {
        try XCTSkipUnless(env["DEMO_FLOW"] == "crossdevice")
        app.terminate()
        app.launch()
        step("launched, email \(email)")

        setSelfHostedEnvironment()
        signUpWithDeviceAuthKey(turnOnAutofill: true)
        // A lock and unlock syncs the device auth key into the iOS passkey list.
        lockAndUnlock()

        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.terminate()
        try safari.open(XCTUnwrap(URL(string: env["DEMO_WEB_VAULT_URL"] ?? "https://localhost:8080/#/login")))
        let passkeyButton = safari.webViews.buttons["Log in with passkey"]
        XCTAssertTrue(passkeyButton.waitForExistence(timeout: 60), "web vault login page not shown")
        Thread.sleep(forTimeInterval: 2)
        marker("DEMO-RECORD-START")
        hold("safari-login", seconds: max(pause, 1) * 2)
        passkeyButton.tap()
        step("tapped log in with passkey")

        // The iOS passkey sheet offers the device auth key from Bitwarden.
        let sheetButton = systemButton(["Continue", "Sign In", "Use Passkey"], timeout: 30)
        hold("passkey-sheet", seconds: max(pause, 1) * 2)
        sheetButton.tap()
        step("approved the passkey sheet")

        // The web vault logs in, and the PRF output unlocks the vault.
        let vault = safari.webViews.staticTexts.matching(
            NSPredicate(format: "label IN %@", ["All vaults", "Vaults", "All items"]),
        ).firstMatch
        if !vault.waitForExistence(timeout: 90) {
            print("DEMO-FAIL: web vault not unlocked\n\(safari.debugDescription)")
            XCTFail("web vault not unlocked")
        }
        hold("web-vault", seconds: 4)
        marker("DEMO-RECORD-STOP")
        step("CROSS DEVICE PASSED")
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

    func signUpWithDeviceAuthKey(turnOnAutofill: Bool = false) {
        tap("CreateAccountButton")
        let name = env["DEMO_NAME"] ?? "DAK Demo"
        type("NameEntry", name)
        let typedName = waitFor("NameEntry").value as? String
        XCTAssertEqual(typedName, name, "the name field does not hold the name")
        type("EmailAddressEntry", email)
        hold("start-registration")
        tap("ContinueButton")
        let button = waitFor("CreateAccountWithDeviceAuthKeyButton", timeout: 30, scroll: true)
        // The master password section is collapsed behind a low-emphasis control.
        waitFor("UseMasterPasswordInsteadButton")
        XCTAssertFalse(app.secureTextFields["MasterPasswordEntry"].exists, "master password field is shown")
        hold("signup", seconds: max(pause, 1) * 2)
        button.tap()
        step("tapped create account with device auth key")

        // Autofill setup screen, then the vault.
        let turnOnLater = element("Turn on later", timeout: 60)
        if turnOnLater.exists, turnOnAutofill {
            tap("Continue")
            systemButton(["Allow", "Turn On", "Use"], timeout: 15).tap()
            step("turned on autofill")
        } else if turnOnLater.exists {
            turnOnLater.tap()
            tap("Confirm")
        }
        waitForVault()
        hold("vault-after-signup", seconds: 3)
        step("SIGNUP PASSED")
    }

    func lockAndUnlock() {
        if env["DEMO_RESTART"] == "1" {
            app.terminate()
            app.launch()
        } else {
            tap("Settings")
            tap("Account security")
            waitFor("Lock now", scroll: true).tap()
        }
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

    /// Waits for the vault and closes the dialogs that cover it after a login.
    func waitForVault() {
        waitFor("My vault", timeout: 90)
        let gotIt = element("OK, got it!", timeout: 4)
        if gotIt.exists {
            gotIt.tap()
            let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow"]
            if allow.waitForExistence(timeout: 5) {
                allow.tap()
            }
        }
    }

    /// Finds a button in a system sheet or alert, which Safari, SpringBoard or the
    /// AuthenticationServices agent can own.
    @discardableResult
    func systemButton(_ labels: [String], timeout: TimeInterval) -> XCUIElement {
        let owners = [
            XCUIApplication(bundleIdentifier: "com.apple.springboard"),
            XCUIApplication(bundleIdentifier: "com.apple.mobilesafari"),
            XCUIApplication(bundleIdentifier: "com.apple.AuthenticationServicesCore.AuthenticationServicesAgent"),
            app,
        ]
        let predicate = NSPredicate(format: "label IN %@", labels)
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for owner in owners {
                let button = owner.buttons.matching(predicate).firstMatch
                if button.exists, button.isHittable {
                    return button
                }
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        print("DEMO-FAIL: none of \(labels) found\n\(owners.map(\.debugDescription).joined(separator: "\n"))")
        XCTFail("none of \(labels) found")
        return app.buttons.matching(predicate).firstMatch
    }

    func step(_ message: String) {
        print("DEMO: \(message)")
        fflush(stdout)
    }

    /// Prints a marker line for `demo.sh`.
    func marker(_ name: String) {
        print(name)
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
