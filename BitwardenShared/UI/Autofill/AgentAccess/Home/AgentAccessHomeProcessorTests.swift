import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Combine
import TestHelpers
import Testing
import UIKit
import UserNotifications

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AgentAccessHomeProcessorTests

@MainActor
struct AgentAccessHomeProcessorTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let agentAccessRepository: MockAgentAccessRepository
    let coordinator: MockCoordinator<AgentAccessRoute, Void>
    let errorReporter: MockErrorReporter
    let notificationService: MockNotificationService
    let subject: AgentAccessHomeProcessor

    // MARK: Initialization

    init() {
        agentAccessRepository = MockAgentAccessRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        notificationService = MockNotificationService()
        notificationService.authorizationStatus = .authorized

        subject = AgentAccessHomeProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                agentAccessRepository: agentAccessRepository,
                errorReporter: errorReporter,
                notificationService: notificationService,
            ),
            state: AgentAccessHomeState(),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` loads the saved values.
    @Test
    func perform_appeared() async {
        agentAccessRepository.isListeningEnabledReturnValue = true
        agentAccessRepository.relayURLReturnValue = "wss://relay.example.com"
        agentAccessRepository.autoApproveRulesReturnValue = [AgentAccessUIFixtures.autoApproveRule()]
        agentAccessRepository.connectionsReturnValue = [
            AgentAccessUIFixtures.connection(),
            AgentAccessUIFixtures.connection(fingerprint: String(repeating: "cd", count: 32)),
        ]

        await subject.perform(.appeared)

        #expect(subject.state.isListeningEnabled)
        #expect(subject.state.relayURL == "wss://relay.example.com")
        #expect(subject.state.relayURLInput == "wss://relay.example.com")
        #expect(subject.state.autoApproveRules == [AgentAccessUIFixtures.autoApproveRule()])
        #expect(subject.state.connectionsCount == 2)
    }

    /// `perform(_:)` with `.appeared` loads the notification authorization status.
    @Test
    func perform_appeared_notificationAuthorization() async {
        notificationService.authorizationStatus = .denied
        agentAccessRepository.isListeningEnabledReturnValue = false
        agentAccessRepository.relayURLReturnValue = AgentAccessConstants.defaultRelayURL
        agentAccessRepository.autoApproveRulesReturnValue = []
        agentAccessRepository.connectionsReturnValue = []

        await subject.perform(.appeared)

        #expect(subject.state.notificationAuthorization == .denied)
    }

    /// `perform(_:)` with `.refreshNotificationStatus` updates the notification authorization status.
    @Test
    func perform_refreshNotificationStatus() async {
        notificationService.authorizationStatus = .denied

        await subject.perform(.refreshNotificationStatus)

        #expect(subject.state.notificationAuthorization == .denied)
    }

    /// `perform(_:)` with `.appeared` logs an error if the connections can't be loaded.
    @Test
    func perform_appeared_connectionsError() async {
        agentAccessRepository.isListeningEnabledReturnValue = false
        agentAccessRepository.relayURLReturnValue = AgentAccessConstants.defaultRelayURL
        agentAccessRepository.autoApproveRulesReturnValue = []
        agentAccessRepository.connectionsThrowableError = BitwardenTestError.example

        await subject.perform(.appeared)

        #expect(subject.state.connectionsCount == 0)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `perform(_:)` with `.removeRule` removes the rule and reloads the rules.
    @Test
    func perform_removeRule() async {
        subject.state.autoApproveRules = [AgentAccessUIFixtures.autoApproveRule()]
        agentAccessRepository.autoApproveRulesReturnValue = []

        await subject.perform(.removeRule(id: "rule-1"))

        #expect(agentAccessRepository.removeAutoApproveRuleReceivedId == "rule-1")
        #expect(subject.state.autoApproveRules.isEmpty)
    }

    /// `perform(_:)` with `.resetRelayURL` goes back to the default relay.
    @Test
    func perform_resetRelayURL() async {
        subject.state.relayURL = "wss://custom.example.com"
        subject.state.relayURLInput = "wss://custom.example.com"
        subject.state.relayURLErrorMessage = "Error"
        agentAccessRepository.relayURLReturnValue = AgentAccessConstants.defaultRelayURL

        await subject.perform(.resetRelayURL)

        #expect(agentAccessRepository.resetRelayURLCallsCount == 1)
        #expect(subject.state.relayURL == AgentAccessConstants.defaultRelayURL)
        #expect(subject.state.relayURLInput == AgentAccessConstants.defaultRelayURL)
        #expect(subject.state.relayURLErrorMessage == nil)
        #expect(!subject.state.isCustomRelayURL)
        #expect(!coordinator.isLoadingOverlayShowing)
    }

    /// `perform(_:)` with `.resetRelayURL` shows an error alert when the reset fails.
    @Test
    func perform_resetRelayURL_error() async {
        subject.state.relayURL = "wss://custom.example.com"
        agentAccessRepository.resetRelayURLThrowableError = BitwardenTestError.example

        await subject.perform(.resetRelayURL)

        #expect(coordinator.errorAlertsShown.last as? BitwardenTestError == .example)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(subject.state.relayURL == "wss://custom.example.com")
    }

    /// `perform(_:)` with `.saveRelayURL` saves the trimmed address.
    @Test
    func perform_saveRelayURL() async {
        subject.state.relayURL = AgentAccessConstants.defaultRelayURL
        subject.state.relayURLInput = "  wss://custom.example.com  "

        await subject.perform(.saveRelayURL)

        #expect(agentAccessRepository.setRelayURLReceivedUrl == "wss://custom.example.com")
        #expect(subject.state.relayURL == "wss://custom.example.com")
        #expect(subject.state.relayURLInput == "wss://custom.example.com")
        #expect(subject.state.relayURLErrorMessage == nil)
        #expect(!subject.state.isRelayURLChanged)
        #expect(!coordinator.isLoadingOverlayShowing)
    }

    /// `perform(_:)` with `.saveRelayURL` shows a message under the field for an invalid address.
    @Test
    func perform_saveRelayURL_invalid() async {
        subject.state.relayURL = AgentAccessConstants.defaultRelayURL
        subject.state.relayURLInput = "http://example.com"
        agentAccessRepository.setRelayURLThrowableError = AgentAccessError.invalidRelayURL

        await subject.perform(.saveRelayURL)

        #expect(subject.state.relayURLErrorMessage == Localizations.agentAccessInvalidRelayURL)
        #expect(subject.state.relayURL == AgentAccessConstants.defaultRelayURL)
        #expect(coordinator.errorAlertsShown.isEmpty)
    }

    /// `perform(_:)` with `.saveRelayURL` shows an error alert for any other error.
    @Test
    func perform_saveRelayURL_error() async {
        subject.state.relayURLInput = "wss://custom.example.com"
        agentAccessRepository.setRelayURLThrowableError = BitwardenTestError.example

        await subject.perform(.saveRelayURL)

        #expect(coordinator.errorAlertsShown.last as? BitwardenTestError == .example)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(subject.state.relayURLErrorMessage == nil)
    }

    /// `perform(_:)` with `.setListening` turns listening on.
    @Test
    func perform_setListening_on() async {
        await subject.perform(.setListening(true))

        #expect(agentAccessRepository.setListeningEnabledReceivedEnabled == true)
        #expect(subject.state.isListeningEnabled)
        #expect(!coordinator.isLoadingOverlayShowing)
    }

    /// `perform(_:)` with `.setListening` asks for notification permission if it hasn't been decided.
    @Test
    func perform_setListening_on_notDetermined() async {
        notificationService.authorizationStatus = .notDetermined

        await subject.perform(.setListening(true))

        #expect(notificationService.requestedOptions == [.alert, .sound, .badge])
        #expect(subject.state.isListeningEnabled)
        #expect(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.setListening` explains what is lost if notifications are denied, and
    /// still turns listening on.
    @Test
    func perform_setListening_on_denied() async throws {
        notificationService.authorizationStatus = .denied

        await subject.perform(.setListening(true))

        #expect(notificationService.requestedOptions == nil)
        #expect(subject.state.isListeningEnabled)
        #expect(subject.state.notificationAuthorization == .denied)
        let alert = try #require(coordinator.alertShown.last)
        #expect(alert.title == Localizations.notificationsAreOff)
        #expect(alert.message == Localizations.agentAccessNotificationsOffWarning)

        let action = try #require(alert.alertActions.first { $0.title == Localizations.openSettings })
        await action.handler?(action, [])
        #expect(subject.state.url == URL(string: UIApplication.openSettingsURLString))
    }

    /// `perform(_:)` with `.setListening` doesn't ask or warn if notifications are already allowed.
    @Test
    func perform_setListening_on_authorized() async {
        await subject.perform(.setListening(true))

        #expect(notificationService.requestedOptions == nil)
        #expect(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.setListening` still turns listening on if the permission request fails.
    @Test
    func perform_setListening_on_requestError() async {
        notificationService.authorizationStatus = .notDetermined
        notificationService.requestAuthorizationResult = .failure(BitwardenTestError.example)

        await subject.perform(.setListening(true))

        #expect(subject.state.isListeningEnabled)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `perform(_:)` with `.setListening` doesn't ask for notification permission when turning off.
    @Test
    func perform_setListening_off_doesNotAsk() async {
        notificationService.authorizationStatus = .notDetermined

        await subject.perform(.setListening(false))

        #expect(notificationService.requestedOptions == nil)
        #expect(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.setListening` doesn't ask for notification permission if saving fails.
    @Test
    func perform_setListening_error_doesNotAsk() async {
        notificationService.authorizationStatus = .notDetermined
        agentAccessRepository.setListeningEnabledThrowableError = BitwardenTestError.example
        agentAccessRepository.isListeningEnabledReturnValue = false

        await subject.perform(.setListening(true))

        #expect(notificationService.requestedOptions == nil)
    }

    /// `perform(_:)` with `.turnOnNotifications` requests permission if it hasn't been decided.
    @Test
    func perform_turnOnNotifications_notDetermined() async {
        notificationService.authorizationStatus = .notDetermined

        await subject.perform(.turnOnNotifications)

        #expect(notificationService.requestedOptions == [.alert, .sound, .badge])
        #expect(subject.state.url == nil)
    }

    /// `perform(_:)` with `.turnOnNotifications` opens iOS Settings if permission was denied.
    @Test
    func perform_turnOnNotifications_denied() async {
        notificationService.authorizationStatus = .denied

        await subject.perform(.turnOnNotifications)

        #expect(notificationService.requestedOptions == nil)
        #expect(subject.state.url == URL(string: UIApplication.openSettingsURLString))
    }

    /// `receive(_:)` with `.clearURL` clears the URL.
    @Test
    func receive_clearURL() {
        subject.state.url = .example

        subject.receive(.clearURL)

        #expect(subject.state.url == nil)
    }

    /// `perform(_:)` with `.setListening` turns listening off.
    @Test
    func perform_setListening_off() async {
        subject.state.isListeningEnabled = true

        await subject.perform(.setListening(false))

        #expect(agentAccessRepository.setListeningEnabledReceivedEnabled == false)
        #expect(!subject.state.isListeningEnabled)
    }

    /// `perform(_:)` with `.setListening` restores the saved value and shows an alert if it fails.
    @Test
    func perform_setListening_error() async {
        agentAccessRepository.setListeningEnabledThrowableError = BitwardenTestError.example
        agentAccessRepository.isListeningEnabledReturnValue = false

        await subject.perform(.setListening(true))

        #expect(!subject.state.isListeningEnabled)
        #expect(coordinator.errorAlertsShown.last as? BitwardenTestError == .example)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `perform(_:)` with `.streamStatus` updates the status as it changes.
    @Test
    func perform_streamStatus() async {
        agentAccessRepository.statusPublisherReturnValue = [
            AgentAccessConnectionStatus.connecting,
            .listening,
        ].publisher.eraseToAnyPublisher()

        await subject.perform(.streamStatus)

        #expect(subject.state.status == .listening)
        #expect(subject.state.statusText == Localizations.agentAccessStatusListening)
    }

    /// `receive(_:)` with `.auditLogPressed` navigates to the activity log.
    @Test
    func receive_auditLogPressed() {
        subject.receive(.auditLogPressed)

        #expect(coordinator.routes.last == .auditLog)
    }

    /// `receive(_:)` with `.connectionsPressed` navigates to the connections.
    @Test
    func receive_connectionsPressed() {
        subject.receive(.connectionsPressed)

        #expect(coordinator.routes.last == .connections)
    }

    /// `receive(_:)` with `.pairPressed` navigates to the pairing screen.
    @Test
    func receive_pairPressed() {
        subject.receive(.pairPressed)

        #expect(coordinator.routes.last == .pairing)
    }

    /// `receive(_:)` with `.advancedPressed` expands and collapses the advanced section.
    @Test
    func receive_advancedPressed() {
        #expect(!subject.state.isAdvancedExpanded)

        subject.receive(.advancedPressed)
        #expect(subject.state.isAdvancedExpanded)

        subject.receive(.advancedPressed)
        #expect(!subject.state.isAdvancedExpanded)
    }

    /// `receive(_:)` with `.relayURLChanged` updates the input and clears the error.
    @Test
    func receive_relayURLChanged() {
        subject.state.relayURL = "wss://relay.example.com"
        subject.state.relayURLErrorMessage = "Error"

        subject.receive(.relayURLChanged("wss://custom.example.com"))

        #expect(subject.state.relayURLInput == "wss://custom.example.com")
        #expect(subject.state.relayURLErrorMessage == nil)
        #expect(subject.state.isRelayURLChanged)
    }
}
