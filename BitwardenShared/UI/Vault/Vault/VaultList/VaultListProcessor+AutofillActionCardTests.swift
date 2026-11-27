// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import Combine
import Foundation
import TestHelpers
import Testing
import UIKit

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - VaultListProcessorAutofillActionCardTests

@MainActor
struct VaultListProcessorAutofillActionCardTests {
    // MARK: Properties

    let autofillPromptService: MockAutofillPromptService
    let configService: MockConfigService
    let coordinator: MockCoordinator<VaultRoute, AuthAction>
    let services: ServiceContainer
    let subject: VaultListProcessor

    // MARK: Initialization

    init() {
        autofillPromptService = MockAutofillPromptService()
        configService = MockConfigService()
        coordinator = MockCoordinator()
        let searchProcessorMediatorFactory = MockSearchProcessorMediatorFactory()
        searchProcessorMediatorFactory.makeReturnValue = MockSearchProcessorMediator()
        services = ServiceContainer.withMocks(
            autofillPromptService: autofillPromptService,
            configService: configService,
            searchProcessorMediatorFactory: searchProcessorMediatorFactory,
        )
        subject = VaultListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            masterPasswordRepromptHelper: MockMasterPasswordRepromptHelper(),
            services: services,
            state: VaultListState(),
            vaultItemMoreOptionsHelper: MockVaultItemMoreOptionsHelper(),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.dismissAutofillActionCard` dismisses the card for 24 hours.
    @Test
    func perform_dismissAutofillActionCard() async {
        await subject.perform(.dismissAutofillActionCard)

        #expect(autofillPromptService.dismissVaultActionCardCalled)
        #expect(!autofillPromptService.optOutOfVaultActionCardCalled)
    }

    /// `perform(_:)` with `.optOutOfAutofillActionCard` opts the user out of the card.
    @Test
    func perform_optOutOfAutofillActionCard() async {
        await subject.perform(.optOutOfAutofillActionCard)

        #expect(autofillPromptService.optOutOfVaultActionCardCalled)
        #expect(!autofillPromptService.dismissVaultActionCardCalled)
    }

    /// `perform(_:)` with `.streamAutofillActionCard` refreshes the autofill status and streams
    /// whether the card should be shown when the feature flag is enabled.
    @Test
    func perform_streamAutofillActionCard_flagEnabled() async throws {
        configService.featureFlagsBool[.autofillOffActionCard] = true
        let visibilitySubject = CurrentValueSubject<Bool, Never>(true)
        autofillPromptService.vaultActionCardVisibilityPublisherReturnValue = visibilitySubject
            .eraseToAnyPublisher()

        let task = Task {
            await subject.perform(.streamAutofillActionCard)
        }
        defer { task.cancel() }

        try await waitForAsync { subject.state.shouldShowAutofillActionCard }
        #expect(subject.state.isAutofillOffActionCardEnabled)
        #expect(autofillPromptService.refreshAutofillStatusCalled)

        visibilitySubject.send(false)
        try await waitForAsync { !subject.state.shouldShowAutofillActionCard }
    }

    /// `perform(_:)` with `.streamAutofillActionCard` does nothing when the feature flag is
    /// disabled.
    @Test
    func perform_streamAutofillActionCard_flagDisabled() async {
        await subject.perform(.streamAutofillActionCard)

        #expect(!subject.state.isAutofillOffActionCardEnabled)
        #expect(!subject.state.shouldShowAutofillActionCard)
        #expect(!autofillPromptService.refreshAutofillStatusCalled)
        #expect(!autofillPromptService.vaultActionCardVisibilityPublisherCalled)
    }

    /// `perform(_:)` with `.windowBecameActive` refreshes the autofill status when the autofill off
    /// action card is enabled, such as when regaining focus in Split View.
    @Test
    func perform_windowBecameActive_flagEnabled_refreshesAutofillStatus() async {
        subject.state.isAutofillOffActionCardEnabled = true

        await subject.perform(.windowBecameActive)

        #expect(autofillPromptService.refreshAutofillStatusCalled)
    }

    /// `perform(_:)` with `.windowBecameActive` does nothing when the autofill off action card is
    /// disabled.
    @Test
    func perform_windowBecameActive_flagDisabled_doesNothing() async {
        await subject.perform(.windowBecameActive)

        #expect(!autofillPromptService.refreshAutofillStatusCalled)
    }

    /// `perform(_:)` with `.turnOnAutofill` doesn't open a URL when the request was handled by
    /// the system.
    @Test
    func perform_turnOnAutofill_handled() async {
        autofillPromptService.turnOnAutofillReturnValue = nil

        await subject.perform(.turnOnAutofill)

        #expect(autofillPromptService.turnOnAutofillCalled)
        #expect(subject.state.url == nil)
    }

    /// `perform(_:)` with `.turnOnAutofill` opens the app's page in the Settings app when the OS
    /// doesn't support a more direct option.
    @Test
    func perform_turnOnAutofill_openAppSettings() async {
        autofillPromptService.turnOnAutofillReturnValue = URL(string: UIApplication.openSettingsURLString)

        await subject.perform(.turnOnAutofill)

        #expect(subject.state.url == URL(string: UIApplication.openSettingsURLString))
    }
}
