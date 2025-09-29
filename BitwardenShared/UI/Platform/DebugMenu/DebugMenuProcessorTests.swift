import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class DebugMenuProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<DebugMenuRoute, Void>!
    var errorReporter: MockErrorReporter!
    var subject: DebugMenuProcessor!

    // MARK: Set Up & Tear Down

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        coordinator = MockCoordinator<DebugMenuRoute, Void>()
        errorReporter = MockErrorReporter()
        subject = DebugMenuProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                configService: configService,
                errorReporter: errorReporter
            ),
            state: DebugMenuState(featureFlags: [])
        )
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        coordinator = nil
        errorReporter = nil
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
            isEnabled: false
        )

        configService.debugFeatureFlags = [flag]

        await subject.perform(.viewAppeared)

        XCTAssertTrue(subject.state.featureFlags.contains(flag))
    }

    /// `perform(.refreshFeatureFlags)` refreshs the current feature flags.
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
            isEnabled: true
        )

        await subject.perform(
            .toggleFeatureFlag(
                flag.feature.rawValue,
                false
            )
        )

        XCTAssertTrue(configService.toggleDebugFeatureFlagCalled)
    }

    /// `receive()` with `.generateErrorReport` generates error reports on the error reporter.
    @MainActor
    func test_receive_generateErrorReport() {
        subject.receive(.generateErrorReport)
        XCTAssertEqual(
            errorReporter.errors[0] as? BitwardenSdk.BitwardenError,
            BitwardenSdk.BitwardenError.E(
                message: "Generated error report from debug view."
            )
        )
        XCTAssertEqual(
            errorReporter.errors[1] as? KeychainServiceError,
            KeychainServiceError.osStatusError(1)
        )
    }
}
