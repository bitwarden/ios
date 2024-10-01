import XCTest

@testable import BitwardenShared

// MARK: - PasswordAutoFillProcessorTests

class PasswordAutoFillProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var autofillCredentialService: MockAutofillCredentialService!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var notificationCenterService: MockNotificationCenterService!
    var stateService: MockStateService!
    var subject: PasswordAutoFillProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        autofillCredentialService = MockAutofillCredentialService()
        configService = MockConfigService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        notificationCenterService = MockNotificationCenterService()
        stateService = MockStateService()
        subject = PasswordAutoFillProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                autofillCredentialService: autofillCredentialService,
                configService: configService,
                errorReporter: errorReporter,
                notificationCenterService: notificationCenterService,
                stateService: stateService
            ),
            state: .init(mode: .onboarding)
        )
    }

    override func tearDown() {
        super.tearDown()

        autofillCredentialService = nil
        configService = nil
        coordinator = nil
        errorReporter = nil
        notificationCenterService = nil
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

    /// `perform(.checkAutoFillOnForeground` will complete auth if autofill is enabled.
    ///
    @MainActor
    func test_perform_checkAutofillOnForeground_autofillEnabled() {
        autofillCredentialService.isAutofillCredentialsEnabled = true

        let task = Task {
            await subject.perform(.checkAutofillOnForeground)
        }
        defer { task.cancel() }

        notificationCenterService.willEnterForegroundSubject.send()
        waitFor(!coordinator.events.isEmpty)

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertTrue(stateService.setAccountSetupAutofillCalled)
    }

    /// `perform(_:)` with `.checkAutofillOnForeground` logs an error is setAccountSetupAutofill fails
    /// but we still complete auth via the coordinator.
    @MainActor
    func test_perform_checkAutofillOnForeground_error() {
        stateService.activeAccount = .fixture()
        autofillCredentialService.isAutofillCredentialsEnabled = true
        stateService.accountSetupAutofillError = BitwardenTestError.example

        let task = Task {
            await subject.perform(.checkAutofillOnForeground)
        }
        defer { task.cancel() }

        waitFor(!errorReporter.errors.isEmpty)

        XCTAssertTrue(stateService.setAccountSetupAutofillCalled)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
    }

    /// `perform(_:)` with `.turnAutoFillOnLaterButtonTapped` logs an error
    ///  if one occurs while saving the set up later flag.
    @MainActor
    func test_receive_setUpLater_error() async throws {
        stateService.activeAccount = .fixture()
        stateService.accountSetupAutofillError = BitwardenTestError.example
        await subject.perform(.turnAutoFillOnLaterButtonTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .setUpAutoFillLater {})

        try await alert.tapAction(title: Localizations.confirm)
        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }
}
