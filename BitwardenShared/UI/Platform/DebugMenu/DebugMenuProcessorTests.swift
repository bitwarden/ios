import XCTest

@testable import BitwardenShared

class DebugMenuProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<DebugMenuRoute, Void>!
    var subject: DebugMenuProcessor!

    // MARK: Set Up & Tear Down

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        configService = MockConfigService()
        coordinator = MockCoordinator<DebugMenuRoute, Void>()
        subject = DebugMenuProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                appSettingsStore: appSettingsStore,
                configService: configService
            ),
            state: DebugMenuState(featureFlags: [])
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        configService = nil
        coordinator = nil
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

        appSettingsStore.setFeatureFlag(
            name: FeatureFlag.emailVerification.rawValue,
            value: true
        )

        await subject.perform(.viewAppeared)

        let flag = DebugMenuFeatureFlag(
            feature: .emailVerification,
            isEnabled: true
        )

        XCTAssertTrue(subject.state.featureFlags.contains(flag))
        XCTAssertTrue(flag.isEnabled)
    }

    /// `perform(.refreshFeatureFlags)` refreshs the current feature flags.
    @MainActor
    func test_perform_refreshFeatureFlags() async {
        appSettingsStore.setFeatureFlag(
            name: FeatureFlag.emailVerification.rawValue,
            value: true
        )

        await subject.perform(.viewAppeared)

        XCTAssertTrue(
            subject.state.featureFlags.contains(
                .init(
                    feature: .emailVerification,
                    isEnabled: true
                )
            )
        )

        await subject.perform(.refreshFeatureFlags)

        for feature in FeatureFlag.allCases {
            XCTAssertTrue(
                subject.state.featureFlags.contains(
                    .init(
                        feature: feature,
                        isEnabled: false
                    )
                )
            )
        }
    }

    /// `perform(.toggleFeatureFlag)` changes the state of the feature flag.
    @MainActor
    func test_perform_toggleFeatureFlag() async {
        await subject.perform(.viewAppeared)

        let featureFlag = FeatureFlag.emailVerification

        await subject.perform(
            .toggleFeatureFlag(
                featureFlag.rawValue,
                true
            )
        )

        XCTAssertTrue(
            subject.state.featureFlags.contains(
                .init(
                    feature: featureFlag,
                    isEnabled: true
                )
            )
        )
    }
}
