import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenKit

class DebugMenuProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<DebugMenuRoute, Void>!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var serverCommunicationConfigClientSingleton: MockServerCommunicationConfigClientSingleton!
    var subject: DebugMenuProcessor!

    // MARK: Set Up & Tear Down

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        coordinator = MockCoordinator<DebugMenuRoute, Void>()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        serverCommunicationConfigClientSingleton = MockServerCommunicationConfigClientSingleton()
        subject = DebugMenuProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                configService: configService,
                environmentService: environmentService,
                errorReporter: errorReporter,
                serverCommunicationConfigClientSingleton: serverCommunicationConfigClientSingleton,
            ),
            state: DebugMenuState(featureFlags: []),
        )
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        coordinator = nil
        environmentService = nil
        errorReporter = nil
        serverCommunicationConfigClientSingleton = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive()` with `.dismissTapped` navigates to the `.dismiss` route.
    @MainActor
    func test_receive_dismissTapped() {
        subject.receive(.dismissTapped)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `perform(.viewAppeared)` loads the correct feature flags.
    @MainActor
    func test_perform_appeared_loadsFeatureFlags() async {
        XCTAssertTrue(subject.state.featureFlags.isEmpty)

        let flag = DebugMenuFeatureFlag(
            feature: .testFeatureFlag,
            isEnabled: false,
        )

        configService.debugFeatureFlags = [flag]

        await subject.perform(.viewAppeared)

        XCTAssertTrue(subject.state.featureFlags.contains(flag))
    }

    /// `perform(.clearSsoCookies)` clears the SSO cookie and shows a success toast.
    @MainActor
    func test_perform_clearSsoCookies_success() async {
        let resolvedHostname = "vault.resolved.example.com"
        serverCommunicationConfigClientSingleton.resolveHostnameResult = resolvedHostname

        await subject.perform(.clearSsoCookies)

        XCTAssertEqual(
            serverCommunicationConfigClientSingleton.resolveHostnameReceivedHostname,
            environmentService.webVaultURL.host,
        )
        XCTAssertTrue(configService.clearServerCommCookieValueCalled)
        XCTAssertEqual(configService.clearServerCommCookieValueHostname, resolvedHostname)
        XCTAssertEqual(subject.state.toast?.title, Localizations.ssoCookiesCleared)
    }

    /// `perform(.clearSsoCookies)` logs an error when the clear operation fails.
    @MainActor
    func test_perform_clearSsoCookies_error() async {
        let resolvedHostname = "vault.resolved.example.com"
        serverCommunicationConfigClientSingleton.resolveHostnameResult = resolvedHostname
        configService.clearServerCommCookieValueError = BitwardenTestError.example

        await subject.perform(.clearSsoCookies)

        XCTAssertEqual(
            serverCommunicationConfigClientSingleton.resolveHostnameReceivedHostname,
            environmentService.webVaultURL.host,
        )
        XCTAssertTrue(configService.clearServerCommCookieValueCalled)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
        XCTAssertNil(subject.state.toast)
    }

    /// `perform(.refreshFeatureFlags)` refreshes the current feature flags.
    @MainActor
    func test_perform_refreshFeatureFlags() async {
        await subject.perform(.refreshFeatureFlags)
        XCTAssertTrue(configService.refreshDebugFeatureFlagsCalled)
    }

    /// `perform(.toggleFeatureFlag)` changes the state of the feature flag.
    @MainActor
    func test_perform_toggleFeatureFlag() async {
        let flag = DebugMenuFeatureFlag(
            feature: .testFeatureFlag,
            isEnabled: true,
        )

        await subject.perform(
            .toggleFeatureFlag(
                flag.feature.rawValue,
                false,
            ),
        )

        XCTAssertTrue(configService.toggleDebugFeatureFlagCalled)
    }

    /// `receive()` with `.generateErrorReport` sends an error report to the error reporter.
    @MainActor
    func test_receive_generateErrorReport() {
        subject.receive(.generateErrorReport)
        XCTAssertEqual(
            errorReporter.errors[safeIndex: 0] as? FlightRecorderError,
            FlightRecorderError.fileSizeError(
                NSError(
                    domain: "Generated Error",
                    code: 0,
                    userInfo: [
                        "AdditionalMessage": "Generated error report from debug view.",
                    ],
                ),
            ),
        )
    }

    /// `receive()` with `.generateSdkErrorReport` sends an SDK error report to the error reporter.
    @MainActor
    func test_receive_generateSdkErrorReport() {
        subject.receive(.generateSdkErrorReport)
        XCTAssertEqual(
            errorReporter.errors[safeIndex: 0] as? BitwardenSdk.BitwardenError,
            BitwardenSdk.BitwardenError.Api(ApiError.ResponseContent(
                message: "Generated SDK error report from debug view.",
            )),
        )
    }

    // MARK: Tests - ToastShown Action

    /// `receive()` with `.toastShown` updates the toast state.
    @MainActor
    func test_receive_toastShown() {
        let toast = Toast(title: "Test Toast")

        subject.receive(.toastShown(toast))

        XCTAssertEqual(subject.state.toast?.title, "Test Toast")
    }

    /// `receive()` with `.toastShown(nil)` clears the toast state.
    @MainActor
    func test_receive_toastShown_nil() {
        subject.state.toast = Toast(title: "Existing Toast")

        subject.receive(.toastShown(nil))

        XCTAssertNil(subject.state.toast)
    }
}
