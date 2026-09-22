// swiftlint:disable:this file_name

import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingServicePremiumUpgradeLifecycleStateTests

/// Tests for `BillingService.premiumUpgradeLifecycleState()`, which derives an account's position in the
/// Premium upgrade lifecycle from its personal Premium status, its persisted pending flag, and
/// its organization-granted Premium.
///
@MainActor
struct BillingServicePremiumUpgradeLifecycleStateTests {
    // MARK: Properties

    var billingAPIService: MockBillingAPIService!
    var billingStateService: MockBillingStateService!
    var configService: MockConfigService!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var premiumUpgradeStorage: PremiumUpgradeStateStore!
    var stateService: MockStateService!
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
        subject = DefaultBillingService(
            billingAPIService: billingAPIService,
            billingStateService: billingStateService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            stateService: stateService,
            syncService: MockSyncService(),
            debounceInterval: .milliseconds(100),
        )
    }

    /// `premiumUpgradeLifecycleState()` derives the active account's lifecycle position from its personal
    /// Premium status, its persisted pending flag, and its organization-granted Premium — in
    /// that order of precedence.
    @Test(arguments: [
        PremiumUpgradeLifecycleStateTestCase(
            personalPremium: false,
            pending: false,
            organizationPremium: false,
            expected: .notPremium,
        ),
        PremiumUpgradeLifecycleStateTestCase(
            personalPremium: false,
            pending: false,
            organizationPremium: true,
            expected: .premium,
        ),
        PremiumUpgradeLifecycleStateTestCase(
            personalPremium: false,
            pending: true,
            organizationPremium: false,
            expected: .pending,
        ),
        // An organization grant arriving mid-flight is not the personal purchase landing.
        PremiumUpgradeLifecycleStateTestCase(
            personalPremium: false,
            pending: true,
            organizationPremium: true,
            expected: .pending,
        ),
        PremiumUpgradeLifecycleStateTestCase(
            personalPremium: true,
            pending: false,
            organizationPremium: false,
            expected: .premium,
        ),
        // A pending flag not yet cleared must not mask Premium that has actually been granted.
        PremiumUpgradeLifecycleStateTestCase(
            personalPremium: true,
            pending: true,
            organizationPremium: true,
            expected: .premium,
        ),
    ])
    func premiumUpgradeLifecycleState_derivation(testCase: PremiumUpgradeLifecycleStateTestCase) async {
        // The active-account results, not the by-userId dictionaries: the accessor under test
        // passes `userId: nil`, and `MockStateService`'s Premium accessors short-circuit to these
        // before consulting the dictionaries. Both default to `true`, so leaving either unset
        // reports Premium regardless of the test case.
        stateService.doesActiveAccountHavePremiumPersonallyResult = testCase.personalPremium
        stateService.doesActiveAccountHavePremiumResult = testCase.personalPremium
            || testCase.organizationPremium
        premiumUpgradeStorage.pendingByUserId["1"] = testCase.pending

        let result = await subject.premiumUpgradeLifecycleState()

        #expect(result == testCase.expected)
    }

    /// `premiumUpgradeLifecycleState()` reports `.notPremium` and logs the error when the state service
    /// can't resolve the active account.
    @Test
    func premiumUpgradeLifecycleState_error() async {
        stateService.activeAccount = nil
        stateService.doesActiveAccountHavePremiumPersonallyResult = false
        stateService.doesActiveAccountHavePremiumResult = false

        let result = await subject.premiumUpgradeLifecycleState()

        #expect(result == .notPremium)
        #expect(errorReporter.errors.first as? StateServiceError == .noActiveAccount)
    }

    /// `premiumUpgradeLifecycleState()` still reports `.premium` for an organization-granted account when
    /// the pending flag can't be read — a failed flag read must not strip Premium the account
    /// demonstrably has.
    @Test
    func premiumUpgradeLifecycleState_pendingReadError_organizationPremium() async {
        stateService.doesActiveAccountHavePremiumPersonallyResult = false
        stateService.doesActiveAccountHavePremiumResult = true
        billingStateService.getPremiumUpgradePendingClosure = { _ in throw BitwardenTestError.example }

        let result = await subject.premiumUpgradeLifecycleState()

        #expect(result == .premium)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }
}

// MARK: - PremiumUpgradeLifecycleStateTestCase

/// A single row of the `premiumUpgradeLifecycleState()` derivation table: the three inputs the state is
/// derived from, and the lifecycle position they should produce.
struct PremiumUpgradeLifecycleStateTestCase: Sendable {
    /// Whether the account has Premium it purchased itself.
    let personalPremium: Bool

    /// Whether a personal checkout is recorded as awaiting confirmation.
    let pending: Bool

    /// Whether the account has Premium granted by an organization.
    let organizationPremium: Bool

    /// The `PremiumUpgradeLifecycleState` the three inputs above should derive to.
    let expected: PremiumUpgradeLifecycleState
}
