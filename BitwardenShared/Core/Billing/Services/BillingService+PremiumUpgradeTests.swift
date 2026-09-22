// swiftlint:disable:this file_name

import BitwardenKitMocks
import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - PremiumUpgradeStateStore

/// Backing per-user-id storage for `MockBillingStateService`'s premium-upgrade-pending state.
final class PremiumUpgradeStateStore {
    var pendingByUserId = [String: Bool]()
    var upgradedToPremiumCardVisibleByUserId = [String: Bool]()

    /// How many times `pendingByUserId` has been written. Lets a test wait on a resolution that
    /// re-persists the value it already held, which `pendingByUserId` alone can't distinguish.
    var pendingWriteCount = 0
}

extension MockStateService {
    /// Sets whether an account has Premium it purchased personally, updating both the personal
    /// and the inclusive accessors. A pending upgrade resolves on *personal* Premium, while the
    /// derived `PremiumUpgradeState` consults both, so a test simulating a purchase landing has
    /// to move the two together or the mock describes an account that can't exist.
    ///
    /// - Parameters:
    ///   - hasPremium: Whether the account has personally-purchased Premium.
    ///   - userId: The account to set Premium status for.
    ///
    func setPersonalPremium(_ hasPremium: Bool, userId: String) {
        doesAccountHavePremiumPersonallyByUserId[userId] = hasPremium
        doesAccountHavePremiumByUserId[userId] = hasPremium
    }
}

extension MockBillingStateService {
    /// Wires this mock's premium-upgrade-pending methods to per-user-id backing storage.
    func setUpPremiumUpgradeState(stateService: MockStateService) -> PremiumUpgradeStateStore {
        let state = PremiumUpgradeStateStore()

        getPremiumUpgradePendingClosure = { userId in
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            return state.pendingByUserId[userId] ?? false
        }
        setPremiumUpgradePendingClosure = { pending, userId in
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            state.pendingByUserId[userId] = pending
            state.pendingWriteCount += 1
        }
        getUpgradedToPremiumActionCardVisibleClosure = { userId in
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            return state.upgradedToPremiumCardVisibleByUserId[userId] ?? false
        }
        setUpgradedToPremiumActionCardVisibleClosure = { visible, userId in
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            state.upgradedToPremiumCardVisibleByUserId[userId] = visible
        }

        return state
    }
}

// MARK: - BillingServicePremiumUpgradeTests

/// Tests for the `BillingService` methods that persist and resolve a pending Premium upgrade.
@MainActor
struct BillingServicePremiumUpgradeTests {
    // MARK: Properties

    var billingAPIService: MockBillingAPIService!
    var billingStateService: MockBillingStateService!
    var configService: MockConfigService!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var premiumUpgradeStorage: PremiumUpgradeStateStore!
    var stateService: MockStateService!
    var syncService: MockSyncService!
    var subject: DefaultBillingService!

    // MARK: Initialization

    init() {
        billingAPIService = MockBillingAPIService()
        billingAPIService.getSubscriptionReturnValue = .fixture()
        billingStateService = MockBillingStateService()
        configService = MockConfigService()
        configService.featureFlagsBool[.premiumUpgradePath] = true
        environmentService = MockEnvironmentService()
        environmentService.region = .unitedStates
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        stateService.activeAccount = .fixture()
        premiumUpgradeStorage = billingStateService.setUpPremiumUpgradeState(stateService: stateService)
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

    // MARK: resolveCheckoutSuccess

    /// `resolveCheckoutSuccess()` marks the upgrade pending, syncs, and publishes `.confirmed`
    /// when the sync confirms Premium.
    @Test
    func resolveCheckoutSuccess_confirmed() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncHandler = {
            stateService.setPersonalPremium(true, userId: "1")
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.resolveCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
        #expect(syncService.didFetchSync)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == false)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `resolveCheckoutSuccess()` leaves the upgrade pending and publishes `.pending` when the
    /// sync succeeds but Premium hasn't been granted yet.
    @Test
    func resolveCheckoutSuccess_pending() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.resolveCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
    }

    /// `resolveCheckoutSuccess()` leaves the upgrade pending (so a later sync can retry), logs
    /// the error, and publishes `.pending` when the forced sync throws.
    @Test
    func resolveCheckoutSuccess_syncError() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.resolveCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(errorReporter.errors.first is URLError)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
    }

