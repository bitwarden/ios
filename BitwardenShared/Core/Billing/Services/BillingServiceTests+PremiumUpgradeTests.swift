import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingServiceTests+PremiumUpgradeTests

extension BillingServiceTests {
    // MARK: Tests

    /// `premiumStatusChanged()` returns early without syncing when the user already has Premium.
    @Test
    func premiumStatusChanged_alreadyHasPremium() async throws {
        stateService.doesActiveAccountHavePremiumResult = true
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        #expect(statuses.isEmpty)
        #expect(!syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` does not set the "Upgraded to Premium" card when the account is
    /// still not Premium after the sync.
    @Test
    func premiumStatusChanged_doesNotSetUpgradedActionCard_whenStillNotPremium() async throws {
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.premiumStatusChanged()

        #expect(stateService.upgradedToPremiumActionCardVisibleResult == false)
    }

    /// `premiumStatusChanged()` returns early without syncing when the premiumUpgradePath flag is disabled.
    @Test
    func premiumStatusChanged_featureFlagDisabled() async throws {
        configService.featureFlagsBool[.premiumUpgradePath] = false
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.premiumStatusChanged()

        #expect(!syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` does not leave a stale `.pending` on the `CurrentValueSubject` for
    /// a late subscriber — unlike `reconcileCheckoutSuccess()`'s deliberately sticky `.pending`
    /// for an actual in-flight checkout (see `premiumCheckoutStatusPublisher_lateSubscriberReceivesPendingStatus`),
    /// this method also runs for a `.premiumStatusChanged` push unrelated to any checkout, so a
    /// late-subscribing upgrade UI must not replay a bogus pending status.
    @Test
    func premiumStatusChanged_lateSubscriberDoesNotReceiveStalePendingStatus() async throws {
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.premiumStatusChanged()

        var lateStatuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { lateStatuses.append($0) }
        defer { cancellable.cancel() }

        // Give a stale replay a chance to arrive before asserting none did.
        try await Task.sleep(nanoseconds: 250_000_000)
        #expect(lateStatuses.isEmpty)
    }

    /// `premiumStatusChanged()` publishes `.confirmed` when the account has become Premium by the
    /// time the sync completes, so a live `PremiumUpgradeHelper`/`PremiumUpgradeProcessor`
    /// subscription from an upgrade attempt still in flight elsewhere reacts immediately, rather
    /// than only on the vault list's next `.appeared`.
    @Test
    func premiumStatusChanged_publishesConfirmed_whenPremiumGranted() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
    }

    /// `premiumStatusChanged()` publishes `.pending` when the account still isn't Premium after
    /// the sync.
    @Test
    func premiumStatusChanged_publishesPending_whenStillNotPremium() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
    }

    /// `premiumStatusChanged()` returns early without syncing when the environment is self-hosted.
    @Test
    func premiumStatusChanged_selfHosted() async throws {
        environmentService.region = .selfHosted
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.premiumStatusChanged()

        #expect(!syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` syncs when self-hosted region is overridden by the debug flag.
    @Test
    func premiumStatusChanged_selfHosted_debugFlagEnabled_syncs() async throws {
        environmentService.region = .selfHosted
        configService.featureFlagsBool[.debugDisableSelfHostPremiumCheck] = true
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.premiumStatusChanged()

        #expect(syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` sets the "Upgraded to Premium" card visible when the account has
    /// become Premium by the time the sync completes — an out-of-band grant (an org, or another
    /// device) has no pending checkout attempt of its own to reconcile it otherwise.
    @Test
    func premiumStatusChanged_setsUpgradedActionCard_whenPremiumGranted() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }

        await subject.premiumStatusChanged()

        #expect(stateService.upgradedToPremiumActionCardVisibleResult == true)
    }

    /// `premiumStatusChanged()` reports the error when setting the "Upgraded to Premium" card
    /// visible throws, without leaving a pending mark behind — unlike `reconcileCheckoutSuccess()`,
    /// there is no checkout attempt here for a later reconcile to pick back up.
    @Test
    func premiumStatusChanged_setUpgradedActionCardError() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }
        stateService.setUpgradedToPremiumActionCardResult = .failure(BitwardenTestError.example)

        await subject.premiumStatusChanged()

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `premiumStatusChanged()` reports the error and does not record a failure flag when sync
    /// fails — unlike `reconcileCheckoutSuccess()`'s deliberately sticky pending mark for an
    /// actual in-flight checkout, this method also runs for a `.premiumStatusChanged` push
    /// unrelated to any checkout, so there's no pending state to leave behind.
    @Test
    func premiumStatusChanged_syncError() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))

        await subject.premiumStatusChanged()

        #expect(errorReporter.errors.first is URLError)
        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
    }

    /// `premiumStatusChanged()` triggers a forced sync when eligible — unlike `.policyChanged`'s
    /// plain sync, this method reads the synced premium status back in the same call, so it
    /// needs the guarantee that the sync actually fetched fresh data.
    @Test
    func premiumStatusChanged_triggersForcedSync() async throws {
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.premiumStatusChanged()

        #expect(syncService.didFetchSync)
        #expect(syncService.fetchSyncForceSync == true)
    }
}
