// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
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
    let errorReporter: MockErrorReporter
    let premiumUpgradeHelper: MockPremiumUpgradeHelper
    let stateService: MockStateService
    let storefrontService: MockStorefrontService
    let subject: SettingsProcessor
    let vaultRepository: MockVaultRepository

    // MARK: Initialization

    init() {
        billingService = MockBillingService()
        billingService.isPlanBadgeDismissedReturnValue = false
        billingService.isSelfHostedReturnValue = false
        billingService.shouldShowUpgradedToPremiumActionCardReturnValue = false
        configService = MockConfigService()
        coordinator = MockCoordinator()
        delegate = MockSettingsProcessorDelegate()
        errorReporter = MockErrorReporter()
        premiumUpgradeHelper = MockPremiumUpgradeHelper()
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
                errorReporter: errorReporter,
                stateService: stateService,
                storefrontService: storefrontService,
                vaultRepository: vaultRepository,
            ),
            state: SettingsState(presentationMode: .tab),
        )
        subject.premiumUpgradeHelper = premiumUpgradeHelper
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

    // MARK: Tests - perform(.appeared) — upgraded to Premium action card

    /// `perform(_:)` with `.appeared` sets `shouldShowUpgradedToPremiumActionCard` to the value
    /// returned by the billing service.
    @Test(arguments: [true, false])
    func perform_appeared_showUpgradedToPremiumActionCard(shouldShow: Bool) async {
        billingService.shouldShowUpgradedToPremiumActionCardReturnValue = shouldShow

        await subject.perform(.appeared)

        #expect(subject.state.shouldShowUpgradedToPremiumActionCard == shouldShow)
    }

    // MARK: Tests - perform(.dismissUpgradedToPremiumActionCard)

    /// `perform(_:)` with `.dismissUpgradedToPremiumActionCard` hides the card and persists the
    /// dismissal.
    @Test
    func perform_dismissUpgradedToPremiumActionCard() async {
        subject.state.shouldShowUpgradedToPremiumActionCard = true

        await subject.perform(.dismissUpgradedToPremiumActionCard)

        #expect(!subject.state.shouldShowUpgradedToPremiumActionCard)
        #expect(billingService.setUpgradedToPremiumActionCardDismissedCallsCount == 1)
    }

    // MARK: Tests - perform(.planPressed)

    /// `perform(_:)` with `.planPressed` starts the in-app Premium upgrade with a loading overlay
    /// when the subscription fetch returns a 404.
    @Test
    func perform_planPressed_freeUser_noSubscription() async {
        subject.state.hasPremium = false
        billingService.getSubscriptionThrowableError = GetSubscriptionRequestError.noSubscription

        await subject.perform(.planPressed)

        #expect(premiumUpgradeHelper.startInAppPremiumUpgradeCalled)
        #expect(coordinator.loadingOverlaysShown == [LoadingOverlayState(title: Localizations.loading)])
        #expect(!errorReporter.errors.contains { $0 is GetSubscriptionRequestError })
    }

    /// `perform(_:)` with `.planPressed` shows an error alert with a loading overlay and reports
    /// the error when the subscription fetch fails with a non-404 error.
    @Test
    func perform_planPressed_freeUser_subscriptionFetchError() async {
        subject.state.hasPremium = false
        billingService.getSubscriptionThrowableError = BitwardenTestError.example

        await subject.perform(.planPressed)

        #expect(coordinator.errorAlertsShown.count == 1)
        #expect(coordinator.loadingOverlaysShown == [LoadingOverlayState(title: Localizations.loading)])
        #expect(errorReporter.errors.contains { $0 as? BitwardenTestError == .example })
    }

    /// `perform(_:)` with `.planPressed` navigates to the Premium plan screen without a loading
    /// overlay when the user has Premium.
    @Test
    func perform_planPressed_hasPremium() async {
        subject.state.hasPremium = true

        await subject.perform(.planPressed)

        #expect(coordinator.routes.last == .premiumPlan(nil))
        #expect(coordinator.loadingOverlaysShown.isEmpty)
    }

    /// `perform(_:)` with `.planPressed` starts the in-app Premium upgrade with a loading overlay
    /// when the subscription status is not a trouble state.
    @Test(arguments: [PremiumPlanStatus.active, .unknown])
    func perform_planPressed_nonTroubleStatus(status: PremiumPlanStatus) async {
        subject.state.hasPremium = false
        billingService.getSubscriptionReturnValue = .fixture(status: status)

        await subject.perform(.planPressed)

        #expect(premiumUpgradeHelper.startInAppPremiumUpgradeCalled)
        #expect(coordinator.loadingOverlaysShown == [LoadingOverlayState(title: Localizations.loading)])
    }

    /// `perform(_:)` with `.planPressed` navigates to the Premium plan screen with a loading
    /// overlay when the subscription status is a trouble state.
    @Test(arguments: [
        PremiumPlanStatus.canceled,
        .expired,
        .pastDue,
        .pendingCancellation,
        .unpaid,
        .updatePayment,
    ])
    func perform_planPressed_troubleStatus(status: PremiumPlanStatus) async {
        subject.state.hasPremium = false
        let subscription = PremiumSubscription.fixture(status: status)
        billingService.getSubscriptionReturnValue = subscription

        await subject.perform(.planPressed)

        #expect(coordinator.routes.last == .premiumPlan(subscription))
        #expect(coordinator.loadingOverlaysShown == [LoadingOverlayState(title: Localizations.loading)])
    }

    // MARK: Tests - receive(.learnMoreAboutPremium)

    /// `receive(_:)` with `.learnMoreAboutPremium` sets the learn more URL, hides the card, and
    /// persists the dismissal.
    @Test
    func receive_learnMoreAboutPremium() async throws {
        subject.state.shouldShowUpgradedToPremiumActionCard = true

        subject.receive(.learnMoreAboutPremium)

        #expect(subject.state.url == ExternalLinksConstants.learnMoreAboutPremium)
        #expect(!subject.state.shouldShowUpgradedToPremiumActionCard)
        try await waitForAsync { billingService.setUpgradedToPremiumActionCardDismissedCallsCount == 1 }
        #expect(billingService.setUpgradedToPremiumActionCardDismissedCallsCount == 1)
    }
}