    /// `resolveCheckoutSuccess()` still resolves the upgrade when Premium was granted by a sync
    /// that later threw on an unrelated step — the profile is persisted early in `fetchSync()`,
    /// so a throwing sync and a confirmed upgrade aren't mutually exclusive.
    @Test
    func resolveCheckoutSuccess_syncErrorAfterPremiumConfirmed() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncHandler = {
            stateService.setPersonalPremium(true, userId: "1")
        }
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))

        await subject.resolveCheckoutSuccess()

        #expect(premiumUpgradeStorage.pendingByUserId["1"] == false)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `resolveCheckoutSuccess()` does nothing when the environment is self-hosted.
    @Test
    func resolveCheckoutSuccess_selfHosted_doesNothing() async {
        environmentService.region = .selfHosted

        await subject.resolveCheckoutSuccess()

        #expect(!syncService.didFetchSync)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == nil)
    }

    /// `resolveCheckoutSuccess()` does nothing when the premiumUpgradePath feature flag is disabled.
    @Test
    func resolveCheckoutSuccess_featureFlagDisabled_doesNothing() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false

        await subject.resolveCheckoutSuccess()

        #expect(!syncService.didFetchSync)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == nil)
    }

    /// `resolveCheckoutSuccess()` does nothing when there's no active account to resolve for.
    @Test
    func resolveCheckoutSuccess_noActiveAccount_doesNothing() async {
        stateService.activeAccount = nil

        await subject.resolveCheckoutSuccess()

        #expect(!syncService.didFetchSync)
    }

    /// `resolveCheckoutSuccess()` still persists the correct result for the account it started
    /// for, even if the active account switches away while its forced sync is in flight — and
    /// doesn't publish a checkout status meant for the now-active (unrelated) account.
    @Test
    func resolveCheckoutSuccess_accountSwitchedDuringSync_writesOriginalAccountOnly() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncHandler = {
            stateService.setPersonalPremium(true, userId: "1")
            stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.resolveCheckoutSuccess()

        #expect(statuses.isEmpty)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == false)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == true)
        #expect(premiumUpgradeStorage.pendingByUserId["2"] == nil)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["2"] == nil)
    }

    /// `resolveCheckoutSuccess()` still reports `.confirmed` when the pending flags it set are
    /// already cleared by the time its own resolution step runs — e.g.
    /// `startResolvingPendingUpgrades()`'s background sync watcher reacting to this same forced
    /// sync and resolving it first.
    @Test
    func resolveCheckoutSuccess_alreadyResolvedByConcurrentSync_stillReportsConfirmed() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncHandler = {
            // Simulates `startResolvingPendingUpgrades()`'s background watcher
            // (`resolveOnEachNewSync(userId:)`) winning the race.
            stateService.setPersonalPremium(true, userId: "1")
            premiumUpgradeStorage.pendingByUserId["1"] = false
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.resolveCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
    }

    // MARK: startResolvingPendingUpgrades

    /// `startResolvingPendingUpgrades()` resolves a pending upgrade the moment it starts
    /// observing an account that already has one recorded (e.g. left over from a previous app
    /// session).
    @Test
    func startResolvingPendingUpgrades_resolvesExistingPendingUpgradeOnFirstSync() async throws {
        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.setPersonalPremium(true, userId: "1")

        await subject.startResolvingPendingUpgrades()
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { premiumUpgradeStorage.pendingByUserId["1"] == false }
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `startResolvingPendingUpgrades()` resolves a pending upgrade on a later, unrelated sync —
    /// not just the sync that originated the checkout attempt (the "delayed sync" case: Settings >
    /// Sync Now, or a sync triggered from the web vault).
    @Test
    func startResolvingPendingUpgrades_resolvesPendingUpgradeOnDelayedSync() async throws {
        await subject.startResolvingPendingUpgrades()

        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.setPersonalPremium(false, userId: "1")
        stateService.lastSyncTimeSubject.send(Date())
        try await waitForAsync { premiumUpgradeStorage.pendingWriteCount == 1 }
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)

        stateService.setPersonalPremium(true, userId: "1")
        stateService.lastSyncTimeSubject.send(Date(timeIntervalSinceNow: 1))

        try await waitForAsync { premiumUpgradeStorage.pendingByUserId["1"] == false }
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `startResolvingPendingUpgrades()`'s background sync watcher leaves an account with no
    /// pending upgrade untouched, so a normal sync for a long-since-Premium or free account never
    /// spuriously shows the "Upgraded to Premium" card.
    @Test
    func startResolvingPendingUpgrades_ignoresSyncsWithNoPendingUpgrade() async throws {
        stateService.setPersonalPremium(true, userId: "1")

        await subject.startResolvingPendingUpgrades()
        stateService.lastSyncTimeSubject.send(Date())

        // Give the background watcher a chance to (not) act before asserting nothing changed.
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == nil)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == nil)
    }

    /// `startResolvingPendingUpgrades()` only subscribes once, ignoring subsequent calls.
    @Test
    func startResolvingPendingUpgrades_subscribesOnlyOnce() async throws {
        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.setPersonalPremium(true, userId: "1")

        await subject.startResolvingPendingUpgrades()
        await subject.startResolvingPendingUpgrades()
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { premiumUpgradeStorage.pendingByUserId["1"] == false }
    }

    // MARK: premiumUpgradeStatePublisher

    /// `premiumUpgradeStatePublisher()` replays the current state to a new subscriber
    /// immediately, then re-emits it as `resolveCheckoutSuccess()` refreshes it: once pending,
    /// right before its forced sync, and again as `.premium` once the sync confirms it.
    @Test
    func premiumUpgradeStatePublisher_emitsOnResolveCheckoutSuccess() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncHandler = {
            stateService.setPersonalPremium(true, userId: "1")
        }
        var states = [PremiumUpgradeState]()
        let cancellable = subject.premiumUpgradeStatePublisher()
            .sink { states.append($0) }
        defer { cancellable.cancel() }

        try await waitForAsync { !states.isEmpty }

        await subject.resolveCheckoutSuccess()

        try await waitForAsync { states.count == 3 }
        #expect(states == [
            .notPremium,
            .pending,
            .premium,
        ])
    }

    /// `startResolvingPendingUpgrades()` resets `premiumUpgradeStatePublisher()` to
    /// `.notPremium` the instant the active account logs out, as a direct push rather than a
    /// `billingStateService` read — the logged-out account's own persisted flags are left
    /// untouched for whenever it's active again.
    @Test
    func premiumUpgradeStatePublisher_resetsOnLogout() async throws {
        var states = [PremiumUpgradeState]()
        let cancellable = subject.premiumUpgradeStatePublisher()
            .sink { states.append($0) }
        defer { cancellable.cancel() }

        await subject.startResolvingPendingUpgrades()
        try await waitForAsync { states.count == 2 }

        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.setPersonalPremium(false, userId: "1")
        stateService.lastSyncTimeSubject.send(Date())
        try await waitForAsync { states.count == 3 }
        #expect(states.last == .pending)

        stateService.activeIdSubject.send(nil)

        try await waitForAsync { states.count == 4 }
        #expect(states.last == .notPremium)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
    }
}
