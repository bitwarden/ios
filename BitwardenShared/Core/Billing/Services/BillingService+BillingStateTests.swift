// swiftlint:disable:this file_name

import BitwardenKitMocks
import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - PremiumUpgradeStateStore

/// Backing per-user-id storage for `MockBillingStateService`'s premium-upgrade-pending state,
/// wired up by `MockBillingStateService.setUpPremiumUpgradeState(stateService:)` below.
final class PremiumUpgradeStateStore {
    var pendingByUserId = [String: Bool]()
    var syncAttemptFailedByUserId = [String: Bool]()
    var upgradedToPremiumCardVisibleByUserId = [String: Bool]()
}

/// Resolves a `nil` `userId` to `stateService`'s active account, mirroring
/// `BillingStateService`'s "defaults to the active account if `nil`" contract — which
/// `DefaultStateService` implements for real via `getActiveAccountUserId()`, but which
/// `MockBillingStateService`'s generated closures have no innate concept of. Throws
/// `StateServiceError.noActiveAccount` if `userId` is `nil` and there's no active account.
func resolvedUserId(_ userId: String?, stateService: MockStateService) throws -> String {
    if let userId {
        return userId
    }
    guard let activeAccount = stateService.activeAccount else {
        throw StateServiceError.noActiveAccount
    }
    return activeAccount.profile.userId
}

extension MockBillingStateService {
    // Wires this mock's premium-upgrade-pending methods to per-user-id backing storage. See
    // `resolvedUserId(_:stateService:)` for how `nil` `userId`s are resolved.
    func setUpPremiumUpgradeState(stateService: MockStateService) -> PremiumUpgradeStateStore {
        let state = PremiumUpgradeStateStore()

        getPremiumUpgradePendingClosure = { userId in
            try state.pendingByUserId[resolvedUserId(userId, stateService: stateService)] ?? false
        }
        setPremiumUpgradePendingClosure = { pending, userId in
            try state.pendingByUserId[resolvedUserId(userId, stateService: stateService)] = pending
        }
        getPremiumUpgradeLastSyncAttemptFailedClosure = { userId in
            try state.syncAttemptFailedByUserId[resolvedUserId(userId, stateService: stateService)] ?? false
        }
        setPremiumUpgradeLastSyncAttemptFailedClosure = { failed, userId in
            try state.syncAttemptFailedByUserId[resolvedUserId(userId, stateService: stateService)] = failed
        }
        getUpgradedToPremiumActionCardVisibleClosure = { userId in
            try state.upgradedToPremiumCardVisibleByUserId[resolvedUserId(userId, stateService: stateService)] ?? false
        }
        setUpgradedToPremiumActionCardVisibleClosure = { visible, userId in
            try state.upgradedToPremiumCardVisibleByUserId[resolvedUserId(userId, stateService: stateService)] = visible
        }

        return state
    }
}

// MARK: - BillingServiceBillingStateTests

// swiftlint:disable file_length

