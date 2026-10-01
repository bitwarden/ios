// swiftlint:disable:this file_name

import BitwardenKitMocks
import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// swiftlint:disable file_length

// MARK: - PremiumUpgradeStateStore

/// Backing per-user-id storage for `MockBillingStateService`'s premium-upgrade-pending state.
final class PremiumUpgradeStateStore {
    var pendingByUserId = [String: Bool]()
    var upgradedToPremiumCardVisibleByUserId = [String: Bool]()
}

extension MockStateService {
    /// Sets whether an account has Premium it purchased personally, updating both the personal
    /// and the inclusive accessors. A pending upgrade completes on *personal* Premium, while the
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

// MARK: - BillingServicePremiumUpgradePendingTests

/// Tests for the `BillingService` methods that persist and complete a pending Premium upgrade.
///
@MainActor
struct BillingServicePremiumUpgradePendingTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let billingAPIService: MockBillingAPIService
    let billingStateService: MockBillingStateService
    let configService: MockConfigService
    let environmentService: MockEnvironmentService
    let errorReporter: MockErrorReporter
    let premiumUpgradeStorage: PremiumUpgradeStateStore
    let stateService: MockStateService
    let syncService: MockSyncService
    let subject: DefaultBillingService

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

    // MARK: completeUpgradeIfPending

