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

    /// `perform(_:)` with `.appeared` hides the upgrade card when the attention card is hidden
    /// but the banner has been dismissed and no upgrade is available.
    @Test
    func perform_appeared_attentionCardHidden_bannerDismissed_upgradeNotAvailable() async {
        billingService.shouldShowSubscriptionAttentionCardReturnValue = false
        billingRepository.isInAppUpgradeAvailableReturnValue = false
        stateService.isPremiumUpgradeBannerDismissedResult = true

        await subject.perform(.appeared)

        #expect(!subject.state.shouldShowSubscriptionAttentionCard)
        #expect(!subject.state.shouldShowPremiumUpgradeActionCard)
    }

    /// `perform(_:)` with `.appeared` sets the upgrade card when the attention card is hidden,
    /// the banner has not been dismissed, and an upgrade is available.
    @Test
    func perform_appeared_attentionCardHidden_setsUpgradeCard() async {
        billingService.shouldShowSubscriptionAttentionCardReturnValue = false
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        stateService.isPremiumUpgradeBannerDismissedResult = false

        await subject.perform(.appeared)

        #expect(!subject.state.shouldShowSubscriptionAttentionCard)
        #expect(subject.state.shouldShowPremiumUpgradeActionCard)
    }

    /// `perform(_:)` with `.appeared` hides the upgrade card when the attention card is visible,
    /// the banner has been dismissed, and an upgrade is available.
    @Test
    func perform_appeared_attentionCardVisible_bannerDismissed_upgradeAvailable() async {
        billingService.shouldShowSubscriptionAttentionCardReturnValue = true
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        stateService.isPremiumUpgradeBannerDismissedResult = true

        await subject.perform(.appeared)

        #expect(subject.state.shouldShowSubscriptionAttentionCard)
        #expect(!subject.state.shouldShowPremiumUpgradeActionCard)
    }

    /// `perform(_:)` with `.appeared` hides the upgrade card when the attention card is visible,
    /// the banner has been dismissed, and no upgrade is available.
    @Test
    func perform_appeared_attentionCardVisible_bannerDismissed_upgradeNotAvailable() async {
        billingService.shouldShowSubscriptionAttentionCardReturnValue = true
        billingRepository.isInAppUpgradeAvailableReturnValue = false
        stateService.isPremiumUpgradeBannerDismissedResult = true

        await subject.perform(.appeared)

        #expect(subject.state.shouldShowSubscriptionAttentionCard)
        #expect(!subject.state.shouldShowPremiumUpgradeActionCard)
    }

    /// `perform(_:)` with `.appeared` hides the upgrade card when the attention card is visible,
    /// even when an upgrade is available — the two cards are mutually exclusive.
    @Test
    func perform_appeared_attentionCardVisible_hidesUpgradeCard() async {
        billingService.shouldShowSubscriptionAttentionCardReturnValue = true
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        stateService.isPremiumUpgradeBannerDismissedResult = false

        await subject.perform(.appeared)

        #expect(subject.state.shouldShowSubscriptionAttentionCard)
        #expect(!subject.state.shouldShowPremiumUpgradeActionCard)
    }

    /// `perform(_:)` with `.appeared` hides the upgrade card when the attention card is visible
    /// and no upgrade is available.
    @Test
    func perform_appeared_attentionCardVisible_upgradeNotAvailable() async {
        billingService.shouldShowSubscriptionAttentionCardReturnValue = true
        billingRepository.isInAppUpgradeAvailableReturnValue = false
        stateService.isPremiumUpgradeBannerDismissedResult = false

        await subject.perform(.appeared)

        #expect(subject.state.shouldShowSubscriptionAttentionCard)
        #expect(!subject.state.shouldShowPremiumUpgradeActionCard)
    }

    /// `perform(_:)` with `.appeared` hides the Premium upgrade action card when the banner
    /// has been dismissed.
    @Test
    func perform_appeared_loadPremiumUpgradeBanner_bannerDismissed() async {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        stateService.isPremiumUpgradeBannerDismissedResult = true

        await subject.perform(.appeared)

        #expect(!subject.state.shouldShowPremiumUpgradeActionCard)
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

    /// `perform(_:)` with `.appeared` shows the Premium upgrade action card when all conditions
    /// are met.
    @Test
    func perform_appeared_loadPremiumUpgradeBanner_shown() async {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        stateService.isPremiumUpgradeBannerDismissedResult = false

        await subject.perform(.appeared)

        #expect(subject.state.shouldShowPremiumUpgradeActionCard)
    }

    /// `perform(_:)` with `.appeared` hides the Premium upgrade action card when the in-app
    /// upgrade is not available.
    @Test
    func perform_appeared_loadPremiumUpgradeBanner_upgradeNotAvailable() async {
        billingRepository.isInAppUpgradeAvailableReturnValue = false

        await subject.perform(.appeared)

        #expect(!subject.state.shouldShowPremiumUpgradeActionCard)
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
