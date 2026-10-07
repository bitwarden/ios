// swiftlint:disable:this file_name

import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingServicePremiumUpgradePendingTests

/// Tests for the `BillingService` methods that track whether a Premium upgrade is pending.
///
@MainActor
struct BillingServicePremiumUpgradePendingTests {
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
    func completeUpgradeIfPending_clearsGivenAccountNotActiveAccount() async {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        billingStateService.getPremiumUpgradePendingReturnValue = true
        stateService.doesAccountHavePremiumPersonallyByUserId["1"] = true

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.pending == false)
        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.userId == "1")
    }

    /// `completeUpgradeIfPending(userId:)` clears the pending flag once the purchased Premium has
    /// arrived — the sync that finally reports it may be any later sync, not the checkout's own.
    @Test
    func completeUpgradeIfPending_pendingAndPersonalPremium_clearsFlag() async {
        billingStateService.getPremiumUpgradePendingReturnValue = true
        stateService.doesAccountHavePremiumPersonallyByUserId["1"] = true

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(billingStateService.setPremiumUpgradePendingCallsCount == 1)
        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.pending == false)
    }

    /// `completeUpgradeIfPending(userId:)` doesn't treat organization-granted Premium as the
    /// personal purchase landing: the flag is only ever set by a personal checkout, so an
    /// organization grant arriving mid-flight must leave the upgrade pending.
    @Test
    func completeUpgradeIfPending_pendingWithOrganizationPremiumOnly_leavesFlagSet() async {
        billingStateService.getPremiumUpgradePendingReturnValue = true
        stateService.doesAccountHavePremiumPersonallyByUserId["1"] = false
        stateService.doesAccountHavePremiumByUserId["1"] = true

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(!billingStateService.setPremiumUpgradePendingCalled)
    }

    /// `completeUpgradeIfPending(userId:)` leaves the upgrade pending when the purchased Premium
    /// hasn't arrived yet, so a later sync can complete it.
    @Test
    func completeUpgradeIfPending_pendingWithoutPremium_leavesFlagSet() async {
        billingStateService.getPremiumUpgradePendingReturnValue = true
        stateService.doesAccountHavePremiumPersonallyByUserId["1"] = false

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(!billingStateService.setPremiumUpgradePendingCalled)
    }

    /// `completeUpgradeIfPending(userId:)` writes nothing for an account with no pending upgrade,
    /// so a routine sync for a long-since-Premium or free account never touches the flag.
    @Test
    func completeUpgradeIfPending_withNoPendingUpgrade_doesNothing() async {
        billingStateService.getPremiumUpgradePendingReturnValue = false
        stateService.doesAccountHavePremiumPersonallyByUserId["1"] = true

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(!billingStateService.setPremiumUpgradePendingCalled)
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

    /// `completeUpgradeIfPending(userId:)` logs the error when clearing the pending flag throws.
    @Test
    func completeUpgradeIfPending_withWriteError_logsError() async {
        billingStateService.getPremiumUpgradePendingReturnValue = true
        billingStateService.setPremiumUpgradePendingThrowableError = BitwardenTestError.example
        stateService.doesAccountHavePremiumPersonallyByUserId["1"] = true

        await subject.completeUpgradeIfPending(userId: "1")

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    // MARK: premiumCheckoutSucceeded

    /// `premiumCheckoutSucceeded()` marks the upgrade pending for the active account, then
    /// reconciles the new Premium status.
    @Test
    func premiumCheckoutSucceeded_marksUpgradePending() async {
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.premiumCheckoutSucceeded()

        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.pending == true)
        #expect(billingStateService.setPremiumUpgradePendingReceivedArguments?.userId == nil)
        #expect(syncService.didFetchSync)
    }

    /// `premiumCheckoutSucceeded()` logs the error and still reconciles Premium status when
    /// marking the upgrade pending throws — a failed write shouldn't strand the checkout.
    @Test
    func premiumCheckoutSucceeded_withWriteError_logsErrorAndStillSyncs() async {
        billingStateService.setPremiumUpgradePendingThrowableError = BitwardenTestError.example
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.premiumCheckoutSucceeded()

        #expect(errorReporter.errors.first as? BitwardenTestError == .example)
        #expect(syncService.didFetchSync)
    }
}
