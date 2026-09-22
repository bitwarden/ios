// swiftlint:disable:this file_name

import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingServicePremiumUpgradeStateTests

/// Tests for `BillingService.premiumUpgradeState()`, which derives an account's position in the
/// Premium upgrade lifecycle from its personal Premium status, its persisted pending flag, and
/// its organization-granted Premium.
///
@MainActor
struct BillingServicePremiumUpgradeStateTests {
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

    /// `premiumUpgradeState()` derives the active account's lifecycle position from its personal
    /// Premium status, its persisted pending flag, and its organization-granted Premium — in
    /// that order of precedence.
    @Test(arguments: [
        PremiumUpgradeStateTestCase(
            personalPremium: false,
            pending: false,
            organizationPremium: false,
            expected: .notPremium,
        ),
        PremiumUpgradeStateTestCase(
            personalPremium: false,
            pending: false,
            organizationPremium: true,
            expected: .premium,
        ),
        PremiumUpgradeStateTestCase(
            personalPremium: false,
            pending: true,
            organizationPremium: false,
            expected: .pending,
        ),
        // An organization grant arriving mid-flight is not the personal purchase landing.
        PremiumUpgradeStateTestCase(
            personalPremium: false,
            pending: true,
            organizationPremium: true,
            expected: .pending,
        ),
        PremiumUpgradeStateTestCase(
            personalPremium: true,
            pending: false,
            organizationPremium: false,
            expected: .premium,
        ),
        // A pending flag not yet cleared must not mask Premium that has actually been granted.
        PremiumUpgradeStateTestCase(
            personalPremium: true,
            pending: true,
            organizationPremium: true,
            expected: .premium,
        ),
    ])
    func premiumUpgradeState_derivation(testCase: PremiumUpgradeStateTestCase) async {
        stateService.doesAccountHavePremiumPersonallyByUserId["1"] = testCase.personalPremium
        stateService.doesAccountHavePremiumByUserId["1"] = testCase.personalPremium
            || testCase.organizationPremium
        premiumUpgradeStorage.pendingByUserId["1"] = testCase.pending

        let result = await subject.premiumUpgradeState()

        #expect(result == testCase.expected)
    }

    /// `premiumUpgradeState()` reports `.notPremium` and logs the error when the state service
    /// can't resolve the active account.
    @Test
    func premiumUpgradeState_error() async {
        stateService.activeAccount = nil

        let result = await subject.premiumUpgradeState()

        #expect(result == .notPremium)
        #expect(errorReporter.errors.first as? StateServiceError == .noActiveAccount)
    }

    /// `premiumUpgradeState()` still reports `.premium` for an organization-granted account when
    /// the pending flag can't be read — a failed flag read must not strip Premium the account
    /// demonstrably has.
    @Test
    func premiumUpgradeState_pendingReadError_organizationPremium() async {
        stateService.doesAccountHavePremiumPersonallyByUserId["1"] = false
        stateService.doesAccountHavePremiumByUserId["1"] = true
        billingStateService.getPremiumUpgradePendingClosure = { _ in throw BitwardenTestError.example }

        let result = await subject.premiumUpgradeState()

        #expect(result == .premium)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }
}

// MARK: - PremiumUpgradeStateTestCase

/// A single row of the `premiumUpgradeState()` derivation table: the three inputs the state is
/// derived from, and the lifecycle position they should produce.
struct PremiumUpgradeStateTestCase: Sendable {
    /// Whether the account has Premium it purchased itself.
    let personalPremium: Bool

    /// Whether a personal checkout is recorded as awaiting confirmation.
    let pending: Bool

    /// Whether the account has Premium granted by an organization.
    let organizationPremium: Bool

    /// The `PremiumUpgradeState` the three inputs above should derive to.
    let expected: PremiumUpgradeState
}
