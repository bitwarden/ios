import XCTest

@testable import BitwardenShared

// MARK: - PasswordAutoFillProcessorTests

class PasswordAutoFillProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: PasswordAutoFillProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        subject = PasswordAutoFillProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                configService: configService,
                errorReporter: errorReporter,
                stateService: stateService
            ),
            state: .init(mode: .onboarding)
        )
    }

    override func tearDown() {
        configService = nil
        coordinator = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(.appeared)` with feature flag for .nativeCreateAccountFlow set to true
    @MainActor
    func test_perform_appeared_loadFeatureFlag_true() async {
        configService.featureFlagsBool[.nativeCreateAccountFlow] = true
        subject.state.nativeCreateAccountFeatureFlag = false

        await subject.perform(.appeared)
        XCTAssertTrue(subject.state.nativeCreateAccountFeatureFlag)
    }

    /// `perform(.appeared)` with feature flag for .nativeCreateAccountFlow set to false
    @MainActor
    func test_perform_appeared_loadsFeatureFlag_false() async {
        configService.featureFlagsBool[.nativeCreateAccountFlow] = false
        subject.state.nativeCreateAccountFeatureFlag = true

        await subject.perform(.appeared)
        XCTAssertFalse(subject.state.nativeCreateAccountFeatureFlag)
    }

    /// `perform(.appeared)` with feature flag defaulting to false
    @MainActor
    func test_perform_appeared_loadsFeatureFlag_nil() async {
        configService.featureFlagsBool[.nativeCreateAccountFlow] = nil
        subject.state.nativeCreateAccountFeatureFlag = true

        await subject.perform(.appeared)
        XCTAssertFalse(subject.state.nativeCreateAccountFeatureFlag)
    }

    /// `perform(.turnAutoFillOnLaterButtonTapped)` will show an alert  the status to `setupLater`
    ///   /// `receive(_:)` with `.setUpLater` shows an alert confirming the user wants to skip unlock
    /// setup and then navigates to autofill setup.
    @MainActor
    func test_perform_turnAutoFillOnLaterTapped() async throws {
        stateService.activeAccount = .fixture()

        await subject.perform(.turnAutoFillOnLaterButtonTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .setUpAutoFillLater {})

        try await alert.tapAction(title: Localizations.cancel)
        XCTAssertTrue(coordinator.routes.isEmpty)

        try await alert.tapAction(title: Localizations.confirm)
        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertEqual(stateService.accountSetupAutofill["1"], .setUpLater)
    }

    /// `perform(_:)` with `.turnAutoFillOnLaterButtonTapped` logs an error
    ///  if one occurs while saving the set up later flag.
    @MainActor
    func test_receive_setUpLater_error() async throws {
        await subject.perform(.turnAutoFillOnLaterButtonTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .setUpAutoFillLater {})

        try await alert.tapAction(title: Localizations.confirm)
        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }
}
