import XCTest

#if !DEBUG
#error("E2E tests require a Debug build: the app only honors the launch arguments they rely on in Debug.")
#endif

// MARK: - E2ETestCase

/// The base class of every end-to-end test. Each test starts on the intro carousel of an app with
/// no stored state, with its own seeder play.
///
/// Tests never launch the app themselves; a subclass overriding `setUpWithError()` must call `super`.
///
/// Test methods are synchronous. XCTest can't stop an `async` test at a failed assertion, so a
/// failing robot would hang the test until its time allowance runs out.
///
class E2ETestCase: XCTestCase {
    // MARK: Properties

    /// The application under test.
    private(set) var app: XCUIApplication!

    /// The client used to create this test's server data.
    private(set) var seeder: SeederClient!

    // MARK: Setup & Teardown

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        let configuration = try E2EConfiguration()
        let seeder = SeederClient(configuration: configuration)
        self.seeder = seeder
        addTeardownBlock {
            do {
                try seeder.deletePlayID()
            } catch {
                // A leftover play must not turn a passing test red, but it must be visible.
                XCTContext.runActivity(named: "Seeder play \(seeder.playID) wasn't deleted: \(error)") { _ in }
            }
        }

        let app = XCUIApplication()
        self.app = app
        app.launchForE2E(serverURL: configuration.serverURL)
        _ = IntroCarouselRobot(app: app)
    }

    override func tearDownWithError() throws {
        app = nil
        seeder = nil
        try super.tearDownWithError()
    }
}
