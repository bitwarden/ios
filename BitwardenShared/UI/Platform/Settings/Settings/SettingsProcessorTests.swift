import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class SettingsProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var billingService: MockBillingService!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var delegate: MockSettingsProcessorDelegate!
    var errorReporter: MockErrorReporter!
    var subject: SettingsProcessor!
    var stateService: MockStateService!
    var storefrontService: MockStorefrontService!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        billingService = MockBillingService()
        billingService.isSelfHostedReturnValue = false
        configService = MockConfigService()
        coordinator = MockCoordinator()
        delegate = MockSettingsProcessorDelegate()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        storefrontService = MockStorefrontService()
        storefrontService.isUSStorefrontReturnValue = true
        vaultRepository = MockVaultRepository()

        setUpSubject()
    }

    override func tearDown() {
        super.tearDown()

        billingService = nil
        configService = nil
        coordinator = nil
        delegate = nil
        errorReporter = nil
        subject = nil
        stateService = nil
        storefrontService = nil
        vaultRepository = nil
    }

    @MainActor
    func setUpSubject(presentationMode: SettingsPresentationMode = .tab) {
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
            state: SettingsState(presentationMode: presentationMode),
        )
    }

    // MARK: Tests

    /// `init()` does not subscribe to the badge publisher when the presentation mode is `.preLogin`.
    @MainActor
    func test_init_preLogin_doesNotSubscribeToBadgePublisher() async {
        setUpSubject(presentationMode: .preLogin)
        XCTAssertNil(subject.badgeUpdateTask)
    }

    /// `init()` subscribes to the badge publisher and notifies the delegate to update the badge
    /// count when it changes.
    @MainActor
    func test_init_subscribesToBadgePublisher() async throws {
        stateService.activeAccount = .fixture()
        setUpSubject()
        XCTAssertNotNil(subject.badgeUpdateTask)

        var badgeState = SettingsBadgeState.fixture(badgeValue: "1", vaultUnlockSetupProgress: .setUpLater)
        stateService.settingsBadgeSubject.send(badgeState)
        try await waitForAsync { self.delegate.badgeValue == "1" }
        XCTAssertEqual(delegate.badgeValue, "1")
        XCTAssertEqual(subject.state.badgeState, badgeState)

        badgeState = SettingsBadgeState.fixture(
            autofillSetupProgress: .setUpLater,
            badgeValue: "2",
            vaultUnlockSetupProgress: .setUpLater,
        )
        stateService.settingsBadgeSubject.send(badgeState)
        try await waitForAsync { self.delegate.badgeValue == "2" }
        XCTAssertEqual(delegate.badgeValue, "2")
        XCTAssertEqual(subject.state.badgeState, badgeState)

        badgeState = SettingsBadgeState.fixture(badgeValue: nil)
        stateService.settingsBadgeSubject.send(badgeState)
        try await waitForAsync { self.delegate.badgeValue == nil }
        XCTAssertNil(delegate.badgeValue)
        XCTAssertEqual(subject.state.badgeState, badgeState)
    }

    /// `init()` subscribes to the badge publisher and logs an error if one occurs.
    @MainActor
    func test_init_subscribesToBadgePublisher_error() async throws {
        setUpSubject()

        stateService.settingsBadgeSubject.send(SettingsBadgeState.fixture(badgeValue: "1"))
        try await waitForAsync { !self.errorReporter.errors.isEmpty }

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// Receiving `.aboutPressed` navigates to the about screen.
    @MainActor
    func test_receive_aboutPressed() {
        subject.receive(.aboutPressed)

        XCTAssertEqual(coordinator.routes.last, .about)
    }

    /// Receiving `.accountSecurityPressed` navigates to the account security screen.
    @MainActor
    func test_receive_accountSecurityPressed() {
        subject.receive(.accountSecurityPressed)

        XCTAssertEqual(coordinator.routes.last, .accountSecurity)
    }

    /// Receiving `.appearancePressed` navigates to the appearance screen.
    @MainActor
    func test_receive_appearancePressed() {
        subject.receive(.appearancePressed)

        XCTAssertEqual(coordinator.routes.last, .appearance)
    }

    /// Receiving `.autoFillPressed` navigates to the auto-fill screen.
    @MainActor
    func test_receive_autoFillPressed() {
        subject.receive(.autoFillPressed)

        XCTAssertEqual(coordinator.routes.last, .autoFill)
    }

    /// Receiving `.dismiss` has the coordinator dismiss the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// Receiving `.otherPressed` navigates to the other screen.
    @MainActor
    func test_receive_otherPressed() {
        subject.receive(.otherPressed)

        XCTAssertEqual(coordinator.routes.last, .other)
    }

    /// `perform(.planPressed)` navigates to the premium plan screen for a premium user
    /// without showing a loading overlay.
    @MainActor
    func test_perform_planPressed_hasPremium() async {
        subject.state.hasPremium = true

        await subject.perform(.planPressed)

        XCTAssertEqual(coordinator.routes.last, .premiumPlan(nil))
        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
    }

    /// `perform(.planPressed)` shows a loading overlay and navigates to the premium plan screen
    /// when the user has a canceled subscription.
    @MainActor
    func test_perform_planPressed_canceledSubscription() async {
        subject.state.hasPremium = false
        let subscription = PremiumSubscription.fixture(status: .canceled)
        billingService.getSubscriptionReturnValue = subscription

        await subject.perform(.planPressed)

        XCTAssertEqual(coordinator.routes.last, .premiumPlan(subscription))
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.loading)])
    }

    /// `perform(.planPressed)` shows a loading overlay and navigates to the premium plan screen
    /// when the user has a past due subscription.
    @MainActor
    func test_perform_planPressed_pastDueSubscription() async {
        subject.state.hasPremium = false
        let subscription = PremiumSubscription.fixture(status: .pastDue)
        billingService.getSubscriptionReturnValue = subscription

        await subject.perform(.planPressed)

        XCTAssertEqual(coordinator.routes.last, .premiumPlan(subscription))
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.loading)])
    }

    /// `perform(.planPressed)` shows a loading overlay and navigates to the premium upgrade screen
    /// when the subscription fetch returns a 404 (free user with no subscription).
    @MainActor
    func test_perform_planPressed_freeUser_noSubscription() async {
        subject.state.hasPremium = false
        billingService.getSubscriptionThrowableError = GetSubscriptionRequestError.noSubscription

        await subject.perform(.planPressed)

        XCTAssertEqual(coordinator.routes.last, .premiumUpgrade)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.loading)])
        XCTAssertFalse(errorReporter.errors.contains { $0 is GetSubscriptionRequestError })
    }

    /// `perform(.planPressed)` shows a loading overlay and shows an error alert
    /// when the subscription fetch fails with a non-404 error.
    @MainActor
    func test_perform_planPressed_freeUser_subscriptionFetchError() async {
        subject.state.hasPremium = false
        billingService.getSubscriptionThrowableError = BitwardenTestError.example

        await subject.perform(.planPressed)

        XCTAssertEqual(coordinator.errorAlertsShown.count, 1)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.loading)])
        XCTAssertTrue(errorReporter.errors.contains { $0 as? BitwardenTestError == .example })
    }

    /// `perform(.planPressed)` shows a loading overlay and navigates to the premium upgrade screen
    /// when subscription status is active.
    @MainActor
    func test_perform_planPressed_activeSubscription() async {
        subject.state.hasPremium = false
        billingService.getSubscriptionReturnValue = .fixture(status: .active)

        await subject.perform(.planPressed)

        XCTAssertEqual(coordinator.routes.last, .premiumUpgrade)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.loading)])
    }

    /// Receiving `.vaultPressed` navigates to the vault settings screen.
    @MainActor
    func test_receive_vaultPressed() {
        subject.receive(.vaultPressed)

        XCTAssertEqual(coordinator.routes.last, .vault)
    }

    /// `perform(.appeared)` hides the plan row when the feature flag is disabled.
    @MainActor
    func test_perform_appeared_hidesPlanRow_featureFlagOff() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false
        vaultRepository.doesActiveAccountHavePremiumResult = true

        await subject.perform(.appeared)

        XCTAssertFalse(subject.state.showPlanRow)
    }

    /// `perform(.appeared)` does nothing in pre-login presentation mode.
    @MainActor
    func test_perform_appeared_preLogin_doesNothing() async {
        setUpSubject(presentationMode: .preLogin)
        await subject.perform(.appeared)
        XCTAssertFalse(subject.state.hasPremium)
        XCTAssertFalse(subject.state.showPlanRow)
    }

    /// `perform(.appeared)` shows the plan row for a free user when the feature flag is enabled.
    @MainActor
    func test_perform_appeared_showsPlanRow_freeUser() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        vaultRepository.doesActiveAccountHavePremiumResult = false

        await subject.perform(.appeared)

        XCTAssertTrue(subject.state.showPlanRow)
        XCTAssertFalse(subject.state.hasPremium)
    }

    /// `perform(.appeared)` hides the plan row when the billing service reports self-hosted.
    @MainActor
    func test_perform_appeared_hidesPlanRow_selfHosted() async {
        billingService.isSelfHostedReturnValue = true
        configService.featureFlagsBool[.premiumUpgradePath] = true
        vaultRepository.doesActiveAccountHavePremiumResult = true

        await subject.perform(.appeared)

        XCTAssertFalse(subject.state.showPlanRow)
    }

    /// `perform(.appeared)` hides the plan row when the storefront is not US.
    @MainActor
    func test_perform_appeared_hidesPlanRow_nonUSStorefront() async {
        storefrontService.isUSStorefrontReturnValue = false
        configService.featureFlagsBool[.premiumUpgradePath] = true

        await subject.perform(.appeared)

        XCTAssertFalse(subject.state.showPlanRow)
    }

    /// `perform(.appeared)` shows the plan row when the feature flag is enabled and the user has premium.
    @MainActor
    func test_perform_appeared_showsPlanRow_hasPremium() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        vaultRepository.doesActiveAccountHavePremiumResult = true

        await subject.perform(.appeared)

        XCTAssertTrue(subject.state.showPlanRow)
        XCTAssertTrue(subject.state.hasPremium)
    }

    /// `perform(.appeared)` shows the plan row for a self-hosted user when the debug override is enabled.
    @MainActor
    func test_perform_appeared_showsPlanRow_selfHosted_debugOverrideEnabled() async {
        billingService.isSelfHostedReturnValue = false
        configService.featureFlagsBool[.premiumUpgradePath] = true
        vaultRepository.doesActiveAccountHavePremiumResult = false

        await subject.perform(.appeared)

        XCTAssertTrue(subject.state.showPlanRow)
    }
}

class MockSettingsProcessorDelegate: SettingsProcessorDelegate {
    var badgeValue: String?

    func updateSettingsTabBadge(_ badgeValue: String?) {
        self.badgeValue = badgeValue
    }
}