/// Tests for the `BillingService` methods that read or write cached billing state through
/// `billingStateService` — action card visibility, the subscription attention card, and
/// premium-upgrade-pending reconciliation. See `BillingServiceTests` for the rest.
@MainActor
struct BillingServiceBillingStateTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var billingAPIService: MockBillingAPIService!
    var billingStateService: MockBillingStateService!
    var configService: MockConfigService!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var premiumUpgradeState: PremiumUpgradeStateStore!
    var stateService: MockStateService!
    var syncService: MockSyncService!
    var subject: DefaultBillingService!

    // MARK: Initialization

    init() {
        billingAPIService = MockBillingAPIService()
        billingAPIService.getSubscriptionReturnValue = .fixture()
        billingStateService = MockBillingStateService()
        // `getSubscriptionAttentionCardVisible()`/`setSubscriptionAttentionCardVisible(_:)` take no
        // `userId`, so unlike the premium-upgrade-pending state above they need no per-account
        // storage — just mirroring writes back into the generated mock's own return value.
        let billingState: MockBillingStateService = billingStateService
        billingState.getSubscriptionAttentionCardVisibleReturnValue = false
        billingState.setSubscriptionAttentionCardVisibleClosure = { visible in
            billingState.getSubscriptionAttentionCardVisibleReturnValue = visible
        }
        configService = MockConfigService()
        configService.featureFlagsBool[.premiumUpgradePath] = true
        environmentService = MockEnvironmentService()
        environmentService.region = .unitedStates
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        stateService.activeAccount = .fixture()
        premiumUpgradeState = billingStateService.setUpPremiumUpgradeState(stateService: stateService)
        syncService = MockSyncService()
        subject = DefaultBillingService(
            billingAPIService: billingAPIService,
            billingStateService: billingStateService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            stateService: stateService,
            syncService: syncService,
            debounceInterval: .milliseconds(100),
        )
    }

    // MARK: setUpgradedToPremiumActionCardDismissed

    /// `setUpgradedToPremiumActionCardDismissed()` sets the visibility flag to `false` for the active account.
    @Test
    func setUpgradedToPremiumActionCardDismissed() async {
        premiumUpgradeState.upgradedToPremiumCardVisibleByUserId["1"] = true

        await subject.setUpgradedToPremiumActionCardDismissed()

        #expect(premiumUpgradeState.upgradedToPremiumCardVisibleByUserId["1"] == false)
    }

    /// `setUpgradedToPremiumActionCardDismissed()` logs an error if the state service throws.
    @Test
    func setUpgradedToPremiumActionCardDismissed_error() async {
        billingStateService.setUpgradedToPremiumActionCardVisibleThrowableError = StateServiceError.noActiveAccount

        await subject.setUpgradedToPremiumActionCardDismissed()

        #expect(errorReporter.errors.first as? StateServiceError == .noActiveAccount)
    }

    // MARK: shouldShowUpgradedToPremiumActionCard

    /// `shouldShowUpgradedToPremiumActionCard()` returns `true` when the state service reports the card is visible.
    @Test
    func shouldShowUpgradedToPremiumActionCard_visible() async {
        premiumUpgradeState.upgradedToPremiumCardVisibleByUserId["1"] = true

        let result = await subject.shouldShowUpgradedToPremiumActionCard()

        #expect(result == true)
    }

    /// `shouldShowUpgradedToPremiumActionCard()` returns `false` when the state service reports it is not visible.
    @Test
    func shouldShowUpgradedToPremiumActionCard_notVisible() async {
        premiumUpgradeState.upgradedToPremiumCardVisibleByUserId["1"] = false

        let result = await subject.shouldShowUpgradedToPremiumActionCard()

        #expect(result == false)
    }

    // MARK: refreshSubscriptionAttentionCard

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility based on
    /// whether the subscription status requires payment attention.
    @Test(arguments: [
        (SubscriptionStatus.pastDue, true),
        (SubscriptionStatus.unpaid, true),
        (SubscriptionStatus.active, false),
    ])
    func refreshSubscriptionAttentionCard_statusVisibility(
        status: SubscriptionStatus,
        expectedVisible: Bool,
    ) async {
        billingAPIService.getSubscriptionReturnValue = .fixture(status: status)

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(billingStateService.getSubscriptionAttentionCardVisibleReturnValue == expectedVisible)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility to `false`
    /// and skips the API call when the user is self-hosted.
    @Test
    func refreshSubscriptionAttentionCard_selfHosted() async {
        environmentService.region = .selfHosted

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(billingStateService.getSubscriptionAttentionCardVisibleReturnValue == false)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility to `false`
    /// and skips the API call when the feature flag is disabled.
    @Test
    func refreshSubscriptionAttentionCard_featureFlagDisabled() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(billingStateService.getSubscriptionAttentionCardVisibleReturnValue == false)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility to `false`
    /// and does not log an error when the user has no personal subscription (free user).
    @Test
    func refreshSubscriptionAttentionCard_noSubscription() async {
        billingAPIService.getSubscriptionThrowableError = GetSubscriptionRequestError.noSubscription

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(billingStateService.getSubscriptionAttentionCardVisibleReturnValue == false)
        #expect(errorReporter.errors.isEmpty)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` uses an already-fetched subscription
    /// instead of making a new API call when one is provided.
    @Test
    func refreshSubscriptionAttentionCard_usesProvidedSubscription() async {
        await subject.refreshSubscriptionAttentionCard(subscription: .fixture(status: .pastDue))

        #expect(billingStateService.getSubscriptionAttentionCardVisibleReturnValue == true)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility to `true`
    /// when a subscription with `.unpaid` status is provided directly (Plan screen path).
    @Test
    func refreshSubscriptionAttentionCard_unpaid_providedSubscription() async {
        await subject.refreshSubscriptionAttentionCard(subscription: .fixture(status: .unpaid))

        #expect(billingStateService.getSubscriptionAttentionCardVisibleReturnValue == true)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` logs the error and does not update
    /// the cache when the API call fails.
    @Test
    func refreshSubscriptionAttentionCard_apiError() async {
        billingAPIService.getSubscriptionThrowableError = URLError(.notConnectedToInternet)

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(billingStateService.getSubscriptionAttentionCardVisibleReturnValue == false)
        #expect(errorReporter.errors.first is URLError)
    }

    // MARK: shouldShowSubscriptionAttentionCard

    /// `shouldShowSubscriptionAttentionCard()` returns the cached value without making an API call.
    @Test
    func shouldShowSubscriptionAttentionCard_returnsFromCache() async {
        billingStateService.getSubscriptionAttentionCardVisibleReturnValue = true

        let result = await subject.shouldShowSubscriptionAttentionCard()

        #expect(result)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    // MARK: premiumUpgradePendingState

    /// `premiumUpgradePendingState()` reflects the persisted pending/failure flags for the active account.
    @Test
    func premiumUpgradePendingState_reflectsPersistedFlags() async {
        premiumUpgradeState.pendingByUserId["1"] = true
        premiumUpgradeState.syncAttemptFailedByUserId["1"] = true

        let result = await subject.premiumUpgradePendingState()

        #expect(result == PremiumUpgradePendingState(isPending: true, lastAttemptFailed: true))
    }

    /// `premiumUpgradePendingState()` returns a default, non-pending state and logs the error
    /// when the state service can't resolve the active account.
    @Test
    func premiumUpgradePendingState_error() async {
        stateService.activeAccount = nil

        let result = await subject.premiumUpgradePendingState()

        #expect(result == PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false))
        #expect(errorReporter.errors.first as? StateServiceError == .noActiveAccount)
    }

    // MARK: reconcileCheckoutSuccess

    /// `reconcileCheckoutSuccess()` marks the upgrade pending, syncs, and publishes `.confirmed`
    /// when the sync confirms Premium.
    @Test
    func reconcileCheckoutSuccess_confirmed() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        syncService.fetchSyncHandler = {
            stateService.doesAccountHavePremiumByUserId["1"] = true
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
        #expect(syncService.didFetchSync)
        #expect(premiumUpgradeState.pendingByUserId["1"] == false)
        #expect(premiumUpgradeState.syncAttemptFailedByUserId["1"] == false)
        #expect(premiumUpgradeState.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `reconcileCheckoutSuccess()` leaves the upgrade pending and publishes `.pending` when the
    /// sync succeeds but Premium hasn't been granted yet.
    @Test
    func reconcileCheckoutSuccess_pending() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(premiumUpgradeState.pendingByUserId["1"] == true)
        #expect(premiumUpgradeState.syncAttemptFailedByUserId["1"] == false)
    }

    /// `reconcileCheckoutSuccess()` records a sync failure (leaving the upgrade pending so a
    /// later sync can retry) and publishes `.pending` when the forced sync throws.
    @Test
    func reconcileCheckoutSuccess_syncError() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(errorReporter.errors.first is URLError)
        #expect(premiumUpgradeState.pendingByUserId["1"] == true)
        #expect(premiumUpgradeState.syncAttemptFailedByUserId["1"] == true)
    }

    /// `reconcileCheckoutSuccess()` never records a sync failure once Premium is confirmed, even
    /// if the sync that granted it later throws on an unrelated step.
    @Test
    func reconcileCheckoutSuccess_syncErrorAfterPremiumConfirmed() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        syncService.fetchSyncHandler = {
            stateService.doesAccountHavePremiumByUserId["1"] = true
        }
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))

        await subject.reconcileCheckoutSuccess()

        #expect(premiumUpgradeState.syncAttemptFailedByUserId["1"] == false)
        #expect(premiumUpgradeState.pendingByUserId["1"] == false)
        #expect(premiumUpgradeState.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `reconcileCheckoutSuccess()` does nothing when the environment is self-hosted.
    @Test
    func reconcileCheckoutSuccess_selfHosted_doesNothing() async {
        environmentService.region = .selfHosted

        await subject.reconcileCheckoutSuccess()

        #expect(!syncService.didFetchSync)
        #expect(premiumUpgradeState.pendingByUserId["1"] == nil)
    }

    /// `reconcileCheckoutSuccess()` does nothing when the premiumUpgradePath feature flag is disabled.
    @Test
    func reconcileCheckoutSuccess_featureFlagDisabled_doesNothing() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false

        await subject.reconcileCheckoutSuccess()

        #expect(!syncService.didFetchSync)
        #expect(premiumUpgradeState.pendingByUserId["1"] == nil)
    }

    /// `reconcileCheckoutSuccess()` does nothing when there's no active account to reconcile for.
    @Test
    func reconcileCheckoutSuccess_noActiveAccount_doesNothing() async {
        stateService.activeAccount = nil

        await subject.reconcileCheckoutSuccess()

        #expect(!syncService.didFetchSync)
    }

    /// `reconcileCheckoutSuccess()` still persists the correct result for the account it started
    /// for, even if the active account switches away while its forced sync is in flight — and
    /// doesn't publish a checkout status meant for the now-active (unrelated) account.
    @Test
    func reconcileCheckoutSuccess_accountSwitchedDuringSync_writesOriginalAccountOnly() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        syncService.fetchSyncHandler = {
            stateService.doesAccountHavePremiumByUserId["1"] = true
            stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        #expect(statuses.isEmpty)
        #expect(premiumUpgradeState.pendingByUserId["1"] == false)
        #expect(premiumUpgradeState.upgradedToPremiumCardVisibleByUserId["1"] == true)
        #expect(premiumUpgradeState.pendingByUserId["2"] == nil)
        #expect(premiumUpgradeState.upgradedToPremiumCardVisibleByUserId["2"] == nil)
    }

    /// `reconcileCheckoutSuccess()` still reports `.confirmed` when the pending flags it set are
    /// already cleared by the time its own resolution step runs — e.g. `start()`'s background
    /// sync watcher reacting to this same forced sync and resolving it first. Regression test for
    /// `resolvePendingUpgrade(userId:syncFailed:)`'s early-exit branch, which used to return a
    /// hardcoded `false` in this situation regardless of the account's actual Premium status.
    @Test
    func reconcileCheckoutSuccess_alreadyResolvedByConcurrentSync_stillReportsConfirmed() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        syncService.fetchSyncHandler = {
            // Simulates `start()`'s background watcher (`reconcileOnEachNewSync(userId:)`)
            // reacting to this same sync and resolving the pending upgrade before this call's own
            // `resolvePendingUpgrade(userId:syncFailed:)` runs.
            stateService.doesAccountHavePremiumByUserId["1"] = true
            premiumUpgradeState.pendingByUserId["1"] = false
            premiumUpgradeState.syncAttemptFailedByUserId["1"] = false
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
    }

    // MARK: start

    /// `start()` resolves a pending upgrade the moment it starts observing an account that
    /// already has one recorded (e.g. left over from a previous app session).
    @Test
    func start_resolvesExistingPendingUpgradeOnFirstSync() async throws {
        premiumUpgradeState.pendingByUserId["1"] = true
        stateService.doesAccountHavePremiumByUserId["1"] = true

        await subject.start()
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { premiumUpgradeState.pendingByUserId["1"] == false }
        #expect(premiumUpgradeState.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `start()` resolves a pending upgrade on a later, unrelated sync — not just the sync that
    /// originated the checkout attempt (the "delayed sync" case: Settings > Sync Now, or a sync
    /// triggered from the web vault).
    @Test
    func start_resolvesPendingUpgradeOnDelayedSync() async throws {
        await subject.start()

        premiumUpgradeState.pendingByUserId["1"] = true
        stateService.doesAccountHavePremiumByUserId["1"] = false
        stateService.lastSyncTimeSubject.send(Date())
        try await waitForAsync { premiumUpgradeState.syncAttemptFailedByUserId["1"] == false }
        #expect(premiumUpgradeState.pendingByUserId["1"] == true)

        stateService.doesAccountHavePremiumByUserId["1"] = true
        stateService.lastSyncTimeSubject.send(Date(timeIntervalSinceNow: 1))

        try await waitForAsync { premiumUpgradeState.pendingByUserId["1"] == false }
        #expect(premiumUpgradeState.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `start()`'s background sync watcher leaves an account with no pending upgrade (and no
    /// prior failure) untouched, so a normal sync for a long-since-Premium or free account never
    /// spuriously shows the "Upgraded to Premium" card.
    @Test
    func start_ignoresSyncsWithNoPendingUpgrade() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = true

        await subject.start()
        stateService.lastSyncTimeSubject.send(Date())

        // Give the background watcher a chance to (not) act before asserting nothing changed.
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(premiumUpgradeState.pendingByUserId["1"] == nil)
        #expect(premiumUpgradeState.upgradedToPremiumCardVisibleByUserId["1"] == nil)
    }

    /// `start()` only subscribes once, ignoring subsequent calls.
    @Test
    func start_subscribesOnlyOnce() async throws {
        premiumUpgradeState.pendingByUserId["1"] = true
        stateService.doesAccountHavePremiumByUserId["1"] = true

        await subject.start()
        await subject.start()
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { premiumUpgradeState.pendingByUserId["1"] == false }
    }

    // MARK: premiumUpgradePendingStatePublisher

    /// `premiumUpgradePendingStatePublisher()` replays the current state to a new subscriber
    /// immediately, then re-emits it as `reconcileCheckoutSuccess()` refreshes it: once pending,
    /// right before its forced sync, and again once resolved after the sync confirms Premium.
    @Test
    func premiumUpgradePendingStatePublisher_emitsOnReconcileCheckoutSuccess() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        syncService.fetchSyncHandler = {
            stateService.doesAccountHavePremiumByUserId["1"] = true
        }
        var states = [PremiumUpgradePendingState]()
        let cancellable = subject.premiumUpgradePendingStatePublisher()
            .sink { states.append($0) }
        defer { cancellable.cancel() }

        try await waitForAsync { !states.isEmpty }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { states.count == 3 }
        #expect(states == [
            PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false),
            PremiumUpgradePendingState(isPending: true, lastAttemptFailed: false),
            PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false),
        ])
    }

    /// `start()` resets `premiumUpgradePendingStatePublisher()` to the default, non-pending state
    /// the instant the active account logs out, as a direct push rather than a
    /// `billingStateService` read — the logged-out account's own persisted flags are left
    /// untouched for whenever it's active again.
    @Test
    func premiumUpgradePendingStatePublisher_resetsOnLogout() async throws {
        var states = [PremiumUpgradePendingState]()
        let cancellable = subject.premiumUpgradePendingStatePublisher()
            .sink { states.append($0) }
        defer { cancellable.cancel() }

        await subject.start()
        try await waitForAsync { states.count == 2 }

        premiumUpgradeState.pendingByUserId["1"] = true
        stateService.doesAccountHavePremiumByUserId["1"] = false
        stateService.lastSyncTimeSubject.send(Date())
        try await waitForAsync { states.count == 3 }
        #expect(states.last == PremiumUpgradePendingState(isPending: true, lastAttemptFailed: false))

        stateService.activeIdSubject.send(nil)

        try await waitForAsync { states.count == 4 }
        #expect(states.last == PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false))
        #expect(premiumUpgradeState.pendingByUserId["1"] == true)
    }
}
