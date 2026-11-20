import XCTest

/// Drives the device auth key POC flows in the installed Bitwarden app.
final class DeviceAuthKeyDemoUITests: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "com.8bit.bitwarden")

    override func setUp() {
        continueAfterFailure = false
    }

    func testProbe() {
        app.launch()
        sleep(3)
        print("PROBE-BEGIN\n\(app.debugDescription)\nPROBE-END")
    }
}