// MARK: - SettingsProcessorBillingTests + Plan Badge

@MainActor
extension SettingsProcessorBillingTests {
    // MARK: Tests - perform(.appeared) — plan badge

    /// `perform(_:)` with `.appeared` sets `showPlanBadge` across the combinations of the Plan row
    /// visibility, Premium ownership, personal subscription, and badge dismissal.
    @Test(arguments: [
        PlanBadgeTestCase(
            expectedShowPlanBadge: true,
            hasPersonalSubscription: nil,
            hasPremium: false,
            isDismissed: false,
            isRowShown: true,
        ),
        PlanBadgeTestCase(
            expectedShowPlanBadge: true,
            hasPersonalSubscription: false,
            hasPremium: false,
            isDismissed: false,
            isRowShown: true,
        ),
        PlanBadgeTestCase(
            expectedShowPlanBadge: false,
            hasPersonalSubscription: true,
            hasPremium: false,
            isDismissed: false,
            isRowShown: true,
        ),
        PlanBadgeTestCase(
            expectedShowPlanBadge: false,
            hasPersonalSubscription: nil,
            hasPremium: true,
            isDismissed: false,
            isRowShown: true,
        ),
        PlanBadgeTestCase(
            expectedShowPlanBadge: false,
            hasPersonalSubscription: nil,
            hasPremium: false,
            isDismissed: true,
            isRowShown: true,
        ),
        PlanBadgeTestCase(
            expectedShowPlanBadge: false,
            hasPersonalSubscription: nil,
            hasPremium: false,
            isDismissed: false,
            isRowShown: false,
        ),
    ])
    func perform_appeared_planBadge(testCase: PlanBadgeTestCase) async {
        billingService.hasPersonalSubscriptionReturnValue = testCase.hasPersonalSubscription
        billingService.isPlanBadgeDismissedReturnValue = testCase.isDismissed
        configService.featureFlagsBool[.premiumUpgradePath] = testCase.isRowShown
        stateService.doesActiveAccountHavePremiumPersonallyResult = testCase.hasPremium
        vaultRepository.doesActiveAccountHavePremiumResult = testCase.hasPremium

        await subject.perform(.appeared)

        #expect(subject.state.showPlanRow == testCase.isRowShown)
        #expect(subject.state.showPlanBadge == testCase.expectedShowPlanBadge)
    }
}

// MARK: - PlanBadgeTestCase

/// Input/output data for the `perform_appeared_planBadge` parameterized test.
struct PlanBadgeTestCase: Sendable {
    let expectedShowPlanBadge: Bool
    let hasPersonalSubscription: Bool?
    let hasPremium: Bool
    let isDismissed: Bool
    let isRowShown: Bool
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
