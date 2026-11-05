// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SettingsProcessorBillingTests

@MainActor
struct SettingsProcessorBillingTests {
    // MARK: Properties

    let billingService: MockBillingService
    let configService: MockConfigService
    let coordinator: MockCoordinator<SettingsRoute, SettingsEvent>
    let delegate: MockSettingsProcessorDelegate
    let stateService: MockStateService
    let storefrontService: MockStorefrontService
    let subject: SettingsProcessor
    let vaultRepository: MockVaultRepository

    // MARK: Initialization

    init() {
        billingService = MockBillingService()
        billingService.isSelfHostedReturnValue = false
        billingService.shouldShowUpgradedToPremiumActionCardReturnValue = false
        configService = MockConfigService()
        coordinator = MockCoordinator()
        delegate = MockSettingsProcessorDelegate()
        stateService = MockStateService()
        storefrontService = MockStorefrontService()
        storefrontService.isUSStorefrontReturnValue = true
        vaultRepository = MockVaultRepository()
        subject = SettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                billingService: billingService,
                configService: configService,
                stateService: stateService,
                storefrontService: storefrontService,
                vaultRepository: vaultRepository,
            ),
            state: SettingsState(presentationMode: .tab),
        )
    }

    // MARK: Tests - perform(.appeared) — plan row

    /// `perform(_:)` with `.appeared` sets `showPlanRow` across the combinations of the feature
    /// flag, self-hosting, storefront, Premium ownership, and whether the user has a Stripe
    /// subscription.
    @Test(arguments: [
        PlanRowTestCase(
            expectedShowPlanRow: false,
            featureEnabled: false,
            hasPersonalSubscription: nil,
            hasPremium: false,
            hasPremiumPersonally: false,
            isSelfHosted: false,
            isUSStorefront: true,
        ),
        PlanRowTestCase(
            expectedShowPlanRow: false,
            featureEnabled: true,
            hasPersonalSubscription: nil,
            hasPremium: false,
            hasPremiumPersonally: false,
            isSelfHosted: true,
            isUSStorefront: true,
        ),
        PlanRowTestCase(
            expectedShowPlanRow: false,
            featureEnabled: true,
            hasPersonalSubscription: nil,
            hasPremium: false,
            hasPremiumPersonally: false,
            isSelfHosted: false,
            isUSStorefront: false,
        ),
        PlanRowTestCase(
            expectedShowPlanRow: true,
            featureEnabled: true,
            hasPersonalSubscription: nil,
            hasPremium: false,
            hasPremiumPersonally: false,
            isSelfHosted: false,
            isUSStorefront: true,
        ),
        PlanRowTestCase(
            expectedShowPlanRow: true,
            featureEnabled: true,
            hasPersonalSubscription: true,
            hasPremium: false,
            hasPremiumPersonally: false,
            isSelfHosted: false,
            isUSStorefront: true,
        ),
        PlanRowTestCase(
            expectedShowPlanRow: true,
            featureEnabled: true,
            hasPersonalSubscription: false,
            hasPremium: false,
            hasPremiumPersonally: false,
            isSelfHosted: false,
            isUSStorefront: true,
        ),
        PlanRowTestCase(
            expectedShowPlanRow: false,
            featureEnabled: true,
            hasPersonalSubscription: nil,
            hasPremium: true,
            hasPremiumPersonally: false,
            isSelfHosted: false,
            isUSStorefront: true,
        ),
        PlanRowTestCase(
            expectedShowPlanRow: false,
            featureEnabled: true,
            hasPersonalSubscription: true,
            hasPremium: true,
            hasPremiumPersonally: false,
            isSelfHosted: false,
            isUSStorefront: true,
        ),
        PlanRowTestCase(
            expectedShowPlanRow: false,
            featureEnabled: true,
            hasPersonalSubscription: false,
            hasPremium: true,
            hasPremiumPersonally: false,
            isSelfHosted: false,
            isUSStorefront: true,
        ),
        PlanRowTestCase(
            expectedShowPlanRow: true,
            featureEnabled: true,
            hasPersonalSubscription: nil,
            hasPremium: true,
            hasPremiumPersonally: true,
            isSelfHosted: false,
            isUSStorefront: true,
        ),
        PlanRowTestCase(
            expectedShowPlanRow: true,
            featureEnabled: true,
            hasPersonalSubscription: true,
            hasPremium: true,
            hasPremiumPersonally: true,
            isSelfHosted: false,
            isUSStorefront: true,
        ),
        PlanRowTestCase(
            expectedShowPlanRow: false,
            featureEnabled: true,
            hasPersonalSubscription: false,
            hasPremium: true,
            hasPremiumPersonally: true,
            isSelfHosted: false,
            isUSStorefront: true,
        ),
    ])
    func perform_appeared_planRow(testCase: PlanRowTestCase) async {
        billingService.hasPersonalSubscriptionReturnValue = testCase.hasPersonalSubscription
        billingService.isSelfHostedReturnValue = testCase.isSelfHosted
        configService.featureFlagsBool[.premiumUpgradePath] = testCase.featureEnabled
        stateService.doesActiveAccountHavePremiumPersonallyResult = testCase.hasPremiumPersonally
        storefrontService.isUSStorefrontReturnValue = testCase.isUSStorefront
        vaultRepository.doesActiveAccountHavePremiumResult = testCase.hasPremium

        await subject.perform(.appeared)

        #expect(subject.state.hasPremium == testCase.hasPremium)
        #expect(subject.state.showPlanRow == testCase.expectedShowPlanRow)
    }
}

// MARK: - PlanRowTestCase

/// Input/output data for the `perform_appeared_planRow` parameterized test.
struct PlanRowTestCase: Sendable {
    let expectedShowPlanRow: Bool
    let featureEnabled: Bool
    let hasPersonalSubscription: Bool?
    let hasPremium: Bool
    let hasPremiumPersonally: Bool
    let isSelfHosted: Bool
    let isUSStorefront: Bool
}
