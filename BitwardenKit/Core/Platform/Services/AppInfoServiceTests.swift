import BitwardenKit
import BitwardenKitMocks
import XCTest

class AppInfoServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appAdditionalInfo: MockAppAdditionalInfo!
    var bundle: MockBundle!
    var subject: AppInfoService!
    var systemDevice: MockSystemDevice!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appAdditionalInfo = MockAppAdditionalInfo()
        bundle = MockBundle()
        systemDevice = MockSystemDevice()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2025, month: 1, day: 2)))

        subject = DefaultAppInfoService(
            appAdditionalInfo: appAdditionalInfo,
            bundle: bundle,
            systemDevice: systemDevice,
            timeProvider: timeProvider,
        )
    }

    override func tearDown() {
        super.tearDown()

        appAdditionalInfo = nil
        bundle = nil
        subject = nil
        systemDevice = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// `appInfoString` returns a formatted string containing detailed information about the app and
    /// device.
    func test_appInfoString() {
        XCTAssertEqual(
            subject.appInfoString,
            """
            © Bitwarden Inc. 2015–2025

            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            """,
        )
    }

    /// The `appInfoString` provides "unknown" if the bundle ID is missing
    func test_appInfoString_beta() {
        bundle.bundleIdentifier = nil

        XCTAssertEqual(
            subject.appInfoString,
            """
            © Bitwarden Inc. 2015–2025

            📝 Bitwarden 1.0 (1)
            📦 Bundle: Unknown
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            """,
        )
    }

    /// `appInfoString` includes additional information if it is available
    /// device with additional information.
    func test_appInfoString_withAdditionalInfo() {
        appAdditionalInfo.ciBuildInfo = [
            "🧱 Commit": "bitwarden/ios/main@abc123",
            "💻 Build Source": "bitwarden/ios/actions/runs/123/attempts/123",
            "🛠️ Compiler Flags": "DEBUG_MENU",
        ]

        XCTAssertEqual(
            subject.appInfoString,
            """
            © Bitwarden Inc. 2015–2025

            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            🧱 Commit: bitwarden/ios/main@abc123
            💻 Build Source: bitwarden/ios/actions/runs/123/attempts/123
            🛠️ Compiler Flags: DEBUG_MENU
            """,
        )
    }

    /// `appInfoString` returns a formatted string containing detailed information about the app and
    /// device, without including keys with empty values in the additional information.
    @MainActor
    func test_appInfoString_withAdditionalInfoFiltersEmptyValues() {
        appAdditionalInfo.ciBuildInfo = [
            "🧱 Commit": "bitwarden/ios/main@abc123",
            "💻 Build Source": "bitwarden/ios/actions/runs/123/attempts/123",
            "🛠️ Compiler Flags": "",
        ]

        XCTAssertEqual(
            subject.appInfoString,
            """
            © Bitwarden Inc. 2015–2025

            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            🧱 Commit: bitwarden/ios/main@abc123
            💻 Build Source: bitwarden/ios/actions/runs/123/attempts/123
            """,
        )
    }

    /// `appInfoString` includes SDK version when available.
    func test_appInfoString_withSDKVersion() {
        appAdditionalInfo.sdkVersion = "1.0.0-1234-abc1234"

        XCTAssertEqual(
            subject.appInfoString,
            """
            © Bitwarden Inc. 2015–2025

            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            🦀 SDK: 1.0.0-1234-abc1234
            """,
        )
    }

    /// `appInfoString` excludes SDK version when unknown.
    func test_appInfoString_withUnknownSDKVersion() {
        appAdditionalInfo.sdkVersion = "Unknown"

        XCTAssertEqual(
            subject.appInfoString,
            """
            © Bitwarden Inc. 2015–2025

            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            """,
        )
    }

    /// `appInfoString` includes both SDK version and CI build info when both available.
    func test_appInfoString_withSDKVersionAndCIBuildInfo() {
        appAdditionalInfo.sdkVersion = "1.0.0-1234-abc1234"
        appAdditionalInfo.ciBuildInfo = [
            "🧱 Commit": "bitwarden/ios/main@abc123",
            "💻 Build Source": "bitwarden/ios/actions/runs/123/attempts/123",
            "🛠️ Compiler Flags": "DEBUG_MENU",
        ]

        XCTAssertEqual(
            subject.appInfoString,
            """
            © Bitwarden Inc. 2015–2025

            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            🦀 SDK: 1.0.0-1234-abc1234
            🧱 Commit: bitwarden/ios/main@abc123
            💻 Build Source: bitwarden/ios/actions/runs/123/attempts/123
            🛠️ Compiler Flags: DEBUG_MENU
            """,
        )
    }

    /// `debugAppInfoString` returns the app info string without copyright info.
    func test_appInfoWithoutCopyrightString() {
        appAdditionalInfo.ciBuildInfo = [
            "🧱 Commit": "bitwarden/ios/main@abc123",
            "💻 Build Source": "bitwarden/ios/actions/runs/123/attempts/123",
            "🛠️ Compiler Flags": "DEBUG_MENU",
        ]

        XCTAssertEqual(
            subject.appInfoWithoutCopyrightString,
            """
            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            🧱 Commit: bitwarden/ios/main@abc123
            💻 Build Source: bitwarden/ios/actions/runs/123/attempts/123
            🛠️ Compiler Flags: DEBUG_MENU
            """,
        )
    }

    /// `copyrightString` returns the app's formatted copyright string.
    func test_copyrightString() {
        XCTAssertEqual(subject.copyrightString, "© Bitwarden Inc. 2015–2025")

        timeProvider.timeConfig = .mockTime(Date(year: 2020, month: 1, day: 2))
        XCTAssertEqual(subject.copyrightString, "© Bitwarden Inc. 2015–2020")
    }

    /// `versionString` returns the app's formatted version string.
    func test_versionString() {
        XCTAssertEqual(subject.versionString, "Version: 1.0 (1)")

        bundle.appVersion = "1.2.3"
        bundle.buildNumber = "4"
        XCTAssertEqual(subject.versionString, "Version: 1.2.3 (4)")
    }

    // MARK: - DefaultAppAdditionalInfo

    /// `ciBuildInfo` is empty outside of CI.
    func test_appAdditionalInfo_ciBuildInfo() {
        XCTAssertTrue(DefaultAppAdditionalInfo().ciBuildInfo.isEmpty)
    }

    /// `sdkVersion` returns the SDK version from SDKVersionInfo.
    func test_appAdditionalInfo_sdkVersion() {
        let info = DefaultAppAdditionalInfo()
        XCTAssertNotNil(info.sdkVersion)
        XCTAssertFalse(info.sdkVersion.isEmpty)
        XCTAssertEqual(info.sdkVersion, SDKVersionInfo.version)
    }
}

class MockAppAdditionalInfo: AppAdditionalInfo {
    var ciBuildInfo: KeyValuePairs<String, String> = [:]
    var sdkVersion: String = "Unknown"
}
