// swiftlint:disable:this file_name

import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingServiceOutOfBandUpgradeTests

/// Tests for the `BillingService` method that detects a Premium upgrade made outside the app.
///
@MainActor
struct BillingServiceOutOfBandUpgradeTests {
    // MARK: Types

    /// A single row of the `detectOutOfBandUpgrade(userId:)` transition table: the recorded and
    /// current Premium values, and what detection should write.
    struct TransitionTestCase: Sendable {
        /// Whether the "Upgraded to Premium" action card should be revealed.
        let expectedCard: Bool

        /// The personal Premium value that should be recorded, or `nil` if nothing should be written.
        let expectedSaved: Bool?

        /// Whether the account has Premium granted by an organization.
        let organizationPremium: Bool

        /// Whether the account has Premium it purchased itself.
        let personalPremium: Bool

        /// The personal Premium value recorded by the previous sync, or `nil` if none was recorded.
        let previous: Bool?
    }

    // MARK: Properties

    let billingStateService: MockBillingStateService
    let configService: MockConfigService
    let errorReporter: MockErrorReporter
    let stateService: MockStateService
    let subject: DefaultBillingService

    // MARK: Initialization

    init() {
        billingStateService = MockBillingStateService()
        configService = MockConfigService()
        configService.featureFlagsBool[.premiumUpgradePath] = true
        let environmentService = MockEnvironmentService()
        environmentService.region = .unitedStates
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        stateService.activeAccount = .fixture()
        subject = DefaultBillingService(
            billingAPIService: MockBillingAPIService(),
            billingStateService: billingStateService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            stateService: stateService,
            syncService: MockSyncService(),
        )
    }

    // MARK: Tests

    /// `detectOutOfBandUpgrade(userId:)` records changes to the given account's personal Premium and
    /// reveals the card only when it goes from `false` to `true`.
    @Test(arguments: [
        TransitionTestCase(
            expectedCard: false,
            expectedSaved: false,
            organizationPremium: false,
            personalPremium: false,
            previous: nil,
        ),
        TransitionTestCase(
            expectedCard: false,
            expectedSaved: true,
            organizationPremium: false,
            personalPremium: true,
            previous: nil,
        ),
        TransitionTestCase(
            expectedCard: false,
            expectedSaved: nil,
            organizationPremium: false,
            personalPremium: false,
            previous: false,
        ),
        TransitionTestCase(
            expectedCard: false,
            expectedSaved: nil,
            organizationPremium: true,
            personalPremium: false,
            previous: false,
        ),
        // The grant.
        TransitionTestCase(
            expectedCard: true,
            expectedSaved: true,
            organizationPremium: false,
            personalPremium: true,
            previous: false,
        ),
        // A lapse.
        TransitionTestCase(
            expectedCard: false,
            expectedSaved: false,
            organizationPremium: false,
            personalPremium: false,
            previous: true,
        ),
        // A renewal.
        TransitionTestCase(
            expectedCard: false,
            expectedSaved: nil,
            organizationPremium: false,
            personalPremium: true,
            previous: true,
        ),
    ])
    func detectOutOfBandUpgrade_transitions(testCase: TransitionTestCase) async {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        billingStateService.getPreviousPersonalPremiumReturnValue = testCase.previous
        stateService.doesAccountHavePremiumPersonallyByUserId["1"] = testCase.personalPremium
        stateService.doesAccountHavePremiumByUserId["1"] = testCase.personalPremium || testCase.organizationPremium
        stateService.setPersonalPremium(!testCase.personalPremium, userId: "2")

        await subject.detectOutOfBandUpgrade(userId: "1")

        let saved = billingStateService.setPreviousPersonalPremiumReceivedArguments
        let card = billingStateService.setUpgradedToPremiumActionCardVisibleReceivedArguments
        #expect(billingStateService.getPreviousPersonalPremiumReceivedUserId == "1")
        #expect(saved?.previousPersonalPremium == testCase.expectedSaved)
        #expect(saved?.userId == (testCase.expectedSaved == nil ? nil : "1"))
        #expect(card?.visible == (testCase.expectedCard ? true : nil))
        #expect(card?.userId == (testCase.expectedCard ? "1" : nil))
    }

    /// `detectOutOfBandUpgrade(userId:)` records the grant and logs the error when revealing the card throws.
    @Test
    func detectOutOfBandUpgrade_withCardWriteError_logsError() async {
        billingStateService.getPreviousPersonalPremiumReturnValue = false
        billingStateService.setUpgradedToPremiumActionCardVisibleThrowableError = BitwardenTestError.example
        stateService.setPersonalPremium(true, userId: "1")

        await subject.detectOutOfBandUpgrade(userId: "1")

        #expect(billingStateService.setPreviousPersonalPremiumReceivedArguments?.previousPersonalPremium == true)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `detectOutOfBandUpgrade(userId:)` records a grant without revealing the card when the account
    /// isn't eligible for the Premium upgrade path.
    @Test
    func detectOutOfBandUpgrade_withGrant_ineligible_recordsWithoutCard() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false
        billingStateService.getPreviousPersonalPremiumReturnValue = false
        stateService.setPersonalPremium(true, userId: "1")

        await subject.detectOutOfBandUpgrade(userId: "1")

        #expect(billingStateService.setPreviousPersonalPremiumReceivedArguments?.previousPersonalPremium == true)
        #expect(!billingStateService.setUpgradedToPremiumActionCardVisibleCalled)
    }

    /// `detectOutOfBandUpgrade(userId:)` logs the error and writes nothing when reading the recorded
    /// value throws.
    @Test
    func detectOutOfBandUpgrade_withReadError_logsError() async {
        billingStateService.getPreviousPersonalPremiumThrowableError = BitwardenTestError.example
        stateService.setPersonalPremium(true, userId: "1")

        await subject.detectOutOfBandUpgrade(userId: "1")

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(!billingStateService.setPreviousPersonalPremiumCalled)
        #expect(!billingStateService.setUpgradedToPremiumActionCardVisibleCalled)
    }

    /// `detectOutOfBandUpgrade(userId:)` logs the error and doesn't reveal the card when recording
    /// the grant throws.
    @Test
    func detectOutOfBandUpgrade_withSaveError_logsErrorWithoutCard() async {
        billingStateService.getPreviousPersonalPremiumReturnValue = false
        billingStateService.setPreviousPersonalPremiumThrowableError = BitwardenTestError.example
        stateService.setPersonalPremium(true, userId: "1")

        await subject.detectOutOfBandUpgrade(userId: "1")

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(!billingStateService.setUpgradedToPremiumActionCardVisibleCalled)
    }
}
