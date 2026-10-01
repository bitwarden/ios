// swiftlint:disable:this file_name

import BitwardenKitMocks
import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// swiftlint:disable file_length

extension MockStateService {
    /// Sets both the personal and inclusive Premium accessors, so a simulated purchase can't leave
    /// the mock with personal Premium but no Premium.
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

// MARK: - BillingServicePremiumUpgradePendingTests

/// Tests for the `BillingService` methods that track whether a Premium upgrade is pending.
///
@MainActor
struct BillingServicePremiumUpgradePendingTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let billingAPIService: MockBillingAPIService
    let billingStateService: MockBillingStateService
    let configService: MockConfigService
    let environmentService: MockEnvironmentService
    let errorReporter: MockErrorReporter
    let stateService: MockStateService
    let syncService: MockSyncService
    let subject: DefaultBillingService

    // MARK: Initialization

    init() {
        billingAPIService = MockBillingAPIService()
        billingAPIService.getSubscriptionReturnValue = .fixture()
        billingStateService = MockBillingStateService()
        billingStateService.getPremiumUpgradePendingReturnValue = false
        configService = MockConfigService()
        configService.featureFlagsBool[.premiumUpgradePath] = true
        environmentService = MockEnvironmentService()
        environmentService.region = .unitedStates
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        stateService.activeAccount = .fixture()
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

    /// `completeUpgradeIfPending(userId:)` clears the pending flag for the account named by its
    /// parameter, not whichever account happens to be active — the sync it follows belongs to
    /// that account.
    @Test
    func completeUpgradeIfPending_completesGivenAccountNotActiveAccount() async {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        billingStateService.getPremiumUpgradePendingReturnValue = true
        stateService.setPersonalPremium(true, userId: "1")

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(billingStateService.getPremiumUpgradePendingReceivedUserId == "1")
        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.pending == false)
        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.userId == "1")
        #expect(billingStateService.setUpgradedToPremiumActionCardVisibleReceivedArguments?.visible == true)
        #expect(billingStateService.setUpgradedToPremiumActionCardVisibleReceivedArguments?.userId == "1")
    }

    /// `completeUpgradeIfPending(userId:)` clears the pending flag once the purchased Premium has
    /// arrived — the sync that finally reports it may be any later sync, not the checkout's own.
    @Test
    func completeUpgradeIfPending_completesPendingUpgradeOnDelayedSync() async {
        billingStateService.getPremiumUpgradePendingReturnValue = true
        stateService.setPersonalPremium(false, userId: "1")

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(!billingStateService.setPremiumUpgradePendingCalled)
        #expect(!billingStateService.setUpgradedToPremiumActionCardVisibleCalled)

        stateService.setPersonalPremium(true, userId: "1")

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.pending == false)
        #expect(billingStateService.setUpgradedToPremiumActionCardVisibleReceivedArguments?.visible == true)
    }

    /// `completeUpgradeIfPending(userId:)` writes nothing for an account with no pending upgrade,
    /// so a routine sync for a long-since-Premium or free account never touches the flag.
    @Test
    func completeUpgradeIfPending_withNoPendingUpgrade_doesNothing() async {
        stateService.setPersonalPremium(true, userId: "1")

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(!billingStateService.setPremiumUpgradePendingCalled)
        #expect(!billingStateService.setUpgradedToPremiumActionCardVisibleCalled)
    }

    /// `completeUpgradeIfPending(userId:)` doesn't treat organization-granted Premium as the
    /// personal purchase landing: the flag is only ever set by a personal checkout, so an
    /// organization grant arriving mid-flight must leave the upgrade pending.
    @Test
    func completeUpgradeIfPending_withOrganizationPremiumOnly_staysPending() async {
        billingStateService.getPremiumUpgradePendingReturnValue = true
        stateService.doesAccountHavePremiumPersonallyByUserId["1"] = false
        stateService.doesAccountHavePremiumByUserId["1"] = true

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(!billingStateService.setPremiumUpgradePendingCalled)
        #expect(!billingStateService.setUpgradedToPremiumActionCardVisibleCalled)
    }

    /// `completeUpgradeIfPending(userId:)` logs the error and writes nothing when reading the
    /// pending flag throws.
    @Test
    func completeUpgradeIfPending_withReadError_logsError() async {
        billingStateService.getPremiumUpgradePendingThrowableError = BitwardenTestError.example

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(!billingStateService.setPremiumUpgradePendingCalled)
    }

    /// `completeUpgradeIfPending(userId:)` logs the error and doesn't reveal the card when clearing
    /// the pending flag throws.
    @Test
    func completeUpgradeIfPending_withWriteError_logsError() async {
        billingStateService.getPremiumUpgradePendingReturnValue = true
        billingStateService.setPremiumUpgradePendingThrowableError = BitwardenTestError.example
        stateService.setPersonalPremium(true, userId: "1")

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(!billingStateService.setUpgradedToPremiumActionCardVisibleCalled)
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
        #expect(billingStateService.setPremiumUpgradePendingCallsCount == 1)
        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.pending == true)
        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.userId == "1")
    }

    /// `premiumCheckoutSucceeded()` marks the upgrade pending, force-syncs, and publishes
    /// `.confirmed` when the sync lands personal Premium, leaving the flag and cards to the sync's
    /// completion handling.
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
        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.pending == true)
        #expect(!billingStateService.setUpgradedToPremiumActionCardVisibleCalled)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `premiumCheckoutSucceeded()` does nothing when the premiumUpgradePath feature flag is disabled.
    @Test
    func premiumCheckoutSucceeded_featureFlagDisabled_doesNothing() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false

        await subject.premiumCheckoutSucceeded()

        #expect(!syncService.didFetchSync)
        #expect(!billingStateService.setPremiumUpgradePendingCalled)
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
        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.pending == true)
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
        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.pending == true)
    }

    /// `premiumCheckoutSucceeded()` does nothing when the environment is self-hosted.
    @Test
    func premiumCheckoutSucceeded_selfHosted_doesNothing() async {
        environmentService.region = .selfHosted

        await subject.premiumCheckoutSucceeded()

        #expect(!syncService.didFetchSync)
        #expect(!billingStateService.setPremiumUpgradePendingCalled)
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
        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.pending == true)
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
        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.pending == true)
        #expect(!billingStateService.setUpgradedToPremiumActionCardVisibleCalled)
    }

    /// `premiumCheckoutSucceeded()` logs the error, still syncs, and still publishes `.pending`
    /// when marking the upgrade pending throws and the sync doesn't land Premium.
    @Test
    func premiumCheckoutSucceeded_withWriteError_logsErrorAndPublishesPending() async throws {
        stateService.setPersonalPremium(false, userId: "1")
        billingStateService.setPremiumUpgradePendingThrowableError = BitwardenTestError.example
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
        billingStateService.setPremiumUpgradePendingThrowableError = BitwardenTestError.example
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
    /// purchased Premium — the "Sync Now" retry succeeding on a real upgrade — leaving the flag
    /// and cards to the sync's completion handling.
    @Test
    func retryPendingUpgrade_confirmed() async throws {
        billingStateService.getPremiumUpgradePendingReturnValue = true
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
        #expect(!billingStateService.setPremiumUpgradePendingCalled)
        #expect(!billingStateService.setUpgradedToPremiumActionCardVisibleCalled)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `retryPendingUpgrade()` does nothing when the premiumUpgradePath feature flag is disabled.
    @Test
    func retryPendingUpgrade_featureFlagDisabled_doesNothing() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false

        await subject.retryPendingUpgrade()

        #expect(!syncService.didFetchSync)
        #expect(!billingStateService.setPremiumUpgradePendingCalled)
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
        billingStateService.getPremiumUpgradePendingReturnValue = true
        stateService.setPersonalPremium(false, userId: "1")
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.retryPendingUpgrade()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(!billingStateService.setPremiumUpgradePendingCalled)
    }

    /// `retryPendingUpgrade()` logs the error and publishes `.pending` when the forced sync throws.
    @Test
    func retryPendingUpgrade_syncError() async throws {
        billingStateService.getPremiumUpgradePendingReturnValue = true
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
        #expect(!billingStateService.setPremiumUpgradePendingCalled)
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
        #expect(!billingStateService.setPremiumUpgradePendingCalled)
        #expect(!billingStateService.setUpgradedToPremiumActionCardVisibleCalled)
    }
}
