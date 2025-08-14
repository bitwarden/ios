import BitwardenKitMocks
import BitwardenResources
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

    var errorReportBuilder: MockErrorReportBuilder!
    var stackNavigator: MockStackNavigator!
    var subject: TestCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReportBuilder = MockErrorReportBuilder()
        stackNavigator = MockStackNavigator()

        subject = TestCoordinator(
            mockStackNavigator: stackNavigator,
            services: ServiceContainer.withMocks(
                errorReportBuilder: errorReportBuilder
            )
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        errorReportBuilder = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `showErrorAlert(error:)` builds an alert to show for an error, which allows the user to
    /// share the details of the error.
    @MainActor
    func test_showErrorAlert() async throws {
        let rootViewController = UIViewController()
        stackNavigator.rootViewController = rootViewController
        setKeyWindowRoot(viewController: rootViewController)

        await subject.showErrorAlert(error: BitwardenTestError.example)

        XCTAssertEqual(
            stackNavigator.alerts,
            [Alert.networkResponseError(BitwardenTestError.example, shareErrorDetails: {})]
        )

        let alert = try XCTUnwrap(stackNavigator.alerts.first)
        try await alert.tapAction(title: Localizations.shareErrorDetails)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view as? UIViewController is UIActivityViewController)

        XCTAssertEqual(errorReportBuilder.buildShareErrorLogError as? BitwardenTestError, .example)
        XCTAssertEqual(errorReportBuilder.buildShareErrorLogCallStack?.isEmpty, false)
    }

    /// `showErrorAlert(error:tryAgain:onDismissed:)` builds an alert to show for an error with an
    /// optional try again closure that allows trying again for certain types of errors.
    func test_showErrorAlert_withTryAgain() async throws {
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
