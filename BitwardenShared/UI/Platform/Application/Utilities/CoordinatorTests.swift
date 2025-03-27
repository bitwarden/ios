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

    class TestCoordinator: Coordinator, HasErrorAlertServices, HasStackNavigator {
        typealias Event = Void // swiftlint:disable:this nesting

        var errorAlertServices: ErrorAlertServices
        var stackNavigator: StackNavigator?

        init(mockStackNavigator: MockStackNavigator, services: ErrorAlertServices) {
            errorAlertServices = services
            stackNavigator = mockStackNavigator
        }

        func start() {}

        func navigate(to route: TestRoute, context: AnyObject?) {}
    }

    // MARK: Properties

    var configService: MockConfigService!
    var stackNavigator: MockStackNavigator!
    var subject: TestCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        stackNavigator = MockStackNavigator()

        subject = TestCoordinator(
            mockStackNavigator: stackNavigator,
            services: ServiceContainer.withMocks(configService: configService)
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        configService = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `showErrorAlert(error:services:)` builds an alert to show for an error when mobile error
    /// reporting is disabled.
    func test_showErrorAlert_mobileErrorReportingDisabled() async {
        configService.featureFlagsBool[.mobileErrorReporting] = false

        await subject.showErrorAlert(error: BitwardenTestError.example)

        XCTAssertEqual(stackNavigator.alerts, [Alert.networkResponseError(BitwardenTestError.example)])
    }

    /// `showErrorAlert(error:)` builds an alert to show for an error when mobile error
    /// reporting is enabled, allowing the user to share the details of the error.
    func test_showErrorAlert_mobileErrorReportingEnabled() async throws {
        configService.featureFlagsBool[.mobileErrorReporting] = true

        await subject.showErrorAlert(error: BitwardenTestError.example)

        XCTAssertEqual(
            stackNavigator.alerts,
            [Alert.networkResponseError(BitwardenTestError.example, shareErrorDetails: {})]
        )

        let alert = try XCTUnwrap(stackNavigator.alerts.first)
        try await alert.tapAction(title: Localizations.shareErrorDetails)

        // TODO: PM-18224 Show share sheet to export error details
    }

    /// `showErrorAlert(error:tryAgain:onDismissed:)` builds an alert to show for an error with an
    /// optional try again closure that allows trying again for certain types of errors.
    func test_showErrorAlert_withTryAgain() async throws {
        configService.featureFlagsBool[.mobileErrorReporting] = true

        var tryAgainCalled = false
        await subject.showErrorAlert(
            error: URLError(.timedOut),
            tryAgain: { tryAgainCalled = true },
            onDismissed: nil
        )

        XCTAssertEqual(
            stackNavigator.alerts,
            [Alert.networkResponseError(URLError(.timedOut), shareErrorDetails: {})]
        )
        let alert = stackNavigator.alerts[0]
        try await alert.tapAction(title: Localizations.tryAgain)
        XCTAssertTrue(tryAgainCalled)
    }

    /// `showErrorAlert(error:tryAgain:onDismissed:)` builds an alert to show for an error with an
    /// optional on dismissed closure that allows triggering an action after the alert was dismissed.
    func test_showErrorAlert_withOnDismissed() async throws {
        configService.featureFlagsBool[.mobileErrorReporting] = true

        var onDismissedCalled = false
        await subject.showErrorAlert(
            error: URLError(.timedOut),
            tryAgain: nil,
            onDismissed: { onDismissedCalled = true }
        )

        XCTAssertEqual(
            stackNavigator.alerts,
            [Alert.networkResponseError(URLError(.timedOut), shareErrorDetails: {})]
        )
        XCTAssertNotNil(stackNavigator.alertOnDismissed)

        stackNavigator.alertOnDismissed?()
        XCTAssertTrue(onDismissedCalled)
    }
}
