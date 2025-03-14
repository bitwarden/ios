import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - CoordinatorTests

@MainActor
class CoordinatorTests: BitwardenTestCase {
    // MARK: Types

    enum TestRoute {
        case test
    }

    class TestCoordinator: Coordinator, HasStackNavigator {
        typealias Event = Void // swiftlint:disable:this nesting

        var stackNavigator: StackNavigator?

        init(mockStackNavigator: MockStackNavigator) {
            stackNavigator = mockStackNavigator
        }

        func start() {}

        func navigate(to route: TestRoute, context: AnyObject?) {}
    }

    // MARK: Properties

    var configService: MockConfigService!
    var services: Services!
    var stackNavigator: MockStackNavigator!
    var subject: TestCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        stackNavigator = MockStackNavigator()

        services = ServiceContainer.withMocks(configService: configService)

        subject = TestCoordinator(mockStackNavigator: stackNavigator)
    }

    override func tearDown() async throws {
        try await super.tearDown()

        configService = nil
        services = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `showErrorAlert(error:services:)` builds an alert to show for an error when mobile error
    /// reporting is disabled.
    func test_showErrorAlert_mobileErrorReportingDisabled() async {
        configService.featureFlagsBool[.mobileErrorReporting] = false

        await subject.showErrorAlert(
            error: BitwardenTestError.example,
            services: services
        )

        XCTAssertEqual(stackNavigator.alerts, [Alert.networkResponseError(BitwardenTestError.example)])
    }

    /// `showErrorAlert(error:services:)` builds an alert to show for an error when mobile error
    /// reporting is enabled, allowing the user to share the details of the error.
    func test_showErrorAlert_mobileErrorReportingEnabled() async throws {
        configService.featureFlagsBool[.mobileErrorReporting] = true

        await subject.showErrorAlert(
            error: BitwardenTestError.example,
            services: services
        )

        XCTAssertEqual(
            stackNavigator.alerts,
            [Alert.networkResponseError(BitwardenTestError.example, shareErrorDetails: {})]
        )

        let alert = try XCTUnwrap(stackNavigator.alerts.first)
        try await alert.tapAction(title: Localizations.shareErrorDetails)

        // TODO: PM-18224 Show share sheet to export error details
    }

    /// `showErrorAlert(error:services:tryAgain:)` builds an alert to show for an error with an
    /// optional try again closure that allows trying again for certain types of errors.
    func test_showErrorAlert_withTryAgain() async throws {
        configService.featureFlagsBool[.mobileErrorReporting] = true

        var tryAgainCalled = false
        await subject.showErrorAlert(
            error: URLError(.timedOut),
            services: services,
            tryAgain: { tryAgainCalled = true }
        )

        XCTAssertEqual(
            stackNavigator.alerts,
            [Alert.networkResponseError(URLError(.timedOut), shareErrorDetails: {})]
        )
        let alert = stackNavigator.alerts[0]
        try await alert.tapAction(title: Localizations.tryAgain)
        XCTAssertTrue(tryAgainCalled)
    }
}
