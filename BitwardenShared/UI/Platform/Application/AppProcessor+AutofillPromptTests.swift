// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import Combine
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AppProcessorAutofillPromptTests

@MainActor
final class AppProcessorAutofillPromptTests {
    // MARK: Properties

    let appModule: MockAppModule
    let autofillCredentialService: MockAutofillCredentialService
    let autofillPromptService: MockAutofillPromptService
    let configService: MockConfigService
    let notificationCenterService: MockNotificationCenterService
    let serverCommunicationConfigAPIService: MockServerCommunicationConfigAPIService
    let stateService: MockStateService
    var willEnterForegroundCalled = 0

    // MARK: Initialization

    init() {
        appModule = MockAppModule()
        appModule.appCoordinator = MockCoordinator()
        appModule.authRouter = MockRouter(routeForEvent: { _ in .landing })
        autofillCredentialService = MockAutofillCredentialService()
        autofillPromptService = MockAutofillPromptService()
        configService = MockConfigService()
        notificationCenterService = MockNotificationCenterService()
        serverCommunicationConfigAPIService = MockServerCommunicationConfigAPIService()
        serverCommunicationConfigAPIService.acquireCookiesPublisherReturnValue =
            CurrentValueSubject<String?, Never>(nil).eraseToAnyPublisher()
        stateService = MockStateService()

        autofillCredentialService.isAutofillCredentialsEnabled = true
        stateService.activeAccount = .fixture()
        stateService.accounts = [.fixture()]
        stateService.accountSetupAutofill["1"] = .setUpLater
    }

    // MARK: Tests

    /// `init()` refreshes the autofill status each time the app enters the foreground when the
    /// autofill off action card is enabled.
    @Test
    func init_appForeground_flagEnabled_refreshesAutofillStatus() async throws {
        configService.featureFlagsBool[.autofillOffActionCard] = true
        let subject = makeSubject()
        // The mock publisher emits when subscribed, simulating the first foreground event.
        try await waitForAsync { self.willEnterForegroundCalled == 1 }
        #expect(autofillPromptService.refreshAutofillStatusCallsCount == 1)

        notificationCenterService.willEnterForegroundSubject.send()
        try await waitForAsync { self.willEnterForegroundCalled == 2 }

        #expect(autofillPromptService.refreshAutofillStatusCallsCount == 2)
        _ = subject
    }

    /// `init()` doesn't refresh the autofill status when entering the foreground if the autofill
    /// off action card is disabled.
    @Test
    func init_appForeground_flagDisabled_doesNotRefreshAutofillStatus() async throws {
        let subject = makeSubject()
        try await waitForAsync { self.willEnterForegroundCalled == 1 }

        #expect(!autofillPromptService.refreshAutofillStatusCalled)
        _ = subject
    }

    /// `init()` doesn't refresh the autofill status when entering the foreground in an app extension.
    @Test
    func init_appForeground_appExtension_doesNotRefreshAutofillStatus() async throws {
        configService.featureFlagsBool[.autofillOffActionCard] = true
        let delegate = MockAppExtensionDelegate()
        delegate.isInAppExtension = true
        let subject = makeSubject(appExtensionDelegate: delegate)
        try await waitForAsync { self.willEnterForegroundCalled == 1 }

        #expect(!autofillPromptService.refreshAutofillStatusCalled)
        _ = subject
    }

    /// `init()` doesn't complete the user's autofill setup when entering the foreground if the
    /// autofill off action card is enabled.
    @Test
    func init_appForeground_flagEnabled_doesNotCompleteAutofillAccountSetup() async throws {
        configService.featureFlagsBool[.autofillOffActionCard] = true
        let subject = makeSubject()
        try await waitForAsync { self.willEnterForegroundCalled == 1 }

        notificationCenterService.willEnterForegroundSubject.send()
        try await waitForAsync { self.willEnterForegroundCalled == 2 }

        #expect(stateService.accountSetupAutofill == ["1": .setUpLater])
        _ = subject
    }

    /// `start(appContext:navigator:window:)` refreshes the autofill status instead of completing
    /// the user's autofill setup when the autofill off action card is enabled.
    @Test
    func start_flagEnabled_refreshesAutofillStatus() async throws {
        configService.featureFlagsBool[.autofillOffActionCard] = true
        let subject = makeSubject()

        await subject.start(appContext: .mainApp, navigator: MockRootNavigator(), window: nil)

        #expect(autofillPromptService.refreshAutofillStatusCalled)
        #expect(stateService.accountSetupAutofill == ["1": .setUpLater])
    }

    /// `start(appContext:navigator:window:)` doesn't refresh the autofill status in an app extension.
    @Test
    func start_flagEnabled_appExtension_doesNotRefreshAutofillStatus() async throws {
        configService.featureFlagsBool[.autofillOffActionCard] = true
        let delegate = MockAppExtensionDelegate()
        delegate.isInAppExtension = true
        let subject = makeSubject(appExtensionDelegate: delegate)

        await subject.start(appContext: .appExtension, navigator: MockRootNavigator(), window: nil)

        #expect(!autofillPromptService.refreshAutofillStatusCalled)
    }

    /// `start(appContext:navigator:window:)` completes the user's autofill setup and doesn't
    /// refresh the autofill status when the autofill off action card is disabled.
    @Test
    func start_flagDisabled_completesAutofillAccountSetup() async throws {
        let subject = makeSubject()

        await subject.start(appContext: .mainApp, navigator: MockRootNavigator(), window: nil)

        #expect(!autofillPromptService.refreshAutofillStatusCalled)
        #expect(stateService.accountSetupAutofill == ["1": .complete])
    }

    // MARK: Private

    /// Creates the `AppProcessor` under test.
    ///
    /// - Parameter appExtensionDelegate: The app extension delegate, if running in an extension.
    /// - Returns: The `AppProcessor` under test.
    ///
    private func makeSubject(appExtensionDelegate: AppExtensionDelegate? = nil) -> AppProcessor {
        AppProcessor(
            appExtensionDelegate: appExtensionDelegate,
            appModule: appModule,
            debugWillEnterForeground: { [weak self] in self?.willEnterForegroundCalled += 1 },
            services: ServiceContainer.withMocks(
                autofillCredentialService: autofillCredentialService,
                autofillPromptService: autofillPromptService,
                configService: configService,
                notificationCenterService: notificationCenterService,
                serverCommunicationConfigAPIService: serverCommunicationConfigAPIService,
                stateService: stateService,
            ),
        )
    }
}
