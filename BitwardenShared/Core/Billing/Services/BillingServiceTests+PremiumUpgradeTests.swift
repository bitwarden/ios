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

    /// `start()` clears a stale `lastAttemptFailed` flag as soon as any sync succeeds, even
    /// when the active account still isn't Premium yet, and promotes the attempt back to
    /// pending rather than abandoning it — a later, unrelated sync succeeding means the most
    /// recent attempt did not fail, but the account still isn't Premium, so a further sync must
    /// still be able to resolve it.
    @Test
    func start_clearsLastAttemptFailedOnGenericSyncEvenWithoutPremium() async throws {
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = false
        var states = [PremiumUpgradePendingState]()
        let cancellable = subject.premiumUpgradePendingStatePublisher()
            .sink { states.append($0) }
        defer { cancellable.cancel() }

        await subject.start()
        // Wait for the subscription's baseline snapshot before sending a "new" value below —
        // `start()` reads `getLastSyncTime()` exactly once, before subscribing to the publisher.
        // Without this, the publisher's `CurrentValueSubject` backing could coalesce an
        // immediate send with the not-yet-taken snapshot, making it ambiguous whether the send
        // counts as a change (both nested `Task`s run on the cooperative pool, so a fixed
        // number of `Task.yield()` calls from this `@MainActor` test isn't a reliable proxy).
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        try await stateService.setLastSyncTime(Date(), userId: nil)

        try await waitForAsync { stateService.premiumUpgradeLastSyncAttemptFailedResult == false }
        #expect(stateService.premiumUpgradePendingResult == true)
        #expect(stateService.upgradedToPremiumActionCardVisibleResult == false)
        #expect(states.last == PremiumUpgradePendingState(isPending: true, lastAttemptFailed: false))
    }

    /// `start()` does not clear a stale `lastAttemptFailed` flag just from subscribing to the
    /// last-sync-time publisher — its `CurrentValueSubject` backing replays the existing cached
    /// value immediately on subscribe, and that replay must not be mistaken for a new sync
    /// completing.
    @Test
    func start_doesNotClearLastAttemptFailedOnInitialSubscriptionReplay() async throws {
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = true
        try await stateService.setLastSyncTime(Date(), userId: nil)
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true

        await subject.start()
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == true)
        #expect(stateService.setPremiumUpgradeLastSyncAttemptFailedCallCount == 0)

        // A genuinely new sync, sent only once the initial subscription has settled, still
        // clears the flag as expected.
        try await stateService.setLastSyncTime(Date(), userId: nil)

        try await waitForAsync { stateService.premiumUpgradeLastSyncAttemptFailedResult == false }
        #expect(stateService.setPremiumUpgradeLastSyncAttemptFailedCallCount == 1)
    }

    /// `start()` leaves the "Upgraded to Premium" card alone on a generic sync when there is no
    /// pending or failed upgrade to reconcile — otherwise every sync for a Premium account would
    /// resurrect a card the user already dismissed.
    @Test
    func start_doesNotSetUpgradedActionCard_whenNoPendingUpgrade() async throws {
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = true

        await subject.start()
        // See the comment in `start_clearsLastAttemptFailedOnGenericSyncEvenWithoutPremium()`.
        // `start()` itself already reads the pending flag once via its initial
        // `refreshPremiumUpgradePendingStateSubject()` call, so the count below is 2, not 1.
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        try await stateService.setLastSyncTime(Date(), userId: nil)

        try await waitForAsync { stateService.getPremiumUpgradePendingCallCount == 2 }
        #expect(stateService.setUpgradedToPremiumActionCardVisibleCallCount == 0)
    }

    /// `start()` is idempotent — a second call does not create a duplicate subscription.
    @Test
    func start_isIdempotent() async throws {
        stateService.activeAccount = .fixture()

        await subject.start()
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        await subject.start()
        // Give a duplicate subscription a chance to have taken its own baseline snapshot before
        // asserting none did.
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(stateService.getLastSyncTimeCallCount == 1)
    }

    /// `start()` publishes the reconciled pending state after a background reconcile resolves
    /// it, so consumers of `premiumUpgradePendingStatePublisher()` observe the resolution even
    /// though it happened via a generic, unrelated sync rather than the checkout attempt's own
    /// subscription.
    @Test
    func start_publishesPendingStateAfterReconcile() async throws {
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = false
        stateService.premiumUpgradePendingResult = true
        var states = [PremiumUpgradePendingState]()
        let cancellable = subject.premiumUpgradePendingStatePublisher()
            .sink { states.append($0) }
        defer { cancellable.cancel() }

        await subject.start()
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }
        states.removeAll()

        stateService.doesActiveAccountHavePremiumResult = true
        try await stateService.setLastSyncTime(Date(), userId: nil)

        try await waitForAsync { !states.isEmpty }
        #expect(states.last == PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false))
    }

    /// `start()` resets the published pending state to a clean default when the account logs
    /// out, so a subscriber connecting during the unauthenticated window doesn't see a
    /// signed-out user's stale upgrade state.
    @Test
    func start_resetsPendingStateOnLogout() async throws {
        stateService.activeAccount = .fixture()
        stateService.premiumUpgradePendingResult = true
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        var states = [PremiumUpgradePendingState]()
        let cancellable = subject.premiumUpgradePendingStatePublisher()
            .sink { states.append($0) }
        defer { cancellable.cancel() }

        await subject.start()
        try await waitForAsync {
            states.last == PremiumUpgradePendingState(isPending: true, lastAttemptFailed: true)
        }

        stateService.activeIdSubject.send(nil)

        try await waitForAsync {
            states.last == PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false)
        }
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
        try await stateService.setLastSyncTime(Date(), userId: nil)

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
        try await stateService.setLastSyncTime(Date(), userId: nil)

        try await waitForAsync { stateService.upgradedToPremiumActionCardVisibleResult == true }
        #expect(stateService.premiumUpgradePendingResult == false)
    }

    /// `start()` cancels the previous account's sync subscriber on an account switch, so a sync
    /// belonging to the previous account doesn't also trigger a duplicate reconcile for the new
    /// one.
    @Test
    func start_resubscribesOnActiveAccountChange() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.doesActiveAccountHavePremiumResult = true

        await subject.start()
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        stateService.activeIdSubject.send("2")

        // The switch cancels account 1's `reconcileOnEachNewSync()` and starts a fresh one for
        // account 2, which re-snapshots its own baseline sync time.
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 2 }

        // If account 1's subscriber were still alive, this sync would reach the reconciler
        // twice instead of once.
        try await stateService.setLastSyncTime(Date(), userId: nil)
        try await waitForAsync { stateService.getPremiumUpgradePendingCallCount == 3 }
        #expect(stateService.getPremiumUpgradePendingCallCount == 3)
    }
}
