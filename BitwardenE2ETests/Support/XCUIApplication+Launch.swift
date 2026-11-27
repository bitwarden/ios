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

extension SystemApps {
    /// Restarts Safari, which opens on the tab it showed last.
    ///
    @MainActor
    static func relaunchSafari() -> XCUIApplication {
        let safari = safari
        safari.terminate()
        safari.launch()
        return safari
    }

    /// Restarts Settings, so that it opens on its first screen. System apps are started here, next
    /// to the launch of the app under test, so that no test or robot launches an app itself.
    ///
    @MainActor
    static func relaunchSettings() -> XCUIApplication {
        let settings = settings
        settings.terminate()
        settings.launch()
        return settings
    }
}
