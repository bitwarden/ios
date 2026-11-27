// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AutofillPromptServiceTests + Vault Action Card

extension AutofillPromptServiceTests {
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

    /// `vaultActionCardVisibilityPublisher()` emits `false` after the card is dismissed, and the
    /// dismiss time is stored without opting out.
    @Test
    func vaultActionCardVisibilityPublisher_dismissed_hidden() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()
        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        #expect(await iterator.next() == true)

        await subject.dismissVaultActionCard()

        #expect(await iterator.next() == false)
        #expect(stateService.autofillActionCardDismissedSubject.value == timeProvider.presentTime)
        #expect(!stateService.autofillActionCardOptedOut)
    }

    /// `vaultActionCardVisibilityPublisher()` keeps the card hidden while it was dismissed less than
    /// 24 hours ago, such as after a cold launch, and shows it again on the next refresh once 24
    /// hours have passed.
    @Test
    func vaultActionCardVisibilityPublisher_dismissed_shownAgainAfter24Hours() async throws {
        let dismissedDate = timeProvider.presentTime
        stateService.autofillActionCardDismissedSubject.send(dismissedDate)
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()
        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        #expect(await iterator.next() == false)

        timeProvider.timeConfig = .mockTime(dismissedDate.addingTimeInterval(23 * 60 * 60))
        await subject.refreshAutofillStatus()
        timeProvider.timeConfig = .mockTime(dismissedDate.addingTimeInterval(24 * 60 * 60))
        await subject.refreshAutofillStatus()

        // The refresh within 24 hours doesn't emit a change; the next value is the card reappearing.
        #expect(await iterator.next() == true)
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

    /// `vaultActionCardVisibilityPublisher()` emits `true` again when the dismissal is cleared,
    /// without restarting the app.
    @Test
    func vaultActionCardVisibilityPublisher_dismissalCleared_shown() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()
        await subject.dismissVaultActionCard()
        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        #expect(await iterator.next() == false)

        await stateService.setAutofillActionCardDismissedDate(nil)

        #expect(await iterator.next() == true)
    }

    /// `vaultActionCardVisibilityPublisher()` emits `true` again when the opt-out is cleared,
    /// without restarting the app.
    @Test
    func vaultActionCardVisibilityPublisher_optOutCleared_shown() async throws {
        stateService.autofillActionCardOptedOut = true
        autofillCredentialService.isAutofillCredentialsEnabled = false
        await subject.refreshAutofillStatus()
        var iterator = await subject.vaultActionCardVisibilityPublisher().values.makeAsyncIterator()
        #expect(await iterator.next() == false)

        await stateService.setAutofillActionCardOptedOut(false)

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
