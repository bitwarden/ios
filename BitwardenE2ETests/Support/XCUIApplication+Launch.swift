import XCTest

extension XCUIApplication {
    /// The arguments every launch needs, whether or not the app's state is erased.
    private static let baseLaunchArguments = [
        "-AppleLanguages", "(en)",
        "-AppleLocale", "en_US",
    ]

    /// Launches the app with all of its stored state erased, pointed at the server under test.
    ///
    /// - Parameter serverURL: The base URL of the server under test.
    ///
    func launchForE2E(serverURL: URL) {
        launchArguments = Self.baseLaunchArguments + [
            "-BWPreAuthEnvironmentBaseURL", serverURL.absoluteString,
            "-BWResetAppState", "YES",
        ]
        launch()
    }

    /// Restarts the app without erasing its state, for tests that cover behavior across launches.
    ///
    func relaunchKeepingState() {
        launchArguments = Self.baseLaunchArguments
        launch()
    }
}
