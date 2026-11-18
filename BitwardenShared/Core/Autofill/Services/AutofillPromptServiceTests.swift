import BitwardenKit
import BitwardenKitMocks
import Combine
import Foundation
import TestHelpers
import Testing
import UIKit

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AutofillPromptServiceTests

@MainActor
struct AutofillPromptServiceTests {
    // MARK: Properties

    let appContextHelper: MockAppContextHelper
    let asSettingsMediator: MockASSettingsMediator
    let autofillCredentialService: MockAutofillCredentialService
    let errorReporter: MockErrorReporter
    let stateService: MockStateService
    let subject: DefaultAutofillPromptService
    let vaultTimeoutService: MockVaultTimeoutService

    // MARK: Initialization

    init() {
        appContextHelper = MockAppContextHelper()
        asSettingsMediator = MockASSettingsMediator()
        autofillCredentialService = MockAutofillCredentialService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        stateService.activeAccount = .fixture()

        subject = DefaultAutofillPromptService(
            activeAccountStateProvider: stateService,
            appContextHelper: appContextHelper,
            asSettingsMediator: asSettingsMediator,
            autofillCredentialService: autofillCredentialService,
            autofillStateService: stateService,
            errorReporter: errorReporter,
            vaultTimeoutService: vaultTimeoutService,
            credentialStoreUpdateDelay: 0,
        )
    }

    // MARK: Tests - autofillEnabledPublisher

    /// `autofillEnabledPublisher()` emits `nil` until the autofill status has been refreshed.
    @Test
    func autofillEnabledPublisher_beforeRefresh_isNil() async throws {
        var iterator = subject.autofillEnabledPublisher().values.makeAsyncIterator()
        let value = await iterator.next()
        #expect(value == .some(nil))
    }

    /// `autofillEnabledPublisher()` emits the autofill status after it's refreshed.
    @Test
    func autofillEnabledPublisher_afterRefresh_emitsStatus() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()

