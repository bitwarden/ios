import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Foundation
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - MockPasswordAutoFillProcessorDelegate

class MockPasswordAutoFillProcessorDelegate: PasswordAutoFillProcessorDelegate {
    var didEnableAutofillCalled = false

    func didEnableAutofill() {
        didEnableAutofillCalled = true
    }
}

// MARK: - PasswordAutoFillProcessorTests

class PasswordAutoFillProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var asSettingsMediator: MockASSettingsMediator!
    var autofillCredentialService: MockAutofillCredentialService!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<PasswordAutofillRoute, PasswordAutofillEvent>!
    var delegate: MockPasswordAutoFillProcessorDelegate!
    var errorReporter: MockErrorReporter!
    var notificationCenterService: MockNotificationCenterService!
    var stateService: MockStateService!
    var subject: PasswordAutoFillProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        asSettingsMediator = MockASSettingsMediator()
        autofillCredentialService = MockAutofillCredentialService()
        configService = MockConfigService()
        coordinator = MockCoordinator()
        delegate = MockPasswordAutoFillProcessorDelegate()
        errorReporter = MockErrorReporter()
        notificationCenterService = MockNotificationCenterService()
        stateService = MockStateService()
        subject = PasswordAutoFillProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                asSettingsMediator: asSettingsMediator,
                autofillCredentialService: autofillCredentialService,
                configService: configService,
                errorReporter: errorReporter,
                notificationCenterService: notificationCenterService,
                stateService: stateService,
            ),
            state: .init(mode: .onboarding),
        )
    }

    override func tearDown() {
        super.tearDown()

        asSettingsMediator = nil
        autofillCredentialService = nil
        configService = nil
        coordinator = nil
        delegate = nil
        errorReporter = nil
        notificationCenterService = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

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
    func test_perform_checkAutofillOnForeground_autofillEnabled_onboarding() {
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

    /// `perform(_:)` with `.checkAutoFillOnForeground` will dismiss the view if autofill is
    /// enabled when the app is foregrounded in the settings flow.
    @MainActor
    func test_perform_checkAutofillOnForeground_autofillEnabled_settings() {
        autofillCredentialService.isAutofillCredentialsEnabled = true
        subject.state.mode = .settings
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let task = Task {
            await subject.perform(.checkAutofillOnForeground)
        }
        defer { task.cancel() }

        notificationCenterService.willEnterForegroundSubject.send()
        waitFor(!coordinator.routes.isEmpty)

        XCTAssertTrue(coordinator.events.isEmpty)
        XCTAssertEqual(coordinator.routes, [.dismiss])
        XCTAssertTrue(stateService.setAccountSetupAutofillCalled)
        XCTAssertTrue(delegate.didEnableAutofillCalled)
    }

    /// `perform(_:)` with `.checkAutofillOnForeground` calls the delegate when autofill is successfully enabled.
    @MainActor
    func test_perform_checkAutofillOnForeground_callsDelegate() {
        autofillCredentialService.isAutofillCredentialsEnabled = true
        stateService.activeAccount = .fixture()

        let task = Task {
            await subject.perform(.checkAutofillOnForeground)
        }
        defer { task.cancel() }

        notificationCenterService.willEnterForegroundSubject.send()
        waitFor(delegate.didEnableAutofillCalled)

        XCTAssertTrue(delegate.didEnableAutofillCalled)
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
        XCTAssertFalse(delegate.didEnableAutofillCalled)
    }

    /// `perform(_:)` with `.continueTapped` opens the verification code settings on iOS 17.
    @MainActor
    func test_perform_continueTapped_iOS17() async {
        guard #available(iOS 17, *) else { return }
        guard #unavailable(iOS 18) else { return }

        await subject.perform(.continueTapped)

        XCTAssertTrue(asSettingsMediator.openVerificationCodeAppSettingsCalled)
    }

    /// `perform(_:)` with `.continueTapped` sets a URL for older iOS versions.
    @MainActor
    func test_perform_continueTapped_preIOS17() async {
        guard #unavailable(iOS 17) else { return }

        await subject.perform(.continueTapped)

        XCTAssertEqual(subject.state.url, ExternalLinksConstants.passwordOptions)
    }

    /// `perform(_:)` with `.continueTapped` on iOS 18 and `.cantRequest` opens the app settings.
    @MainActor
    func test_perform_continueTapped_iOS18_cantRequest() async {
        guard #available(iOS 18, *) else { return }

        // swiftlint:disable:next line_length
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionThrowableError = ASSettingsMediatorError.cantRequest

        await subject.perform(.continueTapped)

        XCTAssertTrue(asSettingsMediator.openVerificationCodeAppSettingsCalled)
    }

    /// `perform(_:)` with `.continueTapped` on iOS 18 and credential provider turned on checks
    /// autofill completion and calls the delegate.
    @MainActor
    func test_perform_continueTapped_iOS18_credentialProviderOn() async {
        guard #available(iOS 18, *) else { return }

        stateService.activeAccount = .fixture()
        autofillCredentialService.isAutofillCredentialsEnabled = true
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionReturnValue = true

        await subject.perform(.continueTapped)

        XCTAssertTrue(delegate.didEnableAutofillCalled)
        XCTAssertEqual(stateService.accountSetupAutofill["1"], .complete)
    }

    /// `perform(_:)` with `.continueTapped` on iOS 18 and credential provider turned off sets
    /// setup to `.setUpLater` and navigates on completion.
    @MainActor
    func test_perform_continueTapped_iOS18_credentialProviderOff() async {
        guard #available(iOS 18, *) else { return }

        stateService.activeAccount = .fixture()
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionReturnValue = false

        await subject.perform(.continueTapped)

        XCTAssertFalse(delegate.didEnableAutofillCalled)
        XCTAssertEqual(stateService.accountSetupAutofill["1"], .setUpLater)
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

    /// `receive(_:)` with `.clearURL` clears the URL in the state.
    @MainActor
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }
}
