import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingServiceTests+ReconcileCheckoutTests

extension BillingServiceTests {
    // MARK: Tests

    /// `reconcileCheckoutSuccess()` returns early without syncing when the user already has
    /// Premium — it shares the same eligibility check as `premiumStatusChanged()`.
    @Test
    func reconcileCheckoutSuccess_alreadyHasPremium() async throws {
        stateService.doesActiveAccountHavePremiumResult = true
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        #expect(statuses.isEmpty)
        #expect(!syncService.didFetchSync)
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

        try await waitForAsync { lateStatuses.isEmpty }
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

    /// `reconcileCheckoutSuccess()` records the sync failure but clears the pending mark
    /// immediately when `fetchSync` throws, and publishes the updated `PremiumUpgradePendingState`
    /// — the "Upgrade to Premium" CTA must reappear on failure, not stay hidden indefinitely.
    @Test
    func reconcileCheckoutSuccess_syncError_recordsFailureAndClearsPending() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var pendingStates = [PremiumUpgradePendingState]()
        let cancellable = subject.premiumUpgradePendingStatePublisher()
            .sink { pendingStates.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == true)
        #expect(stateService.premiumUpgradePendingResult == false)
        #expect(pendingStates == [
            PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false),
            PremiumUpgradePendingState(isPending: true, lastAttemptFailed: false),
            PremiumUpgradePendingState(isPending: false, lastAttemptFailed: true),
        ])
    }

    /// `reconcileCheckoutSuccess()` still clears the pending mark on sync failure even if recording
    /// the failure itself throws — each state write is independent, so one throwing does not skip
    /// the others.
    @Test
    func reconcileCheckoutSuccess_syncError_clearsPendingEvenIfRecordingFailureThrows() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        stateService.setPremiumUpgradeLastSyncAttemptFailedResult = .failure(URLError(.notConnectedToInternet))
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))

        await subject.reconcileCheckoutSuccess()

        #expect(stateService.premiumUpgradePendingResult == false)
    }
}