        var iterator = subject.autofillEnabledPublisher().values.makeAsyncIterator()
        let value = await iterator.next()
        #expect(value == true)
    }

    // MARK: Tests - refreshAutofillStatus

    /// `refreshAutofillStatus()` doesn't check the autofill status in an app extension.
    @Test
    func refreshAutofillStatus_appExtension_noOp() async throws {
        appContextHelper.appContext = .appExtension
        autofillCredentialService.isAutofillCredentialsEnabled = true

        await subject.refreshAutofillStatus()

        var iterator = subject.autofillEnabledPublisher().values.makeAsyncIterator()
        let value = await iterator.next()
        #expect(value == .some(nil))
    }

    /// `refreshAutofillStatus()` repopulates the credential identity store when autofill changes
    /// from off to on and the vault is unlocked.
    @Test
    func refreshAutofillStatus_offToOn_unlocked_updatesCredentialsInStore() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()

        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()

        try await waitForAsync { autofillCredentialService.updateCredentialsInStoreCalled }
    }

    /// `refreshAutofillStatus()` returns without waiting for the delayed credential identity store
    /// repopulation, so callers like the app's foreground handling aren't held up.
    @Test
    func refreshAutofillStatus_offToOn_unlocked_doesNotWaitForCredentialStoreUpdate() async throws {
        let subject = DefaultAutofillPromptService(
            activeAccountStateProvider: stateService,
            appContextHelper: appContextHelper,
            asSettingsMediator: asSettingsMediator,
            autofillCredentialService: autofillCredentialService,
            autofillStateService: stateService,
            errorReporter: errorReporter,
            vaultTimeoutService: vaultTimeoutService,
            credentialStoreUpdateDelay: 60,
        )
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()

        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()

        #expect(!autofillCredentialService.updateCredentialsInStoreCalled)
        var iterator = subject.autofillEnabledPublisher().values.makeAsyncIterator()
        #expect(await iterator.next() == true)
    }

    /// `refreshAutofillStatus()` doesn't repopulate the credential identity store when autofill
    /// changes from off to on but the vault is locked.
    @Test
    func refreshAutofillStatus_offToOn_locked_doesNotUpdateCredentialsInStore() async throws {
        vaultTimeoutService.isClientLocked["1"] = true
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()

        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()

        #expect(!autofillCredentialService.updateCredentialsInStoreCalled)
    }

    /// `refreshAutofillStatus()` doesn't repopulate the credential identity store when there's no
    /// active account, and doesn't log an error.
    @Test
    func refreshAutofillStatus_offToOn_noActiveAccount() async throws {
        stateService.activeAccount = nil
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()

        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()

        #expect(!autofillCredentialService.updateCredentialsInStoreCalled)
        #expect(errorReporter.errors.isEmpty)
    }

    /// `refreshAutofillStatus()` logs an error if the active account can't be determined.
    @Test
    func refreshAutofillStatus_offToOn_activeAccountError() async throws {
        stateService.getActiveAccountIdError = BitwardenTestError.example
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()

        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()

        #expect(!autofillCredentialService.updateCredentialsInStoreCalled)
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    /// `refreshAutofillStatus()` doesn't repopulate the credential identity store on the first
    /// check, since the store is populated when the vault is unlocked.
    @Test
    func refreshAutofillStatus_firstCheckOn_doesNotUpdateCredentialsInStore() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = true

        await subject.refreshAutofillStatus()

        #expect(!autofillCredentialService.updateCredentialsInStoreCalled)
    }

    /// `refreshAutofillStatus()` doesn't repopulate the credential identity store when autofill
    /// stays on.
    @Test
    func refreshAutofillStatus_onToOn_doesNotUpdateCredentialsInStore() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()
        await subject.refreshAutofillStatus()

        #expect(!autofillCredentialService.updateCredentialsInStoreCalled)
    }

    // MARK: Tests - turnOnAutofill

    /// `turnOnAutofill()` requests to turn on the credential provider extension and then
    /// refreshes the autofill status, using the live state rather than the prompt's result.
    @Test
    func turnOnAutofill_requestsAndRefreshes() async throws {
        guard #available(iOS 18.0, *) else { return }
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionReturnValue = false
        autofillCredentialService.isAutofillCredentialsEnabled = true

        let result = await subject.turnOnAutofill()

        #expect(result == nil)
        #expect(asSettingsMediator.requestToTurnOnCredentialProviderExtensionCalled)
        var iterator = subject.autofillEnabledPublisher().values.makeAsyncIterator()
        let value = await iterator.next()
        #expect(value == true)
    }

    /// `turnOnAutofill()` opens the AutoFill settings instead of the system prompt when the prompt
    /// was requested too recently.
    @Test
    func turnOnAutofill_cantRequest_opensCredentialProviderSettings() async throws {
        guard #available(iOS 18.0, *) else { return }
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionThrowableError =
            ASSettingsMediatorError.cantRequest

        let result = await subject.turnOnAutofill()

        #expect(result == nil)
        #expect(asSettingsMediator.openCredentialProviderAppSettingsCalled)
        #expect(errorReporter.errors.isEmpty)
    }

    /// `turnOnAutofill()` asks the caller to open the app's settings page when the system prompt
    /// was requested too recently and the AutoFill settings can't be opened.
    @Test
    func turnOnAutofill_cantRequest_openSettingsFails_returnsOpenAppSettings() async throws {
        guard #available(iOS 18.0, *) else { return }
        asSettingsMediator.requestToTurnOnCredentialProviderExtensionThrowableError =
            ASSettingsMediatorError.cantRequest
        asSettingsMediator.openCredentialProviderAppSettingsThrowableError = BitwardenTestError.example

        let result = await subject.turnOnAutofill()

        #expect(result == URL(string: UIApplication.openSettingsURLString))
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    // MARK: Tests - vaultActionCardVisibilityPublisher

    /// `vaultActionCardVisibilityPublisher()` emits `false` until the autofill status is known.
    @Test
    func vaultActionCardVisibilityPublisher_unknownStatus_hidden() async throws {
        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        let value = await iterator.next()
        #expect(value == false)
    }

    /// `vaultActionCardVisibilityPublisher()` emits `true` when autofill is off.
    @Test
    func vaultActionCardVisibilityPublisher_autofillOff_shown() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()

        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        let value = await iterator.next()
        #expect(value == true)
    }

    /// `vaultActionCardVisibilityPublisher()` emits `false` when autofill is on.
    @Test
    func vaultActionCardVisibilityPublisher_autofillOn_hidden() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()

        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        let value = await iterator.next()
        #expect(value == false)
    }

    /// `vaultActionCardVisibilityPublisher()` emits `false` after the card is dismissed for the
    /// session, without persisting anything.
    @Test
    func vaultActionCardVisibilityPublisher_dismissedForSession_hidden() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()
        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        #expect(await iterator.next() == true)

        await subject.dismissVaultActionCardForSession()

        #expect(await iterator.next() == false)
        #expect(!stateService.autofillActionCardOptedOut)
    }

    /// `vaultActionCardVisibilityPublisher()` emits `false` after the user opts out, and the opt
    /// out is persisted.
    @Test
    func vaultActionCardVisibilityPublisher_optedOut_hidden() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()
        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        #expect(await iterator.next() == true)

        await subject.optOutOfVaultActionCard()

        #expect(await iterator.next() == false)
        #expect(stateService.autofillActionCardOptedOut)
    }

    /// `vaultActionCardVisibilityPublisher()` emits `true` again when the session dismissal is
    /// cleared, such as from the debug menu, without restarting the app.
    @Test
    func vaultActionCardVisibilityPublisher_sessionDismissalCleared_shown() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()
        await subject.dismissVaultActionCardForSession()
        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        #expect(await iterator.next() == false)

        await stateService.clearAutofillActionCardDismissedForSession()

        #expect(await iterator.next() == true)
    }

    /// `vaultActionCardVisibilityPublisher()` emits `true` again when the opt-out is cleared, such
    /// as from the debug menu, without restarting the app.
    @Test
    func vaultActionCardVisibilityPublisher_optOutCleared_shown() async throws {
        stateService.autofillActionCardOptedOut = true
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()
        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        #expect(await iterator.next() == false)

        await stateService.clearAutofillActionCardOptOut()

        #expect(await iterator.next() == true)
    }

    /// `vaultActionCardVisibilityPublisher()` emits `false` when the user previously opted out.
    @Test
    func vaultActionCardVisibilityPublisher_previouslyOptedOut_hidden() async throws {
        stateService.autofillActionCardOptedOut = true
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()

        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        let value = await iterator.next()
        #expect(value == false)
    }

    /// `vaultActionCardVisibilityPublisher()` emits `false` once autofill is turned on.
    @Test
    func vaultActionCardVisibilityPublisher_autofillTurnedOn_hides() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()
        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        #expect(await iterator.next() == true)

        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()

        #expect(await iterator.next() == false)
    }
}
