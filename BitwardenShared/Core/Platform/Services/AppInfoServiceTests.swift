import BitwardenKit
import XCTest

@testable import BitwardenShared

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
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2025, month: 1, day: 1)))

        subject = DefaultAppInfoService(
            appAdditionalInfo: appAdditionalInfo,
            bundle: bundle,
            systemDevice: systemDevice,
            timeProvider: timeProvider
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

            Version: 1.0 (1)
            📱 iPhone14,2 🍏 iOS 16.4 📦 Production
            """
        )
    }

    /// `appInfoString` returns a formatted string containing detailed information about the app and
    /// device for the beta config.
    func test_appInfoString_beta() {
        bundle.bundleIdentifier = "com.8bit.bitwarden.beta"

        XCTAssertEqual(
            subject.appInfoString,
            """
            © Bitwarden Inc. 2015–2025

            Version: 1.0 (1)
            📱 iPhone14,2 🍏 iOS 16.4 📦 Beta
            """
        )
    }

    /// `appInfoString` returns a formatted string containing detailed information about the app and
    /// device with additional information.
    func test_appInfoString_withAdditionalInfo() {
        appAdditionalInfo.ciBuildInfo = [
            "🧱 commit:": "bitwarden/ios/main@abc123",
            "💻 build source:": "bitwarden/ios/actions/runs/123/attempts/123",
            "🛠️ compiler flags:": "DEBUG_MENU",
        ]

        XCTAssertEqual(
            subject.appInfoString,
            """
            © Bitwarden Inc. 2015–2025

            Version: 1.0 (1)
            📱 iPhone14,2 🍏 iOS 16.4 📦 Production
            🧱 commit: bitwarden/ios/main@abc123
            💻 build source: bitwarden/ios/actions/runs/123/attempts/123
            🛠️ compiler flags: DEBUG_MENU
            """
        )
    }

    /// `appInfoString` returns a formatted string containing detailed information about the app and
    /// device, without including keys with empty values in the additional information.
    @MainActor
    func test_receive_versionTapped_withAdditionalInfoFiltersEmptyValues() {
        appAdditionalInfo.ciBuildInfo = [
            "🧱 commit:": "bitwarden/ios/main@abc123",
            "💻 build source:": "bitwarden/ios/actions/runs/123/attempts/123",
            "🛠️ compiler flags:": "",
        ]

        XCTAssertEqual(
            subject.appInfoString,
            """
            © Bitwarden Inc. 2015\(String.enDash)\(Calendar.current.component(.year, from: Date.now))

            Version: 1.0 (1)
            📱 iPhone14,2 🍏 iOS 16.4 📦 Production
            🧱 commit: bitwarden/ios/main@abc123
            💻 build source: bitwarden/ios/actions/runs/123/attempts/123
            """
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
}

class MockAppAdditionalInfo: AppAdditionalInfo {
    var ciBuildInfo: KeyValuePairs<String, String> = [:]
}
