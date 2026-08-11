import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - PremiumUpgradeHelperTests

@MainActor
struct PremiumUpgradeHelperTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let billingRepository: MockBillingRepository
    let billingService: MockBillingService
    let coordinator: MockCoordinator<VaultRoute, AuthAction>
    let environmentService: MockEnvironmentService

    // MARK: Initialization

    init() {
        billingRepository = MockBillingRepository()
        billingService = MockBillingService()
        billingService.premiumUpgradePendingStateReturnValue = PremiumUpgradePendingState(
            isPending: false,
            lastAttemptFailed: false,
        )
        coordinator = MockCoordinator()
        environmentService = MockEnvironmentService()
    }

    // MARK: Helpers

    private func makeSubject(
        onPendingDismiss: (() -> Void)? = nil,
    ) -> DefaultPremiumUpgradeHelper<VaultRoute, AuthAction> {
        DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            coordinator: coordinator.asAnyCoordinator(),
            setURL: { _ in },
            onPendingDismiss: onPendingDismiss,
        )
    }

    // MARK: Tests — navigateToPremiumUpgrade

    /// `navigateToPremiumUpgrade(onConfirmed:)` navigates to the Premium upgrade route when
    /// in-app upgrade is available.
    @Test
    func navigateToPremiumUpgrade_inAppAvailable() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        var capturedURL: URL?
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            coordinator: coordinator.asAnyCoordinator(),
            setURL: { capturedURL = $0 },
        )

        await subject.navigateToPremiumUpgrade()

        try await waitForAsync { coordinator.routes.last == .premiumUpgrade }
        #expect(capturedURL == nil)
    }

    /// `navigateToPremiumUpgrade(onConfirmed:)` sets the URL to the web fallback when in-app
    /// upgrade is not available.
    @Test
    func navigateToPremiumUpgrade_inAppNotAvailable() async {
        billingRepository.isInAppUpgradeAvailableReturnValue = false
        var capturedURL: URL?
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            coordinator: coordinator.asAnyCoordinator(),
            setURL: { capturedURL = $0 },
        )

        await subject.navigateToPremiumUpgrade()

        #expect(capturedURL == environmentService.upgradeToPremiumURL)
        #expect(coordinator.routes.last != .premiumUpgrade)
    }

    // MARK: Tests — startInAppPremiumUpgrade

    /// `startInAppPremiumUpgrade(onConfirmed:)` navigates directly without checking availability
    /// when no upgrade is currently pending.
    @Test
    func startInAppPremiumUpgrade_navigatesWithoutAvailabilityCheck() async throws {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            coordinator: coordinator.asAnyCoordinator(),
            setURL: { _ in },
        )

        subject.startInAppPremiumUpgrade()

        try await waitForAsync { coordinator.routes.last == .premiumUpgrade }
        #expect(!billingRepository.isInAppUpgradeAvailableCalled)
    }

    /// `startInAppPremiumUpgrade(onConfirmed:)` ignores a second call that arrives while the
    /// first call's pending-state check is still in flight (e.g. a rapid double-tap on the same
    /// CTA) — only the first call navigates.
    @Test
    func startInAppPremiumUpgrade_rapidDoubleCall_onlyNavigatesOnce() async throws {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        let subject = makeSubject()

        subject.startInAppPremiumUpgrade()
        subject.startInAppPremiumUpgrade()

        try await waitForAsync { coordinator.routes.last == .premiumUpgrade }
        // Give a wrongly-allowed second resolution a chance to also land before asserting.
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(coordinator.routes.count(where: { $0 == .premiumUpgrade }) == 1)
    }

    /// `startInAppPremiumUpgrade(onConfirmed:)` shows the upgrade pending alert instead of
    /// navigating to the upgrade screen when an upgrade is already pending — closing the door on
    /// any of this helper's callers (Settings > Plan, Send, item views, etc.) starting a second,
    /// redundant checkout while one is still unresolved.
    @Test
    func startInAppPremiumUpgrade_showsPendingAlertWhenAlreadyPending() async throws {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        billingService.premiumUpgradePendingStateReturnValue = PremiumUpgradePendingState(
            isPending: true,
            lastAttemptFailed: false,
        )
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            coordinator: coordinator.asAnyCoordinator(),
            setURL: { _ in },
        )

        subject.startInAppPremiumUpgrade()

        try await waitForAsync { !coordinator.alertShown.isEmpty }
        #expect(coordinator.alertShown.last?.title == Localizations.upgradePending)
        #expect(coordinator.routes.last != .premiumUpgrade)
    }

    /// `startInAppPremiumUpgrade(onConfirmed:)` calls `onPendingDismiss` when it shows the
    /// upgrade pending alert directly, matching the cleanup already done when `.pending` arrives
    /// mid-checkout (e.g. dismissing the Vault tab's action card).
    @Test
    func startInAppPremiumUpgrade_pendingAlert_callsOnPendingDismiss() async throws {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        billingService.premiumUpgradePendingStateReturnValue = PremiumUpgradePendingState(
            isPending: true,
            lastAttemptFailed: false,
        )
        var onPendingDismissCalled = false
        let subject = makeSubject(onPendingDismiss: { onPendingDismissCalled = true })

        subject.startInAppPremiumUpgrade()

        try await waitForAsync { onPendingDismissCalled }
    }

    /// `startInAppPremiumUpgrade(onConfirmed:)`, having shown the pending alert directly without
    /// navigating anywhere, does not try to dismiss anything if the "Sync Now" retry it triggers
    /// also comes back `.pending` — there's no Premium upgrade screen to dismiss, since none was
    /// ever opened. Re-shows the alert directly instead.
    @Test
    func startInAppPremiumUpgrade_pendingAlert_retryStillPending_doesNotDismiss() async throws {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        billingService.premiumUpgradePendingStateReturnValue = PremiumUpgradePendingState(
            isPending: true,
            lastAttemptFailed: false,
        )
        let subject = makeSubject()

        subject.startInAppPremiumUpgrade()
        try await waitForAsync { !coordinator.alertShown.isEmpty }

        statusSubject.send(.pending)

        try await waitForAsync { coordinator.alertShown.count == 2 }
        #expect(coordinator.alertShown.last?.title == Localizations.upgradePending)
        #expect(coordinator.routes.isEmpty)
    }

    // MARK: Tests — subscribeToPremiumCheckoutStatus

    /// When the billing service emits `.canceled`, nothing happens.
    @Test
    func subscribeToPremiumCheckoutStatus_canceled() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            coordinator: coordinator.asAnyCoordinator(),
            setURL: { _ in },
        )
        await subject.navigateToPremiumUpgrade()
        try await waitForAsync { coordinator.routes.last == .premiumUpgrade }
        let routeCountBeforeSend = coordinator.routes.count

        statusSubject.send(.canceled)
        // Yield to let the `.receive(on: DispatchQueue.main)` dispatch run.
        await Task.yield()

        #expect(coordinator.routes.count == routeCountBeforeSend)
    }

    /// When the billing service emits `.confirmed`, the `onConfirmed` closure is called and
    /// the cancellable is released.
    @Test
    func subscribeToPremiumCheckoutStatus_confirmed() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        var onConfirmedCalled = false
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            coordinator: coordinator.asAnyCoordinator(),
            setURL: { _ in },
        )
        await subject.navigateToPremiumUpgrade(onConfirmed: {
            onConfirmedCalled = true
        })
        try await waitForAsync { coordinator.routes.last == .premiumUpgrade }

        statusSubject.send(.confirmed)

        try await waitForAsync { onConfirmedCalled }
        #expect(onConfirmedCalled)
    }

    /// When the billing service emits `.pending`, the coordinator navigates to `.dismiss`.
    /// Executing the dismiss action hides the overlay and shows the upgrade pending alert.
    @Test
    func subscribeToPremiumCheckoutStatus_pending_noOnPendingDismiss() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            coordinator: coordinator.asAnyCoordinator(),
            setURL: { _ in },
        )
        await subject.navigateToPremiumUpgrade()
        try await waitForAsync { coordinator.routes.last == .premiumUpgrade }

        statusSubject.send(.pending)

        try await waitForAsync {
            guard case let .dismiss(action) = coordinator.routes.last else { return false }
            return action != nil
        }
        guard case let .dismiss(action) = coordinator.routes.last else {
            Issue.record("Expected .dismiss route")
            return
        }
        action?.action()

        #expect(coordinator.alertShown.last?.title == Localizations.upgradePending)
        #expect(!coordinator.isLoadingOverlayShowing)
    }

    /// When the billing service emits `.pending`, executing the dismiss action calls `onPendingDismiss`.
    @Test
    func subscribeToPremiumCheckoutStatus_pending_callsOnPendingDismiss() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        var onPendingDismissCalled = false
        let subject = makeSubject(onPendingDismiss: { onPendingDismissCalled = true })
        await subject.navigateToPremiumUpgrade()
        try await waitForAsync { coordinator.routes.last == .premiumUpgrade }

        statusSubject.send(.pending)

        try await waitForAsync {
            guard case let .dismiss(action) = coordinator.routes.last else { return false }
            return action != nil
        }
        guard case let .dismiss(action) = coordinator.routes.last else {
            Issue.record("Expected .dismiss route")
            return
        }
        action?.action()
        #expect(onPendingDismissCalled)
    }

    /// When the billing service emits `.pending` a second time after the first `.pending`'s
    /// dismiss action already ran, the coordinator does not dismiss again — there's no longer a
    /// Premium upgrade screen on the stack to dismiss, since the first `.pending` already closed
    /// it. The pending alert is shown directly instead.
    @Test
    func subscribeToPremiumCheckoutStatus_pending_secondPendingAfterDismiss_doesNotDismissAgain() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            coordinator: coordinator.asAnyCoordinator(),
            setURL: { _ in },
        )
        await subject.navigateToPremiumUpgrade()
        try await waitForAsync { coordinator.routes.last == .premiumUpgrade }

        statusSubject.send(.pending)
        try await waitForAsync {
            guard case let .dismiss(action) = coordinator.routes.last else { return false }
            return action != nil
        }
        guard case let .dismiss(action) = coordinator.routes.last else {
            Issue.record("Expected .dismiss route")
            return
        }
        action?.action()
        try await waitForAsync { coordinator.alertShown.count == 1 }

        statusSubject.send(.pending)

        try await waitForAsync { coordinator.alertShown.count == 2 }
        #expect(coordinator.routes.count(where: { route in
            guard case .dismiss = route else { return false }
            return true
        }) == 1)
    }

    /// Tapping "Sync Now" on the upgrade pending alert navigates to the standalone Premium
    /// upgrade complete screen only when the retry actually resolves the pending upgrade — not
    /// when it's still pending (not yet Premium) or the retry itself failed, both of which are
    /// covered by PR2's CTA and PR3's "Sync unsuccessful" alert independently, via the durable
    /// `premiumUpgradePendingStatePublisher()` signal.
    @Test(arguments: [
        (PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false), true),
        (PremiumUpgradePendingState(isPending: true, lastAttemptFailed: false), false),
        (PremiumUpgradePendingState(isPending: true, lastAttemptFailed: true), false),
        (PremiumUpgradePendingState(isPending: false, lastAttemptFailed: true), false),
    ])
    func subscribeToPremiumCheckoutStatus_pending_syncNow(
        pendingState: PremiumUpgradePendingState,
        expectedNavigatesToComplete: Bool,
    ) async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        billingService.premiumUpgradePendingStateReturnValue = pendingState
        let subject = makeSubject()
        await subject.navigateToPremiumUpgrade()

        statusSubject.send(.pending)
        try await waitForAsync {
            guard case let .dismiss(action) = coordinator.routes.last else { return false }
            return action != nil
        }
        guard case let .dismiss(action) = coordinator.routes.last else {
            Issue.record("Expected .dismiss route")
            return
        }
        action?.action()

        let alert = try #require(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.syncNow)

        #expect(billingService.reconcileCheckoutSuccessCalled)
        #expect((coordinator.routes.last == .premiumUpgradeComplete) == expectedNavigatesToComplete)
    }

    /// When the billing service emits `.syncing`, nothing happens (the loading overlay is shown
    /// by `PremiumUpgradeProcessor`).
    @Test
    func subscribeToPremiumCheckoutStatus_syncing() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            coordinator: coordinator.asAnyCoordinator(),
            setURL: { _ in },
        )
        await subject.navigateToPremiumUpgrade()
        try await waitForAsync { coordinator.routes.last == .premiumUpgrade }
        let routeCountBeforeSend = coordinator.routes.count

        statusSubject.send(.syncing)
        // Yield to let the `.receive(on: DispatchQueue.main)` dispatch run.
        await Task.yield()

        #expect(coordinator.routes.count == routeCountBeforeSend)
    }
}
