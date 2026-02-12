import BitwardenKit
import BitwardenKitMocks
import XCTest

@MainActor
class AppInfoServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appAdditionalInfo: MockAppAdditionalInfo!
    var bundle: MockBundle!
    var configService: MockConfigService!
    var subject: AppInfoService!
    var systemDevice: MockSystemDevice!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appAdditionalInfo = MockAppAdditionalInfo()
        bundle = MockBundle()
        configService = MockConfigService()
        systemDevice = MockSystemDevice()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2025, month: 1, day: 2)))

        subject = DefaultAppInfoService(
            appAdditionalInfo: appAdditionalInfo,
            bundle: bundle,
            configServiceProvider: { [configService] in configService },
            systemDevice: systemDevice,
            timeProvider: timeProvider,
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        appAdditionalInfo = nil
        bundle = nil
        configService = nil
        subject = nil
        systemDevice = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// `appInfoString` returns a formatted string containing detailed information about the app and
    /// device.
    func test_appInfoString() async {
        let result = await subject.appInfoString
        XCTAssertEqual(
            result,
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
    func test_appInfoString_beta() async {
        bundle.bundleIdentifier = nil

        let result = await subject.appInfoString
        XCTAssertEqual(
            result,
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
    func test_appInfoString_withAdditionalInfo() async {
        appAdditionalInfo.ciBuildInfo = [
            "🧱 Commit": "bitwarden/ios/main@abc123",
            "💻 Build Source": "bitwarden/ios/actions/runs/123/attempts/123",
            "🛠️ Compiler Flags": "DEBUG_MENU",
        ]

        let result = await subject.appInfoString
        XCTAssertEqual(
            result,
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
    func test_appInfoString_withAdditionalInfoFiltersEmptyValues() async {
        appAdditionalInfo.ciBuildInfo = [
            "🧱 Commit": "bitwarden/ios/main@abc123",
            "💻 Build Source": "bitwarden/ios/actions/runs/123/attempts/123",
            "🛠️ Compiler Flags": "",
        ]

        let result = await subject.appInfoString
        XCTAssertEqual(
            result,
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
    func test_appInfoString_withSDKVersion() async {
        appAdditionalInfo.sdkVersion = "1.0.0-1234-abc1234"

        let result = await subject.appInfoString
        XCTAssertEqual(
            result,
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
    func test_appInfoString_withUnknownSDKVersion() async {
        appAdditionalInfo.sdkVersion = "Unknown"

        let result = await subject.appInfoString
        XCTAssertEqual(
            result,
            """
            © Bitwarden Inc. 2015–2025

            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            """,
        )
    }

    /// `appInfoString` includes server version when available.
    func test_appInfoString_withServerVersion() async {
        configService.configMocker.withResult(
            ServerConfig(
                date: Date(),
                responseModel: ConfigResponseModel(
                    environment: EnvironmentServerConfigResponseModel(
                        api: nil,
                        cloudRegion: "EU",
                        identity: nil,
                        notifications: nil,
                        sso: nil,
                        vault: nil,
                    ),
                    featureStates: [:],
                    gitHash: "",
                    server: nil,
                    version: "2024.5.0",
                ),
            ),
        )

        let result = await subject.appInfoString
        XCTAssertEqual(
            result,
            """
            © Bitwarden Inc. 2015–2025

            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            🌩️ Server: 2024.5.0 @ EU
            """,
        )
    }

    /// `appInfoString` includes server version with the third party's name when available.
    func test_appInfoString_withServerVersionThirdParty() async {
        configService.configMocker.withResult(
            ServerConfig(
                date: Date(),
                responseModel: ConfigResponseModel(
                    environment: nil,
                    featureStates: [:],
                    gitHash: "",
                    server: ThirdPartyConfigResponseModel(name: "Third Party", url: "https://example.com"),
                    version: "2025.0.0",
                ),
            ),
        )

        let result = await subject.appInfoString
        XCTAssertEqual(
            result,
            """
            © Bitwarden Inc. 2015–2025

            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            🌩️ Server: Third Party 2025.0.0
            """,
        )
    }

    /// `appInfoString` includes SDK, server, and CI build info when all available.
    func test_appInfoString_withAllVersionInfo() async {
        appAdditionalInfo.sdkVersion = "1.0.0-1234-abc1234"
        appAdditionalInfo.ciBuildInfo = [
            "🧱 Commit": "bitwarden/ios/main@abc123",
            "💻 Build Source": "bitwarden/ios/actions/runs/123/attempts/123",
            "🛠️ Compiler Flags": "DEBUG_MENU",
        ]
        configService.configMocker.withResult(
            ServerConfig(
                date: Date(),
                responseModel: ConfigResponseModel(
                    environment: EnvironmentServerConfigResponseModel(
                        api: nil,
                        cloudRegion: "US",
                        identity: nil,
                        notifications: nil,
                        sso: nil,
                        vault: nil,
                    ),
                    featureStates: [:],
                    gitHash: "",
                    server: nil,
                    version: "2024.5.0",
                ),
            ),
        )

        let result = await subject.appInfoString
        XCTAssertEqual(
            result,
            """
            © Bitwarden Inc. 2015–2025

            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            🦀 SDK: 1.0.0-1234-abc1234
            🌩️ Server: 2024.5.0 @ US
            🧱 Commit: bitwarden/ios/main@abc123
            💻 Build Source: bitwarden/ios/actions/runs/123/attempts/123
            🛠️ Compiler Flags: DEBUG_MENU
            """,
        )
    }

    /// `debugAppInfoString` returns the app info string without copyright info.
    @MainActor
    func test_appInfoWithoutCopyrightString() async {
        appAdditionalInfo.ciBuildInfo = [
            "🧱 Commit": "bitwarden/ios/main@abc123",
            "💻 Build Source": "bitwarden/ios/actions/runs/123/attempts/123",
            "🛠️ Compiler Flags": "DEBUG_MENU",
        ]

        let result = await subject.appInfoWithoutCopyrightString
        XCTAssertEqual(
            result,
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
