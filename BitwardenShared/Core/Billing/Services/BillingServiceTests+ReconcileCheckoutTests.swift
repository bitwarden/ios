import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingServiceTests+ReconcileCheckoutTests

extension BillingServiceTests {
    // MARK: Tests

    /// `reconcileCheckoutSuccess()` abandons the reconcile without writing or publishing anything
    /// if the active account changes while suspended in the forced `fetchSync()` above — the
    /// "Sync Now" caller (`PremiumUpgradeHelper`'s `.pending` case) dismisses to an interactive
    /// vault list before this method runs, so an account switch during that sync is a real
    /// window, and none of `billingStateService`'s calls are per-user.
    @Test
    func reconcileCheckoutSuccess_abandonsWriteOnAccountSwitchDuringSync() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        syncService.fetchSyncHandler = {
            // Simulates the account switch landing exactly inside this suspension window.
            stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        #expect(statuses.isEmpty)
        #expect(stateService.premiumUpgradePendingResult == true)
        #expect(stateService.setPremiumUpgradeLastSyncAttemptFailedCallCount == 0)
        #expect(stateService.setUpgradedToPremiumActionCardVisibleCallCount == 0)
    }

    /// `reconcileCheckoutSuccess()` still syncs and confirms the upgrade when the account already
    /// has Premium going in — unlike `premiumStatusChanged()`'s identical-looking guard, "already
    /// Premium" here is the success case (a webhook grant picked up by an unrelated sync while
    /// the checkout sheet was still open), not a no-op.
    @Test
    func reconcileCheckoutSuccess_alreadyHasPremium() async throws {
        stateService.doesActiveAccountHavePremiumResult = true
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
        #expect(syncService.didFetchSync)
        #expect(stateService.premiumUpgradePendingResult == false)
        #expect(stateService.upgradedToPremiumActionCardVisibleResult == true)
    }

    /// `reconcileCheckoutSuccess()` publishes `.confirmed` when the user gains Premium after
    /// sync, and marks the upgrade pending for the duration of that sync.
    @Test
    func reconcileCheckoutSuccess_confirmed() async throws {
        // Start as non-Premium so the guard passes, then switch to Premium after sync.
        stateService.doesActiveAccountHavePremiumResult = false
        var pendingDuringSync = false
        syncService.fetchSyncHandler = {
            pendingDuringSync = stateService.premiumUpgradePendingResult
            stateService.doesActiveAccountHavePremiumResult = true
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        // With instant mock sync, .syncing and .confirmed arrive within the 300ms debounce
        // window, so only .confirmed (the last value) is delivered.
        try await waitForAsync { !statuses.isEmpty }
        #expect(pendingDuringSync)
        #expect(statuses == [.confirmed])
        #expect(syncService.didFetchSync)
    }

    /// `reconcileCheckoutSuccess()` clears both the pending and failure flags once the user is
    /// confirmed Premium.
    @Test
    func reconcileCheckoutSuccess_confirmed_clearsPendingState() async throws {
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }

        await subject.reconcileCheckoutSuccess()

        #expect(stateService.premiumUpgradePendingResult == false)
        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
    }

