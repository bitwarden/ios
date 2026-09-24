// swiftlint:disable:this file_name

import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingServicePremiumUpgradeLifecycleStateTests

/// Tests for `BillingService.premiumUpgradeLifecycleState(userId:)`, which derives an account's position in the
/// Premium upgrade lifecycle from its personal Premium status, its persisted pending flag, and
/// its organization-granted Premium.
///
@MainActor
struct BillingServicePremiumUpgradeLifecycleStateTests {
    // MARK: Types

    /// A single row of the `premiumUpgradeLifecycleState()` derivation table: the three inputs
    /// the state is derived from, and the lifecycle position they should produce.
    struct DerivationTestCase: Sendable {
        /// The `PremiumUpgradeLifecycleState` the three inputs below should derive to.
        let expected: PremiumUpgradeLifecycleState

        /// Whether the account has Premium granted by an organization.
        let organizationPremium: Bool

        /// Whether a personal checkout is recorded as awaiting confirmation.
        let pending: Bool

        /// Whether the account has Premium it purchased itself.
        let personalPremium: Bool
    }

    // MARK: Properties

    let billingStateService: MockBillingStateService
    let errorReporter: MockErrorReporter
    let stateService: MockStateService
    let subject: DefaultBillingService

    // MARK: Initialization

    init() {
        billingStateService = MockBillingStateService()
        billingStateService.getPremiumUpgradePendingReturnValue = false
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        stateService.activeAccount = .fixture()
        subject = DefaultBillingService(
            billingAPIService: MockBillingAPIService(),
            billingStateService: billingStateService,
            configService: MockConfigService(),
            environmentService: MockEnvironmentService(),
            errorReporter: errorReporter,
            stateService: stateService,
            syncService: MockSyncService(),
            debounceInterval: .milliseconds(100),
        )
    }

    // MARK: Tests

    /// `premiumUpgradeLifecycleState()` derives the active account's lifecycle position from its personal
    /// Premium status, its persisted pending flag, and its organization-granted Premium — in
    /// that order of precedence.
    @Test(arguments: [
        DerivationTestCase(
            expected: .notPremium,
            organizationPremium: false,
            pending: false,
            personalPremium: false,
        ),
        DerivationTestCase(
            expected: .premium,
            organizationPremium: true,
            pending: false,
            personalPremium: false,
        ),
        DerivationTestCase(
            expected: .pending,
            organizationPremium: false,
            pending: true,
            personalPremium: false,
        ),
        // An organization grant arriving mid-flight is not the personal purchase landing.
        DerivationTestCase(
            expected: .pending,
            organizationPremium: true,
            pending: true,
            personalPremium: false,
        ),
        DerivationTestCase(
            expected: .premium,
            organizationPremium: false,
            pending: false,
            personalPremium: true,
        ),
        DerivationTestCase(
            expected: .premium,
            organizationPremium: true,
            pending: false,
            personalPremium: true,
        ),
        // A pending flag not yet cleared must not mask Premium that has actually been granted.
        DerivationTestCase(
            expected: .premium,
            organizationPremium: false,
            pending: true,
            personalPremium: true,
        ),
        DerivationTestCase(
            expected: .premium,
            organizationPremium: true,
            pending: true,
            personalPremium: true,
        ),
    ])
    func premiumUpgradeLifecycleState_derivation(testCase: DerivationTestCase) async {
        stateService.doesActiveAccountHavePremiumPersonallyResult = testCase.personalPremium
        stateService.doesActiveAccountHavePremiumResult = testCase.personalPremium
            || testCase.organizationPremium
        billingStateService.getPremiumUpgradePendingReturnValue = testCase.pending

        let result = await subject.premiumUpgradeLifecycleState()

        #expect(result == testCase.expected)
    }

    /// `premiumUpgradeLifecycleState(userId:)` derives the state of the account named by its
    /// parameter, not the active account.
    @Test
    func premiumUpgradeLifecycleState_givenUserId_derivesThatAccount() async {
        stateService.doesActiveAccountHavePremiumPersonallyResult = true
        stateService.doesActiveAccountHavePremiumResult = true
        stateService.doesAccountHavePremiumPersonallyByUserId["2"] = false
        stateService.doesAccountHavePremiumByUserId["2"] = false
        billingStateService.getPremiumUpgradePendingClosure = { userId in userId == "2" }

        let result = await subject.premiumUpgradeLifecycleState(userId: "2")

        #expect(result == .pending)
    }

    /// `premiumUpgradeLifecycleState()` reports `.notPremium` and logs the error when the pending
    /// flag can't be read for an account without Premium.
    @Test
    func premiumUpgradeLifecycleState_pendingReadError_noPremium() async {
        stateService.doesActiveAccountHavePremiumPersonallyResult = false
        stateService.doesActiveAccountHavePremiumResult = false
        billingStateService.getPremiumUpgradePendingThrowableError = BitwardenTestError.example

        let result = await subject.premiumUpgradeLifecycleState()

        #expect(result == .notPremium)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `premiumUpgradeLifecycleState()` still reports `.premium` for an organization-granted account when
    /// the pending flag can't be read — a failed flag read must not strip Premium the account
    /// demonstrably has.
    @Test
    func premiumUpgradeLifecycleState_pendingReadError_organizationPremium() async {
        stateService.doesActiveAccountHavePremiumPersonallyResult = false
        stateService.doesActiveAccountHavePremiumResult = true
        billingStateService.getPremiumUpgradePendingThrowableError = BitwardenTestError.example

        let result = await subject.premiumUpgradeLifecycleState()

        #expect(result == .premium)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }
}
