import XCTest

@testable import BitwardenShared

class SingleSignOnProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute>!
    var errorReporter: MockErrorReporter!
    var subject: SingleSignOnProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<AuthRoute>()
        errorReporter = MockErrorReporter()
        let services = ServiceContainer.withMocks(
            errorReporter: errorReporter
        )
        subject = SingleSignOnProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: SingleSignOnState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.loginPressed` displays an alert if organization identifier field is invalid.
    func test_perform_loginPressed_invalidIdentifier() async throws {
        subject.state.identifierText = "    "

        await subject.perform(.loginTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.validationFieldRequired(Localizations.orgIdentifier),
                alertActions: [AlertAction(title: Localizations.ok, style: .default)]
            )
        )
    }

    /// `perform(_:)` with `.loginPressed` attempts to login.
    func test_perform_loginPressed_success() async throws {
        subject.state.identifierText = "TestIdentifier"

        await subject.perform(.loginTapped)

        // TODO: BIT-1308

        XCTAssertEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loggingIn))
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.identifierTextChanged(_:)` updates the state.
    func test_receive_identifierTextChanged() {
        subject.state.identifierText = ""
        XCTAssertTrue(subject.state.identifierText.isEmpty)

        subject.receive(.identifierTextChanged("updated name"))
        XCTAssertTrue(subject.state.identifierText == "updated name")
    }
}
