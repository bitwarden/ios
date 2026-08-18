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

    /// `premiumStatusChanged()` publishes `.confirmed` when the user gains Premium after sync.
    @Test
    func premiumStatusChanged_confirmed() async throws {
        stateService.premiumUpgradePendingResult = true
        // Start as non-Premium so the guard passes, then switch to Premium after sync.
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        // With instant mock sync, .syncing and .confirmed arrive within the 300ms debounce
        // window, so only .confirmed (the last value) is delivered.
        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
        #expect(syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` clears both the pending and failure flags once the user is
    /// confirmed Premium.
    @Test
    func premiumStatusChanged_confirmed_clearsPendingState() async throws {
        stateService.premiumUpgradePendingResult = true
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }

        await subject.premiumStatusChanged()

        #expect(stateService.premiumUpgradePendingResult == false)
        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
    }

    /// `premiumStatusChanged()` resets the publisher value to nil after emitting `.confirmed`,
    /// so late subscribers do not receive a stale `.confirmed` on connection.
    @Test
    func premiumStatusChanged_confirmed_resetsPublisherValue() async throws {
        stateService.premiumUpgradePendingResult = true
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }
        var earlyStatuses = [PremiumCheckoutStatus]()
        let earlyCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { earlyStatuses.append($0) }
        defer { earlyCancellable.cancel() }

        await subject.premiumStatusChanged()
        try await waitForAsync { !earlyStatuses.isEmpty }

        // A subscriber connecting after .confirmed + nil are emitted should receive nothing.
        var lateStatuses = [PremiumCheckoutStatus]()
        let lateCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { lateStatuses.append($0) }
        defer { lateCancellable.cancel() }

        try await waitForAsync { lateStatuses.isEmpty }
    }

    /// `premiumStatusChanged()` returns early without syncing when the premiumUpgradePath flag is disabled.
    @Test
    func premiumStatusChanged_featureFlagDisabled() async throws {
        configService.featureFlagsBool[.premiumUpgradePath] = false
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        #expect(statuses.isEmpty)
        #expect(!syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` does nothing when no upgrade is pending — this is the boundary
    /// that keeps a `.premiumStatusChanged` push notification (which isn't tied to any local
    /// checkout attempt) from marking an account pending just because it happens to not be
    /// Premium yet.
    @Test
    func premiumStatusChanged_notPending_doesNothing() async throws {
        stateService.premiumUpgradePendingResult = false
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        #expect(statuses.isEmpty)
        #expect(stateService.premiumUpgradePendingResult == false)
    }

    /// `premiumStatusChanged()` still triggers a plain (non-forced) sync when no upgrade is
    /// pending, mirroring `.policyChanged`'s own push handling — an account that gained Premium
    /// via the web vault, another device, or an org still needs its profile refreshed locally,
    /// even though nothing here is a checkout attempt to reconcile.
    @Test
    func premiumStatusChanged_notPending_stillSyncsGenerically() async throws {
        stateService.premiumUpgradePendingResult = false
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.premiumStatusChanged()

        #expect(syncService.didFetchSync)
        #expect(syncService.fetchSyncForceSync == false)
    }

    /// `premiumStatusChanged()` publishes `.pending` when the user does not have Premium after sync.
    @Test
    func premiumStatusChanged_pending() async throws {
        stateService.premiumUpgradePendingResult = true
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` marks the upgrade pending without recording a failure when sync
    /// succeeds but the user is still not Premium.
    @Test
    func premiumStatusChanged_pending_noFailureRecorded() async throws {
        stateService.premiumUpgradePendingResult = true
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.premiumStatusChanged()

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
        #expect(stateService.premiumUpgradePendingResult == true)
    }

    /// `premiumStatusChanged()` returns early without syncing when the environment is self-hosted.
    @Test
    func premiumStatusChanged_selfHosted() async throws {
        environmentService.region = .selfHosted
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        #expect(statuses.isEmpty)
        #expect(!syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` syncs when self-hosted region is overridden by the debug flag.
    @Test
    func premiumStatusChanged_selfHosted_debugFlagEnabled_syncs() async throws {
        environmentService.region = .selfHosted
        configService.featureFlagsBool[.debugDisableSelfHostPremiumCheck] = true
        stateService.premiumUpgradePendingResult = true
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        try await waitForAsync { !statuses.isEmpty }
        #expect(syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` reports the error and publishes `.pending` when sync fails.
    @Test
    func premiumStatusChanged_syncError() async throws {
        stateService.premiumUpgradePendingResult = true
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(errorReporter.errors.first is URLError)
    }

    /// `premiumStatusChanged()` records the sync failure and marks the upgrade pending when
    /// `fetchSync` throws, and publishes the updated `PremiumUpgradePendingState`.
    @Test
    func premiumStatusChanged_syncError_recordsFailureAndPending() async throws {
        stateService.premiumUpgradePendingResult = true
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var pendingStates = [PremiumUpgradePendingState]()
        let cancellable = subject.premiumUpgradePendingStatePublisher()
            .sink { pendingStates.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == true)
        #expect(stateService.premiumUpgradePendingResult == true)
        #expect(pendingStates.last == PremiumUpgradePendingState(isPending: true, lastAttemptFailed: true))
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

        stateService.premiumUpgradePendingResult = true
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { stateService.premiumUpgradeLastSyncAttemptFailedResult == false }
        #expect(stateService.premiumUpgradePendingResult == true)
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
        stateService.premiumUpgradePendingResult = true
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

        stateService.premiumUpgradePendingResult = true
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        stateService.doesActiveAccountHavePremiumResult = true
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { stateService.premiumUpgradePendingResult == false }
        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
        #expect(stateService.upgradedToPremiumActionCardVisibleResult == true)
    }
}
