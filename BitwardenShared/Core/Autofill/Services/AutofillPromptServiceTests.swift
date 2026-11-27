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
    let notificationCenterService: MockNotificationCenterService
    let stateService: MockStateService
    let subject: DefaultAutofillPromptService
    let timeProvider: MockTimeProvider
    let vaultTimeoutService: MockVaultTimeoutService

    // MARK: Initialization

    init() {
        appContextHelper = MockAppContextHelper()
        asSettingsMediator = MockASSettingsMediator()
        autofillCredentialService = MockAutofillCredentialService()
        errorReporter = MockErrorReporter()
        notificationCenterService = MockNotificationCenterService()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2026, month: 1, day: 1)))
        vaultTimeoutService = MockVaultTimeoutService()

        stateService.activeAccount = .fixture()

        subject = DefaultAutofillPromptService(
            activeAccountStateProvider: stateService,
            appContextHelper: appContextHelper,
            asSettingsMediator: asSettingsMediator,
            autofillCredentialService: autofillCredentialService,
            autofillStateService: stateService,
            errorReporter: errorReporter,
            notificationCenterService: notificationCenterService,
            timeProvider: timeProvider,
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

    /// `refreshAutofillStatus()` waits for the app to return to the foreground before repopulating
    /// the credential identity store, since writes fail while the app is in the background.
    @Test
    func refreshAutofillStatus_offToOn_backgroundedDuringDelay_waitsForForeground() async throws {
        notificationCenterService.isInForegroundSubject.send(false)
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()

        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()
        // Give the delayed update a chance to run while the app is in the background.
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(!autofillCredentialService.updateCredentialsInStoreCalled)

        notificationCenterService.isInForegroundSubject.send(true)

        try await waitForAsync { autofillCredentialService.updateCredentialsInStoreCalled }
    }

    /// `refreshAutofillStatus()` cancels a pending credential identity store repopulation when
    /// autofill is turned on again, so the store is only repopulated once.
    @Test
    func refreshAutofillStatus_offToOnTwice_backgrounded_updatesCredentialsInStoreOnce() async throws {
        notificationCenterService.isInForegroundSubject.send(false)
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()

        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()
        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()
        // Give the pending updates a chance to start waiting for the foreground.
        try await Task.sleep(nanoseconds: 100_000_000)

        notificationCenterService.isInForegroundSubject.send(true)

        try await waitForAsync { autofillCredentialService.updateCredentialsInStoreCalled }
        // Give a duplicate update a chance to run.
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(autofillCredentialService.updateCredentialsInStoreCallsCount == 1)
    }

    /// `refreshAutofillStatus()` doesn't repopulate the credential identity store if the vault
    /// locks while the update is pending, since the store is populated again on unlock.
    @Test
    func refreshAutofillStatus_offToOn_vaultLockedDuringDelay_doesNotUpdateCredentialsInStore() async throws {
        notificationCenterService.isInForegroundSubject.send(false)
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()

        autofillCredentialService.isAutofillCredentialsEnabled = true
        await subject.refreshAutofillStatus()
        vaultTimeoutService.isClientLocked["1"] = true
        notificationCenterService.isInForegroundSubject.send(true)
        // Give the pending update a chance to run after returning to the foreground.
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(!autofillCredentialService.updateCredentialsInStoreCalled)
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
            notificationCenterService: notificationCenterService,
            timeProvider: timeProvider,
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
}
