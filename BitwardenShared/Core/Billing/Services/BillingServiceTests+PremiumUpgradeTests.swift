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

    /// `premiumStatusChanged()` does not publish a checkout status — it isn't tied to any
    /// specific in-flight checkout attempt, so there's no attempt outcome to report.
    @Test
    func premiumStatusChanged_doesNotPublishCheckoutStatus() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        #expect(statuses.isEmpty)
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

    /// `premiumStatusChanged()` triggers a plain (non-forced) sync when eligible, mirroring
    /// `.policyChanged`'s own push handling — an account that gained Premium via the web vault,
    /// another device, or an org still needs its profile refreshed locally.
    @Test
    func premiumStatusChanged_triggersPlainSync() async throws {
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.premiumStatusChanged()

        #expect(syncService.didFetchSync)
        #expect(syncService.fetchSyncForceSync == false)
    }

    /// `start()` clears a stale `lastAttemptFailed` flag as soon as any sync succeeds, even
    /// when the active account still isn't Premium yet — a later, unrelated sync succeeding
    /// means the most recent attempt did not fail, regardless of whether Premium has been
    /// granted.
    @Test
    func start_clearsLastAttemptFailedOnGenericSyncEvenWithoutPremium() async throws {
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.start()
        // Wait for the subscription's baseline snapshot before sending a "new" value below —
        // `start()` reads `getLastSyncTime()` exactly once, before subscribing to the publisher.
        // Without this, the publisher's `CurrentValueSubject` backing could coalesce an
        // immediate send with the not-yet-taken snapshot, making it ambiguous whether the send
        // counts as a change (both nested `Task`s run on the cooperative pool, so a fixed
        // number of `Task.yield()` calls from this `@MainActor` test isn't a reliable proxy).
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { stateService.premiumUpgradeLastSyncAttemptFailedResult == false }
        #expect(stateService.premiumUpgradePendingResult == false)
        #expect(stateService.upgradedToPremiumActionCardVisibleResult == false)
    }

    /// `start()` does not clear a stale `lastAttemptFailed` flag just from subscribing to the
    /// last-sync-time publisher — its `CurrentValueSubject` backing replays the existing cached
    /// value immediately on subscribe, and that replay must not be mistaken for a new sync
    /// completing.
    @Test
    func start_doesNotClearLastAttemptFailedOnInitialSubscriptionReplay() async throws {
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = true
        stateService.lastSyncTimeSubject.send(Date())
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true

        await subject.start()
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == true)
        #expect(stateService.setPremiumUpgradeLastSyncAttemptFailedCallCount == 0)

        // A genuinely new sync, sent only once the initial subscription has settled, still
        // clears the flag as expected.
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { stateService.premiumUpgradeLastSyncAttemptFailedResult == false }
        #expect(stateService.setPremiumUpgradeLastSyncAttemptFailedCallCount == 1)
    }

    /// `start()` resolves a pending Premium upgrade when a generic sync completes and the
    /// active account has since become Premium, by any means (not just the original checkout
    /// attempt's own subscription).
    @Test
    func start_resolvesPendingUpgradeOnGenericSync() async throws {
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.start()
        // See the comment in `start_clearsLastAttemptFailedOnGenericSyncEvenWithoutPremium()`.
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        stateService.doesActiveAccountHavePremiumResult = true
        stateService.lastSyncTimeSubject.send(Date())

        // Wait for the last state mutation in the premium-confirmed branch — `lastAttemptFailed`
        // and `pending` both clear before this, so waiting on either of those would race.
        try await waitForAsync { stateService.upgradedToPremiumActionCardVisibleResult == true }
        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
        #expect(stateService.premiumUpgradePendingResult == false)
    }

    /// `start()` resolves a pending Premium upgrade on a generic sync even when `lastAttemptFailed`
    /// was never set — the "sync succeeded, Premium not yet confirmed" outcome leaves only
    /// `isPending` set, and a later, unrelated sync must still be able to resolve it.
    @Test
    func start_resolvesPendingUpgradeOnGenericSync_pendingOnlyNoFailureRecorded() async throws {
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.start()
        // See the comment in `start_clearsLastAttemptFailedOnGenericSyncEvenWithoutPremium()`.
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        stateService.premiumUpgradePendingResult = true
        stateService.doesActiveAccountHavePremiumResult = true
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { stateService.upgradedToPremiumActionCardVisibleResult == true }
        #expect(stateService.premiumUpgradePendingResult == false)
    }
}
