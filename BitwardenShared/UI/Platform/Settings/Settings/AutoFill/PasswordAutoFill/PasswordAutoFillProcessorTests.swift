import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Foundation
import TestHelpers
import Testing

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

@MainActor
struct PasswordAutoFillProcessorTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let asSettingsMediator: MockASSettingsMediator
    let autofillCredentialService: MockAutofillCredentialService
    let coordinator: MockCoordinator<PasswordAutofillRoute, PasswordAutofillEvent>
    let delegate: MockPasswordAutoFillProcessorDelegate
    let errorReporter: MockErrorReporter
    let notificationCenterService: MockNotificationCenterService
    let stateService: MockStateService
    let subject: PasswordAutoFillProcessor

    // MARK: Initialization

    init() {
        asSettingsMediator = MockASSettingsMediator()
        autofillCredentialService = MockAutofillCredentialService()
        coordinator = MockCoordinator()
        delegate = MockPasswordAutoFillProcessorDelegate()
        errorReporter = MockErrorReporter()
        notificationCenterService = MockNotificationCenterService()
        stateService = MockStateService()
        stateService.activeAccount = .fixture()
        subject = PasswordAutoFillProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                asSettingsMediator: asSettingsMediator,
                autofillCredentialService: autofillCredentialService,
                errorReporter: errorReporter,
                notificationCenterService: notificationCenterService,
                stateService: stateService,
            ),
            state: .init(mode: .onboarding),
        )
    }

    // MARK: Tests - Onboarding

    /// `perform(_:)` with `.checkAutofillOnForeground` completes onboarding if autofill is enabled
    /// when the app is foregrounded in the onboarding flow, without notifying the delegate.
    @Test
    func perform_checkAutofillOnForeground_onboarding_autofillEnabled() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = true

        let task = Task {
            await subject.perform(.checkAutofillOnForeground)
        }
        defer { task.cancel() }

        try await waitForAsync { !coordinator.events.isEmpty }

        #expect(coordinator.events == [.didCompleteAuth])
        #expect(coordinator.routes.isEmpty)
        #expect(stateService.accountSetupAutofill["1"] == .complete)
        #expect(!delegate.didEnableAutofillCalled)
    }

    /// `perform(_:)` with `.checkAutofillOnForeground` keeps the onboarding step on screen if
    /// autofill is still off when the app is foregrounded without returning from Settings, and
    /// completes onboarding once autofill is enabled.
    @Test
    func perform_checkAutofillOnForeground_onboarding_autofillOff() async throws {
        let task = Task {
            await subject.perform(.checkAutofillOnForeground)
        }
        defer { task.cancel() }

        notificationCenterService.willEnterForegroundSubject.send()
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(coordinator.events.isEmpty)

        autofillCredentialService.isAutofillCredentialsEnabled = true
        notificationCenterService.willEnterForegroundSubject.send()
        try await waitForAsync { !coordinator.events.isEmpty }

        #expect(coordinator.events == [.didCompleteAuth])
    }

    /// `perform(_:)` with `.continueTapped` on iOS 18+ in the onboarding flow requests to turn on
    /// the credential provider and completes onboarding whatever the request returns, without
    /// notifying the delegate or showing a toast. The autofill setup progress is updated based on
    /// whether autofill is on.
    @available(iOS 18, *)
    @Test(arguments: [true, false])
    func perform_continueTapped_onboarding_iOS18(isCredentialProviderOn: Bool) async {
        autofillCredentialService.isAutofillCredentialsEnabled = isCredentialProviderOn
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionReturnValue = isCredentialProviderOn

        await subject.perform(.continueTapped)

        #expect(asSettingsMediator.requestToTurnOnCredentialProviderExtensionCalled)
        #expect(!delegate.didEnableAutofillCalled)
        #expect(stateService.accountSetupAutofill["1"] == (isCredentialProviderOn ? .complete : .setUpLater))
        #expect(coordinator.events == [.didCompleteAuth])
        #expect(coordinator.routes.isEmpty)
        #expect(coordinator.toastsShown.isEmpty)
    }

    /// `perform(_:)` with `.continueTapped` on iOS 18+ in the onboarding flow falls back to opening
    /// the credential provider settings if the request can't be made, and completes onboarding
    /// when the app returns to the foreground.
    @available(iOS 18, *)
    @Test
    func perform_continueTapped_onboarding_iOS18_cantRequest() async throws {
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionThrowableError =
            ASSettingsMediatorError.cantRequest

        await subject.perform(.continueTapped)

        #expect(asSettingsMediator.openCredentialProviderAppSettingsCalled)
        #expect(errorReporter.errors.isEmpty)
        #expect(coordinator.events.isEmpty)

        let task = Task {
            await subject.perform(.checkAutofillOnForeground)
        }
        defer { task.cancel() }

        try await waitForAsync { !coordinator.events.isEmpty }

        #expect(coordinator.events == [.didCompleteAuth])
        #expect(stateService.accountSetupAutofill["1"] == .setUpLater)
    }

    /// `perform(_:)` with `.continueTapped` on iOS 18+ in the onboarding flow logs an error and
    /// stays on the screen if the request can't be made and opening the credential provider
    /// settings fails.
    @available(iOS 18, *)
    @Test
    func perform_continueTapped_onboarding_iOS18_cantRequest_openSettingsError() async {
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionThrowableError =
            ASSettingsMediatorError.cantRequest
        asSettingsMediator.openCredentialProviderAppSettingsThrowableError = BitwardenTestError.example

        await subject.perform(.continueTapped)

        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
        #expect(coordinator.events.isEmpty)
    }

    /// `perform(_:)` with `.continueTapped` on iOS 18+ in the onboarding flow logs an error and
    /// completes onboarding if the request fails.
    @available(iOS 18, *)
    @Test
    func perform_continueTapped_onboarding_iOS18_error() async {
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionThrowableError = BitwardenTestError.example

        await subject.perform(.continueTapped)

        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
        #expect(coordinator.events == [.didCompleteAuth])
    }

    /// `perform(_:)` with `.continueTapped` on iOS 17 in the onboarding flow opens the credential
    /// provider settings and completes onboarding when the app returns to the foreground.
    @Test
    func perform_continueTapped_onboarding_iOS17() async throws {
        guard #available(iOS 17, *) else { return }
        guard #unavailable(iOS 18) else { return }

        await subject.perform(.continueTapped)

        #expect(asSettingsMediator.openCredentialProviderAppSettingsCalled)
        #expect(coordinator.events.isEmpty)

        let task = Task {
            await subject.perform(.checkAutofillOnForeground)
        }
        defer { task.cancel() }

        try await waitForAsync { !coordinator.events.isEmpty }

        #expect(coordinator.events == [.didCompleteAuth])
    }

    /// `perform(_:)` with `.continueTapped` on iOS 17 in the onboarding flow logs an error if
    /// opening the credential provider settings fails and stays on the screen.
    @Test
    func perform_continueTapped_onboarding_iOS17_error() async {
        guard #available(iOS 17, *) else { return }
        guard #unavailable(iOS 18) else { return }

        asSettingsMediator.openCredentialProviderAppSettingsThrowableError = BitwardenTestError.example

        await subject.perform(.continueTapped)

        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
        #expect(coordinator.events.isEmpty)
    }

    /// `perform(_:)` with `.continueTapped` on iOS 15 and 16 in the onboarding flow opens the password
    /// options settings and completes onboarding when the app returns to the foreground.
    @Test
    func perform_continueTapped_onboarding_preIOS17() async throws {
        guard #unavailable(iOS 17) else { return }

        await subject.perform(.continueTapped)

        #expect(subject.state.url == ExternalLinksConstants.passwordOptions)
        #expect(coordinator.events.isEmpty)

        let task = Task {
            await subject.perform(.checkAutofillOnForeground)
        }
        defer { task.cancel() }

        try await waitForAsync { !coordinator.events.isEmpty }

        #expect(coordinator.events == [.didCompleteAuth])
    }

    /// `perform(_:)` with `.turnAutoFillOnLaterButtonTapped` shows an alert confirming the user
    /// wants to turn on autofill later, and completes onboarding once confirmed, setting the
    /// autofill setup progress to `.setUpLater`.
    @Test
    func perform_turnAutoFillOnLaterButtonTapped() async throws {
        await subject.perform(.turnAutoFillOnLaterButtonTapped)

        let alert = try #require(coordinator.alertShown.last)
        #expect(alert == .setUpAutoFillLater {})

        try await alert.tapAction(title: Localizations.cancel)
        #expect(coordinator.events.isEmpty)

        try await alert.tapAction(title: Localizations.confirm)
        #expect(coordinator.events == [.didCompleteAuth])
        #expect(stateService.accountSetupAutofill["1"] == .setUpLater)
        #expect(!delegate.didEnableAutofillCalled)
    }

    /// `perform(_:)` with `.turnAutoFillOnLaterButtonTapped` only completes onboarding once if
    /// the alert is confirmed multiple times.
    @Test
    func perform_turnAutoFillOnLaterButtonTapped_multipleConfirms() async throws {
        await subject.perform(.turnAutoFillOnLaterButtonTapped)
        await subject.perform(.turnAutoFillOnLaterButtonTapped)

        #expect(coordinator.alertShown.count == 2)
        for alert in coordinator.alertShown {
            try await alert.tapAction(title: Localizations.confirm)
        }

        #expect(coordinator.events == [.didCompleteAuth])
    }

    /// `perform(_:)` with `.turnAutoFillOnLaterButtonTapped` logs an error and still completes
    /// onboarding if updating the autofill setup progress fails.
    @Test
    func perform_turnAutoFillOnLaterButtonTapped_error() async throws {
        stateService.accountSetupAutofillError = BitwardenTestError.example

        await subject.perform(.turnAutoFillOnLaterButtonTapped)
        let alert = try #require(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.confirm)

        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
        #expect(coordinator.events == [.didCompleteAuth])
    }

    // MARK: Tests - Settings

    /// `perform(_:)` with `.checkAutofillOnForeground` will dismiss the view if autofill is
    /// enabled when the app is foregrounded in the settings flow.
    @Test
    func perform_checkAutofillOnForeground_settings_autofillEnabled() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = true
        subject.state.mode = .settings
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let task = Task {
            await subject.perform(.checkAutofillOnForeground)
        }
        defer { task.cancel() }

        try await waitForAsync { !coordinator.routes.isEmpty }

        #expect(coordinator.events.isEmpty)
        #expect(coordinator.routes == [.dismiss])
        #expect(stateService.accountSetupAutofill["1"] == .complete)
        #expect(delegate.didEnableAutofillCalled)
    }

    /// `perform(_:)` with `.checkAutofillOnForeground` in the settings flow logs an error if
    /// saving the account setup progress fails but still dismisses the view.
    @Test
    func perform_checkAutofillOnForeground_settings_error() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = true
        subject.state.mode = .settings
        stateService.activeAccount = .fixture()
        stateService.accountSetupAutofillError = BitwardenTestError.example

        let task = Task {
            await subject.perform(.checkAutofillOnForeground)
        }
        defer { task.cancel() }

        try await waitForAsync { !coordinator.routes.isEmpty }

        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
        #expect(coordinator.routes == [.dismiss])
        #expect(!delegate.didEnableAutofillCalled)
    }

    /// `perform(_:)` with `.continueTapped` on iOS 18+ in the settings flow opens the credential
    /// provider settings if the request can't be made.
    @available(iOS 18, *)
    @Test
    func perform_continueTapped_settings_iOS18_cantRequest() async {
        subject.state.mode = .settings
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionThrowableError =
            ASSettingsMediatorError.cantRequest

        await subject.perform(.continueTapped)

        #expect(asSettingsMediator.openCredentialProviderAppSettingsCalled)
        #expect(coordinator.routes.isEmpty)
        #expect(coordinator.events.isEmpty)
    }

    /// `perform(_:)` with `.continueTapped` on iOS 18+ in the settings flow sets the autofill setup
    /// progress to `.setUpLater` and dismisses the view if the credential provider is turned off.
    @available(iOS 18, *)
    @Test
    func perform_continueTapped_settings_iOS18_credentialProviderOff() async {
        subject.state.mode = .settings
        stateService.activeAccount = .fixture()
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionReturnValue = false

        await subject.perform(.continueTapped)

        #expect(!delegate.didEnableAutofillCalled)
        #expect(stateService.accountSetupAutofill["1"] == .setUpLater)
        #expect(coordinator.routes == [.dismiss])
        #expect(coordinator.events.isEmpty)
    }

    /// `perform(_:)` with `.continueTapped` on iOS 18+ in the settings flow notifies the delegate
    /// and dismisses the view if the credential provider is turned on.
    @available(iOS 18, *)
    @Test
    func perform_continueTapped_settings_iOS18_credentialProviderOn() async {
        subject.state.mode = .settings
        stateService.activeAccount = .fixture()
        autofillCredentialService.isAutofillCredentialsEnabled = true
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionReturnValue = true

        await subject.perform(.continueTapped)

        #expect(delegate.didEnableAutofillCalled)
        #expect(stateService.accountSetupAutofill["1"] == .complete)
        #expect(coordinator.routes == [.dismiss])
        #expect(coordinator.events.isEmpty)
    }

    /// `perform(_:)` with `.continueTapped` on iOS 17 in the settings flow opens the credential
    /// provider settings.
    @Test
    func perform_continueTapped_settings_iOS17() async {
        guard #available(iOS 17, *) else { return }
        guard #unavailable(iOS 18) else { return }

        subject.state.mode = .settings

        await subject.perform(.continueTapped)

        #expect(asSettingsMediator.openCredentialProviderAppSettingsCalled)
    }

    /// `perform(_:)` with `.continueTapped` on iOS 15 and 16 in the settings flow sets the URL to
    /// the password options.
    @Test
    func perform_continueTapped_settings_preIOS17() async {
        guard #unavailable(iOS 17) else { return }

        subject.state.mode = .settings

        await subject.perform(.continueTapped)

        #expect(subject.state.url == ExternalLinksConstants.passwordOptions)
    }

    // MARK: Tests - Common

    /// `receive(_:)` with `.clearURL` clears the URL in the state.
    @Test
    func receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        #expect(subject.state.url == nil)
    }
} // swiftlint:disable:this file_length