    /// `completeUpgradeIfPending(userId:)` completes the account named by its parameter, not
    /// whichever account happens to be active — the sync it runs after belongs to that account.
    @Test
    func completeUpgradeIfPending_completesGivenAccountNotActiveAccount() async {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.setPersonalPremium(true, userId: "1")

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(premiumUpgradeStorage.pendingByUserId["1"] == false)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == true)
        #expect(premiumUpgradeStorage.pendingByUserId["2"] == nil)
    }

    /// `completeUpgradeIfPending(userId:)` completes a pending upgrade on a later, unrelated sync —
    /// not just the sync that originated the checkout attempt. This is QA's "delayed sync" case:
    /// Settings > Vault > Sync Now, or a sync triggered from the web vault.
    @Test
    func completeUpgradeIfPending_completesPendingUpgradeOnDelayedSync() async {
        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.setPersonalPremium(false, userId: "1")

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == nil)

        stateService.setPersonalPremium(true, userId: "1")

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(premiumUpgradeStorage.pendingByUserId["1"] == false)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `completeUpgradeIfPending(userId:)` leaves an account with no pending upgrade untouched, so
    /// a routine sync for a long-since-Premium or free account never spuriously shows the
    /// "Upgraded to Premium" card.
    @Test
    func completeUpgradeIfPending_withNoPendingUpgrade_doesNothing() async {
        stateService.setPersonalPremium(true, userId: "1")

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(premiumUpgradeStorage.pendingByUserId["1"] == nil)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == nil)
    }

    /// `completeUpgradeIfPending(userId:)` doesn't treat organization-granted Premium as the
    /// personal purchase landing: the pending flag is only ever set by a personal checkout, so an
    /// organization grant arriving mid-flight must leave the upgrade pending and the card hidden.
    @Test
    func completeUpgradeIfPending_withOrganizationPremiumOnly_staysPending() async {
        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.doesAccountHavePremiumPersonallyByUserId["1"] = false
        stateService.doesAccountHavePremiumByUserId["1"] = true

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == nil)
    }

    /// `completeUpgradeIfPending(userId:)` logs the error and leaves persisted state alone when
    /// reading the pending flag throws.
    @Test
    func completeUpgradeIfPending_withReadError_logsError() async {
        billingStateService.getPremiumUpgradePendingClosure = { _ in
            throw BitwardenTestError.example
        }

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == nil)
    }

    /// `completeUpgradeIfPending(userId:)` logs the error and leaves the card hidden when clearing
    /// the pending flag throws — the card is only revealed alongside a successful clear.
    @Test
    func completeUpgradeIfPending_withWriteError_logsError() async {
        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.setPersonalPremium(true, userId: "1")
        billingStateService.setPremiumUpgradePendingClosure = { _, _ in
            throw BitwardenTestError.example
        }

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == nil)
    }

    // MARK: premiumCheckoutSucceeded

    /// `premiumCheckoutSucceeded()` decides its result for the account it started for, even if the
    /// active account switches away while its forced sync is in flight, and marks only that
    /// account pending.
    @Test
    func premiumCheckoutSucceeded_accountSwitchedDuringSync_reportsOriginalAccount() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        stateService.setPersonalPremium(false, userId: "2")
        syncService.fetchSyncHandler = {
            stateService.setPersonalPremium(true, userId: "1")
            stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumCheckoutSucceeded()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
        #expect(premiumUpgradeStorage.pendingByUserId["2"] == nil)
    }

    /// `premiumCheckoutSucceeded()` marks the upgrade pending, force-syncs, and publishes
    /// `.confirmed` when the sync lands personal Premium. It only reads after the sync: clearing
    /// the flag and revealing the card belong to `completeUpgradeIfPending(userId:)`, and the
    /// attention card refresh belongs to the sync's own completion handling.
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
        #expect(syncService.fetchSyncForceSync == true)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == nil)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `premiumCheckoutSucceeded()` does nothing when the premiumUpgradePath feature flag is disabled.
    @Test
    func premiumCheckoutSucceeded_featureFlagDisabled_doesNothing() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false

        await subject.premiumCheckoutSucceeded()

        #expect(!syncService.didFetchSync)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == nil)
    }

    /// `premiumCheckoutSucceeded()` logs the error and publishes `.pending` without syncing when
    /// the active account can't be resolved, so the user gets the pending alert rather than
    /// nothing.
    @Test
    func premiumCheckoutSucceeded_noActiveAccount_logsErrorAndPublishesPending() async throws {
        stateService.activeAccount = nil
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumCheckoutSucceeded()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(errorReporter.errors.last as? StateServiceError == .noActiveAccount)
        #expect(!syncService.didFetchSync)
    }

    /// `premiumCheckoutSucceeded()` publishes `.pending` when the sync lands only
    /// organization-granted Premium — that isn't the personal purchase landing.
    @Test
    func premiumCheckoutSucceeded_organizationPremiumOnly_publishesPending() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncHandler = {
            stateService.doesAccountHavePremiumByUserId["1"] = true
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumCheckoutSucceeded()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
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

    /// `premiumCheckoutSucceeded()` leaves the upgrade pending (so a later sync can complete it),
    /// logs the error, and publishes `.pending` when the forced sync throws.
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

    /// `premiumCheckoutSucceeded()` publishes `.pending` when the sync throws, even if it persisted
    /// personal Premium before throwing — a failed sync never reaches the sync-completed
    /// handling, so the upgrade stays pending for the next successful sync to complete.
    @Test
    func premiumCheckoutSucceeded_syncErrorAfterPremiumLanded_publishesPending() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncHandler = {
            stateService.setPersonalPremium(true, userId: "1")
        }
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumCheckoutSucceeded()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == nil)
    }

    /// `premiumCheckoutSucceeded()` logs the error, still syncs, and still publishes `.pending`
    /// when marking the upgrade pending throws and the sync doesn't land Premium. The result
    /// doesn't depend on the pending flag, so a failed write can't leave the waiting overlay
    /// without a result.
    @Test
    func premiumCheckoutSucceeded_withWriteError_logsErrorAndPublishesPending() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        billingStateService.setPremiumUpgradePendingClosure = { _, _ in
            throw BitwardenTestError.example
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumCheckoutSucceeded()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(errorReporter.errors.first as? BitwardenTestError == .example)
        #expect(syncService.didFetchSync)
    }

    /// `premiumCheckoutSucceeded()` still publishes `.confirmed` when marking the upgrade pending
    /// throws but the sync lands personal Premium — a failed write shouldn't strand a checkout
    /// the user already paid for.
    @Test
    func premiumCheckoutSucceeded_withWriteError_premiumLanded_publishesConfirmed() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        billingStateService.setPremiumUpgradePendingClosure = { _, _ in
            throw BitwardenTestError.example
        }
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
        #expect(errorReporter.errors.first as? BitwardenTestError == .example)
    }

    // MARK: retryPendingUpgrade

    /// `retryPendingUpgrade()` force-syncs and publishes `.confirmed` when its sync finds the
    /// purchased Premium — the "Sync Now" retry succeeding on a real upgrade. It only reads:
    /// clearing the flag and revealing the card belong to `completeUpgradeIfPending(userId:)`.
    @Test
    func retryPendingUpgrade_confirmed() async throws {
        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncHandler = {
            stateService.setPersonalPremium(true, userId: "1")
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.retryPendingUpgrade()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
        #expect(syncService.fetchSyncForceSync == true)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == nil)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `retryPendingUpgrade()` does nothing when the premiumUpgradePath feature flag is disabled.
    @Test
    func retryPendingUpgrade_featureFlagDisabled_doesNothing() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false

        await subject.retryPendingUpgrade()

        #expect(!syncService.didFetchSync)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == nil)
    }

    /// `retryPendingUpgrade()` logs the error and publishes `.pending` without syncing when the
    /// active account can't be resolved, so the user gets the pending alert again rather than
    /// nothing.
    @Test
    func retryPendingUpgrade_noActiveAccount_logsErrorAndPublishesPending() async throws {
        stateService.activeAccount = nil
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.retryPendingUpgrade()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(errorReporter.errors.last as? StateServiceError == .noActiveAccount)
        #expect(!syncService.didFetchSync)
    }

    /// `retryPendingUpgrade()` leaves a genuinely pending upgrade pending and publishes `.pending`
    /// when its sync still doesn't find Premium.
    @Test
    func retryPendingUpgrade_pending() async throws {
        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.setPersonalPremium(false, userId: "1")
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.retryPendingUpgrade()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
    }

    /// `retryPendingUpgrade()` logs the error and publishes `.pending` when the forced sync throws.
    @Test
    func retryPendingUpgrade_syncError() async throws {
        premiumUpgradeStorage.pendingByUserId["1"] = true
        stateService.setPersonalPremium(false, userId: "1")
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.retryPendingUpgrade()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(errorReporter.errors.first is URLError)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == true)
    }

    /// `retryPendingUpgrade()` never marks an upgrade pending, so a "Sync Now" tap that doesn't
    /// follow a real checkout can't latch the account into a pending state it can never leave.
    @Test
    func retryPendingUpgrade_withNoPendingUpgrade_doesNotMarkPending() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.retryPendingUpgrade()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(syncService.didFetchSync)
        #expect(premiumUpgradeStorage.pendingByUserId["1"] == nil)
        #expect(premiumUpgradeStorage.upgradedToPremiumCardVisibleByUserId["1"] == nil)
    }
}
