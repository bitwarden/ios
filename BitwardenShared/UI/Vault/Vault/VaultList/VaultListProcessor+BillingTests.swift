// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - VaultListProcessorBillingTests

@MainActor
struct VaultListProcessorBillingTests {
    // MARK: Properties

    let billingRepository: MockBillingRepository
    let billingService: MockBillingService
    let coordinator: MockCoordinator<VaultRoute, AuthAction>
    let premiumUpgradeHelper: MockPremiumUpgradeHelper
    let searchProcessorMediator: MockSearchProcessorMediator
    let searchProcessorMediatorFactory: MockSearchProcessorMediatorFactory
    let stateService: MockStateService
    let subject: VaultListProcessor
    let vaultRepository: MockVaultRepository

    // MARK: Initialization

    init() {
        billingRepository = MockBillingRepository()
        billingRepository.isInAppUpgradeAvailableReturnValue = false
        billingService = MockBillingService()
        billingService.shouldShowSubscriptionAttentionCardReturnValue = false
        billingService.shouldShowUpgradedToPremiumActionCardReturnValue = false
        coordinator = MockCoordinator()
        premiumUpgradeHelper = MockPremiumUpgradeHelper()
        searchProcessorMediator = MockSearchProcessorMediator()
        searchProcessorMediatorFactory = MockSearchProcessorMediatorFactory()
        searchProcessorMediatorFactory.makeReturnValue = searchProcessorMediator
        stateService = MockStateService()
        vaultRepository = MockVaultRepository()
        let services = ServiceContainer.withMocks(
            billingRepository: billingRepository,
            billingService: billingService,
            searchProcessorMediatorFactory: searchProcessorMediatorFactory,
            stateService: stateService,
            vaultRepository: vaultRepository,
        )
        subject = VaultListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            masterPasswordRepromptHelper: MockMasterPasswordRepromptHelper(),
            services: services,
            state: VaultListState(),
            vaultItemMoreOptionsHelper: MockVaultItemMoreOptionsHelper(),
        )
        subject.premiumUpgradeHelper = premiumUpgradeHelper
    }

    // MARK: Tests - perform(.appeared) — action cards

    /// `perform(_:)` with `.appeared` sets `shouldShowSubscriptionAttentionCard` and
    /// `shouldShowPremiumUpgradeActionCard` correctly across all combinations of attention card
    /// visibility, banner dismissal, and upgrade availability. The attention card takes priority —
    /// when it is visible the upgrade card is always hidden regardless of other inputs.
    @Test(arguments: [
        PremiumActionCardTestCase(
            attentionCardVisible: false,
            bannerDismissed: false,
            upgradeAvailable: false,
            expectedAttentionCard: false,
            expectedUpgradeCard: false,
        ),
        PremiumActionCardTestCase(
            attentionCardVisible: false,
            bannerDismissed: false,
            upgradeAvailable: true,
            expectedAttentionCard: false,
            expectedUpgradeCard: true,
        ),
        PremiumActionCardTestCase(
            attentionCardVisible: false,
            bannerDismissed: true,
            upgradeAvailable: false,
            expectedAttentionCard: false,
            expectedUpgradeCard: false,
        ),
        PremiumActionCardTestCase(
            attentionCardVisible: false,
            bannerDismissed: true,
            upgradeAvailable: true,
            expectedAttentionCard: false,
            expectedUpgradeCard: false,
        ),
        PremiumActionCardTestCase(
            attentionCardVisible: true,
            bannerDismissed: false,
            upgradeAvailable: false,
            expectedAttentionCard: true,
            expectedUpgradeCard: false,
        ),
        PremiumActionCardTestCase(
            attentionCardVisible: true,
            bannerDismissed: false,
            upgradeAvailable: true,
            expectedAttentionCard: true,
            expectedUpgradeCard: false,
        ),
        PremiumActionCardTestCase(
            attentionCardVisible: true,
            bannerDismissed: true,
            upgradeAvailable: false,
            expectedAttentionCard: true,
            expectedUpgradeCard: false,
        ),
        PremiumActionCardTestCase(
            attentionCardVisible: true,
            bannerDismissed: true,
            upgradeAvailable: true,
            expectedAttentionCard: true,
            expectedUpgradeCard: false,
        ),
    ])
    func perform_appeared_premiumActionCards(_ testCase: PremiumActionCardTestCase) async {
        billingService.shouldShowSubscriptionAttentionCardReturnValue = testCase.attentionCardVisible
        billingRepository.isInAppUpgradeAvailableReturnValue = testCase.upgradeAvailable
        stateService.isPremiumUpgradeBannerDismissedResult = testCase.bannerDismissed

        await subject.perform(.appeared)

        #expect(subject.state.shouldShowSubscriptionAttentionCard == testCase.expectedAttentionCard)
        #expect(subject.state.shouldShowPremiumUpgradeActionCard == testCase.expectedUpgradeCard)
    }

    /// `perform(_:)` with `.appeared` still shows the upgraded-to-Premium card even when the
    /// upgrade banner was previously dismissed.
    @Test
    func perform_appeared_loadPremiumUpgradeBanner_bannerDismissed_stillShowsUpgradedCard() async {
        stateService.isPremiumUpgradeBannerDismissedResult = true
        billingService.shouldShowUpgradedToPremiumActionCardReturnValue = true

        await subject.perform(.appeared)

        #expect(!subject.state.shouldShowPremiumUpgradeActionCard)
        #expect(subject.state.shouldShowUpgradedToPremiumActionCard)
    }

    /// `perform(_:)` with `.appeared` hides the subscription needs attention card when the
    /// cached state indicates it should not be shown.
    @Test
    func perform_appeared_subscriptionNeedsAttentionCard_hidden() async {
        billingService.shouldShowSubscriptionAttentionCardReturnValue = false

        await subject.perform(.appeared)

        #expect(!subject.state.shouldShowSubscriptionAttentionCard)
        #expect(!billingService.getSubscriptionCalled)
    }

    /// `perform(_:)` with `.appeared` shows the subscription needs attention card when the
    /// cached state indicates it should be shown.
    @Test
    func perform_appeared_subscriptionNeedsAttentionCard_shown() async {
        billingService.shouldShowSubscriptionAttentionCardReturnValue = true

        await subject.perform(.appeared)

        #expect(subject.state.shouldShowSubscriptionAttentionCard)
        #expect(!billingService.getSubscriptionCalled)
    }

    // MARK: Tests - perform(.dismiss*)

    /// `perform(_:)` with `.dismissPremiumUpgradeActionCard` dismisses the Premium upgrade card
    /// and persists the dismissal.
    @Test
    func perform_dismissPremiumUpgradeActionCard() async {
        stateService.activeAccount = .fixture()
        subject.state.shouldShowPremiumUpgradeActionCard = true

        await subject.perform(.dismissPremiumUpgradeActionCard)

        #expect(!subject.state.shouldShowPremiumUpgradeActionCard)
        #expect(stateService.premiumUpgradeBannerDismissedByUserId["1"] == true)
    }

    /// `perform(_:)` with `.dismissUpgradedToPremiumActionCard` hides the upgraded-to-Premium
    /// card and persists the dismissal.
    @Test
    func perform_dismissUpgradedToPremiumActionCard() async {
        subject.state.shouldShowUpgradedToPremiumActionCard = true

        await subject.perform(.dismissUpgradedToPremiumActionCard)

        #expect(!subject.state.shouldShowUpgradedToPremiumActionCard)
        #expect(billingService.setUpgradedToPremiumActionCardDismissedCallsCount == 1)
    }

    // MARK: Tests - receive(*)

    /// `receive(_:)` with `.learnMoreAboutPremium` opens the learn more about Premium URL,
    /// hides the card, and persists the dismissal.
    @Test
    func receive_learnMoreAboutPremium() async throws {
        subject.state.shouldShowUpgradedToPremiumActionCard = true

        subject.receive(.learnMoreAboutPremium)

        #expect(subject.state.url == ExternalLinksConstants.learnMoreAboutPremium)
        #expect(!subject.state.shouldShowUpgradedToPremiumActionCard)
        try await waitForAsync { billingService.setUpgradedToPremiumActionCardDismissedCallsCount == 1 }
        #expect(billingService.setUpgradedToPremiumActionCardDismissedCallsCount == 1)
    }

    /// `receive(_:)` with `.upgradeToPremium` delegates to the Premium upgrade helper.
    @Test
    func receive_upgradeToPremium() {
        subject.receive(.upgradeToPremium)

        #expect(premiumUpgradeHelper.startInAppPremiumUpgradeCalled)
    }

    /// `receive(_:)` with `.viewPlan` navigates to the Premium plan screen.
    @Test
    func receive_viewPlan() {
        subject.receive(.viewPlan)

        #expect(coordinator.routes.last == .premiumPlan)
    }
}

// MARK: - PremiumActionCardTestCase

/// Input/output data for the `perform_appeared_premiumActionCards` parameterized test.
private struct PremiumActionCardTestCase: Sendable {
    let attentionCardVisible: Bool
    let bannerDismissed: Bool
    let upgradeAvailable: Bool
    let expectedAttentionCard: Bool
    let expectedUpgradeCard: Bool
}
