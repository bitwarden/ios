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
    /// derived `PremiumUpgradeLifecycleState` consults both, so a test simulating a purchase landing has
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

    // MARK: premiumCheckoutSucceeded

    /// `premiumCheckoutSucceeded()` still persists the correct result for the account it started
    /// for, even if the active account switches away while its forced sync is in flight — and
    /// doesn't publish a checkout status meant for the now-active (unrelated) account.
    @Test
    func premiumCheckoutSucceeded_accountSwitchedDuringSync_writesOriginalAccountOnly() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncHandler = {
            stateService.setPersonalPremium(true, userId: "1")
            stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumCheckoutSucceeded()

        #expect(statuses.isEmpty)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == false)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == true)
        #expect(premiumUpgradeStorage.pendingByUserId["2"] == nil)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["2"] == nil)
    }

    /// `premiumCheckoutSucceeded()` still reports `.confirmed` when the pending flag it set is
    /// already cleared by the time its own resolution step runs — which is the normal case, since
    /// its forced sync reaches `onFetchSyncSucceeded(userId:)` and resolves the upgrade first.
    @Test
    func premiumCheckoutSucceeded_alreadyResolvedByConcurrentSync_stillReportsConfirmed() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncHandler = {
            // Simulates the sync delegate's `resolvePendingUpgrade(userId:)` resolving this
            // same forced sync before `premiumCheckoutSucceeded()` gets to its own resolution.
            stateService.setPersonalPremium(true, userId: "1")
            premiumUpgradeStorage.pendingByUserId["1"] = false
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumCheckoutSucceeded()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
    }

    /// `premiumCheckoutSucceeded()` marks the upgrade pending, syncs, and publishes `.confirmed`
    /// when the sync confirms Premium.
    @Test
    func premiumCheckoutSucceeded_confirmed() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncHandler = {
            stateService.setPersonalPremium(true, userId: "1")
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumCheckoutSucceeded()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
        #expect(syncService.didFetchSync)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == false)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `premiumCheckoutSucceeded()` does nothing when the premiumUpgradePath feature flag is disabled.
    @Test
    func premiumCheckoutSucceeded_featureFlagDisabled_doesNothing() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false

        await subject.premiumCheckoutSucceeded()

        #expect(!syncService.didFetchSync)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == nil)
    }

    /// `premiumCheckoutSucceeded()` does nothing when there's no active account to resolve for.
    @Test
    func premiumCheckoutSucceeded_noActiveAccount_doesNothing() async {
        stateService.activeAccount = nil

        await subject.premiumCheckoutSucceeded()

        #expect(!syncService.didFetchSync)
    }

    /// `premiumCheckoutSucceeded()` leaves the upgrade pending and publishes `.pending` when the
    /// sync succeeds but Premium hasn't been granted yet.
    @Test
    func premiumCheckoutSucceeded_pending() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumCheckoutSucceeded()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
    }

    /// `premiumCheckoutSucceeded()` does nothing when the environment is self-hosted.
    @Test
    func premiumCheckoutSucceeded_selfHosted_doesNothing() async {
        environmentService.region = .selfHosted

        await subject.premiumCheckoutSucceeded()

        #expect(!syncService.didFetchSync)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == nil)
    }

    /// `premiumCheckoutSucceeded()` leaves the upgrade pending (so a later sync can retry), logs
    /// the error, and publishes `.pending` when the forced sync throws.
    @Test
    func premiumCheckoutSucceeded_syncError() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumCheckoutSucceeded()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(errorReporter.errors.first is URLError)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
    }

    /// `premiumCheckoutSucceeded()` still resolves the upgrade when Premium was granted by a sync
    /// that later threw on an unrelated step — the profile is persisted early in `fetchSync()`,
    /// so a throwing sync and a confirmed upgrade aren't mutually exclusive.
    @Test
    func premiumCheckoutSucceeded_syncErrorAfterPremiumConfirmed() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncHandler = {
            stateService.setPersonalPremium(true, userId: "1")
        }
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))

        await subject.premiumCheckoutSucceeded()

        #expect(premiumUpgradeStorage.pendingByUserId["1"] == false)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    // MARK: resolvePendingUpgrade

    /// `resolvePendingUpgrade(userId:)` resolves the account named by its parameter, not
    /// whichever account happens to be active — the sync it runs after belongs to that account.
    @Test
    func resolvePendingUpgrade_resolvesGivenAccountNotActiveAccount() async {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.setPersonalPremium(true, userId: "1")

        await subject.resolvePendingUpgrade(userId: "1")

        #expect(premiumUpgradeStorage.pendingByUserId["1"] == false)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == true)
        #expect(premiumUpgradeStorage.pendingByUserId["2"] == nil)
    }

    /// `resolvePendingUpgrade(userId:)` resolves a pending upgrade on a later, unrelated sync —
    /// not just the sync that originated the checkout attempt. This is QA's "delayed sync" case:
    /// Settings > Vault > Sync Now, or a sync triggered from the web vault.
    @Test
    func resolvePendingUpgrade_resolvesPendingUpgradeOnDelayedSync() async {
        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.setPersonalPremium(false, userId: "1")

        await subject.resolvePendingUpgrade(userId: "1")

        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == nil)

        stateService.setPersonalPremium(true, userId: "1")

        await subject.resolvePendingUpgrade(userId: "1")

        #expect(premiumUpgradeStorage.pendingByUserId["1"] == false)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `resolvePendingUpgrade(userId:)` leaves an account with no pending upgrade untouched, so
    /// a routine sync for a long-since-Premium or free account never spuriously shows the
    /// "Upgraded to Premium" card.
    @Test
    func resolvePendingUpgrade_withNoPendingUpgrade_doesNothing() async {
        stateService.setPersonalPremium(true, userId: "1")

        await subject.resolvePendingUpgrade(userId: "1")

        #expect(premiumUpgradeStorage.pendingByUserId["1"] == nil)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == nil)
    }

    /// `resolvePendingUpgrade(userId:)` doesn't treat organization-granted Premium as the
    /// personal purchase landing: the pending flag is only ever set by a personal checkout, so an
    /// organization grant arriving mid-flight must leave the upgrade pending and the card hidden.
    @Test
    func resolvePendingUpgrade_withOrganizationPremiumOnly_staysPending() async {
        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.doesAccountHavePremiumPersonallyByUserId["1"] = false
        stateService.doesAccountHavePremiumByUserId["1"] = true

        await subject.resolvePendingUpgrade(userId: "1")

        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == nil)
    }

    /// `resolvePendingUpgrade(userId:)` logs the error and leaves persisted state alone when
    /// reading the pending flag throws.
    @Test
    func resolvePendingUpgrade_withReadError_logsError() async {
        billingStateService.getPremiumUpgradePendingClosure = { _ in
            throw BitwardenTestError.example
        }

        await subject.resolvePendingUpgrade(userId: "1")

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == nil)
    }
}