    /// `reconcileCheckoutSuccess()` resets the publisher value to nil after emitting `.confirmed`,
    /// so late subscribers do not receive a stale `.confirmed` on connection.
    @Test
    func reconcileCheckoutSuccess_confirmed_resetsPublisherValue() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }
        var earlyStatuses = [PremiumCheckoutStatus]()
        let earlyCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { earlyStatuses.append($0) }
        defer { earlyCancellable.cancel() }

        await subject.reconcileCheckoutSuccess()
        try await waitForAsync { !earlyStatuses.isEmpty }

        // A subscriber connecting after .confirmed + nil are emitted should receive nothing.
        var lateStatuses = [PremiumCheckoutStatus]()
        let lateCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { lateStatuses.append($0) }
        defer { lateCancellable.cancel() }

        // Give a stale replay a chance to arrive before asserting none did.
        try await Task.sleep(nanoseconds: 250_000_000)
        #expect(lateStatuses.isEmpty)
    }

    /// `reconcileCheckoutSuccess()` returns early without syncing when the premiumUpgradePath
    /// flag is disabled, regardless of the account's current Premium status.
    @Test
    func reconcileCheckoutSuccess_featureFlagDisabled() async throws {
        configService.featureFlagsBool[.premiumUpgradePath] = false
        stateService.doesActiveAccountHavePremiumResult = true

        await subject.reconcileCheckoutSuccess()

        #expect(!syncService.didFetchSync)
    }

    /// `reconcileCheckoutSuccess()` publishes `.pending` when the user does not have Premium
    /// after sync, and leaves the upgrade pending — the sync itself succeeded, so a later,
    /// unrelated sync can still resolve this via `reconcilePendingUpgradeIfNeeded()`.
    @Test
    func reconcileCheckoutSuccess_pending() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(syncService.didFetchSync)
        #expect(stateService.premiumUpgradePendingResult == true)
    }

    /// `reconcileCheckoutSuccess()` records no failure and leaves the upgrade pending when sync
    /// succeeds but the user is still not Premium.
    @Test
    func reconcileCheckoutSuccess_pending_staysPendingNoFailureRecorded() async throws {
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.reconcileCheckoutSuccess()

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
        #expect(stateService.premiumUpgradePendingResult == true)
    }

    /// `reconcileCheckoutSuccess()` returns early without syncing when the environment is
    /// self-hosted, regardless of the account's current Premium status.
    @Test
    func reconcileCheckoutSuccess_selfHosted() async throws {
        environmentService.region = .selfHosted
        stateService.doesActiveAccountHavePremiumResult = true

        await subject.reconcileCheckoutSuccess()

        #expect(!syncService.didFetchSync)
    }

    /// `reconcileCheckoutSuccess()`'s forced sync writing the last-sync time before the sync has
    /// fully resolved — exactly like the real `fetchSync()`, which persists it before several
    /// later steps that can still throw — does not let the background reconciler
    /// (`reconcilePendingUpgradeIfNeeded()`, subscribed via `start()`) race this method's own
    /// resolution of `lastAttemptFailed` for the same sync. Without the suppression, the
    /// reconciler's unconditional clear could stomp the genuine failure recorded below.
    @Test
    func reconcileCheckoutSuccess_suppressesConcurrentReconcileForOwnSync() async throws {
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.start()
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        syncService.fetchSyncHandler = {
            // Simulates the real `fetchSync()`'s last-sync-time write landing before the later
            // step below throws — the same ordering that lets the background reconciler observe
            // this sync before it's actually resolved.
            stateService.lastSyncTimeSubject.value = Date()
        }
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))

        await subject.reconcileCheckoutSuccess()

        // Give the background reconciler a chance to have acted on the emission above before
        // asserting it didn't race the write below.
        try await Task.sleep(nanoseconds: 250_000_000)
        #expect(stateService.setPremiumUpgradeLastSyncAttemptFailedCallCount == 1)
        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == true)
    }

    /// `reconcileCheckoutSuccess()` reports the error and publishes `.pending` when sync fails.
    @Test
    func reconcileCheckoutSuccess_syncError() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(errorReporter.errors.first is URLError)
    }

    /// `reconcileCheckoutSuccess()` leaves the pending mark set on sync failure even if recording
    /// the failure itself throws — clearing it here would lose the only record that this checkout
    /// ever succeeded with Stripe.
    @Test
    func reconcileCheckoutSuccess_syncError_leavesPendingSetEvenIfRecordingFailureThrows() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        stateService.setPremiumUpgradeLastSyncAttemptFailedResult = .failure(URLError(.notConnectedToInternet))
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))

        await subject.reconcileCheckoutSuccess()

        #expect(stateService.premiumUpgradePendingResult == true)
    }

    /// `reconcileCheckoutSuccess()` does not record a failure when `fetchSync` throws after Premium
    /// was already confirmed — the profile (and its Premium status) is persisted early in
    /// `fetchSync()`, so a later step in that same sync can still throw once the grant already
    /// landed. A confirmed upgrade must never end up persisting a contradictory failure flag.
    @Test
    func reconcileCheckoutSuccess_syncError_premiumGranted_doesNotRecordFailure() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))

        await subject.reconcileCheckoutSuccess()

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
        #expect(stateService.premiumUpgradePendingResult == false)
        #expect(stateService.upgradedToPremiumActionCardVisibleResult == true)
        #expect(errorReporter.errors.first is URLError)
    }

    /// `reconcileCheckoutSuccess()` records the sync failure but leaves the pending mark set when
    /// `fetchSync` throws, and publishes the updated `PremiumUpgradePendingState` — clearing
    /// `isPending` here would lose the only record that this checkout ever succeeded with Stripe,
    /// stranding a later webhook grant with nothing pending left to resolve it.
    @Test
    func reconcileCheckoutSuccess_syncError_recordsFailureAndLeavesPending() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var pendingStates = [PremiumUpgradePendingState]()
        let cancellable = subject.premiumUpgradePendingStatePublisher()
            .sink { pendingStates.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == true)
        #expect(stateService.premiumUpgradePendingResult == true)
        #expect(pendingStates == [
            PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false),
            PremiumUpgradePendingState(isPending: true, lastAttemptFailed: false),
            PremiumUpgradePendingState(isPending: true, lastAttemptFailed: true),
        ])
    }
}
