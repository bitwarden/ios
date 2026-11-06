import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// swiftlint:disable file_length

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
        billingService.premiumUpgradeLifecycleStateReturnValue = .notPremium
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
    func navigateToPremiumUpgrade_inAppAvailable() async {
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

        #expect(coordinator.routes.last == .premiumUpgrade)
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
    /// when no upgrade is pending.
    @Test
    func startInAppPremiumUpgrade_navigatesWithoutAvailabilityCheck() async {
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

        await subject.startInAppPremiumUpgrade()

        #expect(coordinator.routes.last == .premiumUpgrade)
        #expect(!billingRepository.isInAppUpgradeAvailableCalled)
    }

    /// `startInAppPremiumUpgrade(onConfirmed:)` calls `onPendingDismiss` when an upgrade is
    /// already pending.
    @Test
    func startInAppPremiumUpgrade_pendingAlert_callsOnPendingDismiss() async {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        billingService.premiumUpgradeLifecycleStateReturnValue = .pending
        var onPendingDismissCalled = false
        let subject = makeSubject(onPendingDismiss: { onPendingDismissCalled = true })

        await subject.startInAppPremiumUpgrade()

        #expect(onPendingDismissCalled)
    }

    /// When an upgrade is already pending, a `.confirmed` after "Sync Now" is tapped on another
    /// helper's upgrade pending alert doesn't navigate.
    @Test
    func startInAppPremiumUpgrade_pendingAlert_otherHelperSyncNowConfirmed_doesNotNavigate() async throws {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        billingService.premiumUpgradeLifecycleStateReturnValue = .pending
        let otherCoordinator = MockCoordinator<VaultRoute, AuthAction>()
        let otherSubject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            coordinator: otherCoordinator.asAnyCoordinator(),
            setURL: { _ in },
        )
        let subject = makeSubject()
        await subject.startInAppPremiumUpgrade()
        await otherSubject.startInAppPremiumUpgrade()
        try await otherCoordinator.alertShown.last?.tapAction(title: Localizations.syncNow)

        statusSubject.send(.confirmed)

        try await waitForAsync { otherCoordinator.routes.last == .premiumUpgradeComplete }
        #expect(coordinator.routes.isEmpty)
    }

    /// When an upgrade is already pending, a `.pending` after "Sync Now" is tapped on another
    /// helper's upgrade pending alert doesn't show the alert again.
    @Test
    func startInAppPremiumUpgrade_pendingAlert_otherHelperSyncNowPending_doesNotShowAlert() async throws {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        billingService.premiumUpgradeLifecycleStateReturnValue = .pending
        let otherCoordinator = MockCoordinator<VaultRoute, AuthAction>()
        let otherSubject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            coordinator: otherCoordinator.asAnyCoordinator(),
            setURL: { _ in },
        )
        let subject = makeSubject()
        await subject.startInAppPremiumUpgrade()
        await otherSubject.startInAppPremiumUpgrade()
        try await otherCoordinator.alertShown.last?.tapAction(title: Localizations.syncNow)

        statusSubject.send(.pending)

        try await waitForAsync { otherCoordinator.alertShown.count == 2 }
        #expect(coordinator.alertShown.count == 1)
    }

    /// When an upgrade is already pending, a `.confirmed` after "Sync Now" is tapped on the upgrade
    /// pending alert navigates to the Premium upgrade complete screen.
    @Test
    func startInAppPremiumUpgrade_pendingAlert_retryConfirmed_navigatesToPremiumUpgradeComplete() async throws {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        billingService.premiumUpgradeLifecycleStateReturnValue = .pending
        let subject = makeSubject()
        await subject.startInAppPremiumUpgrade()
        try await coordinator.alertShown.last?.tapAction(title: Localizations.syncNow)

        statusSubject.send(.confirmed)

        try await waitForAsync { coordinator.routes.last == .premiumUpgradeComplete }
    }

    /// When an upgrade is already pending, a `.pending` after "Sync Now" is tapped on the upgrade
    /// pending alert shows the alert again without dismissing anything.
    @Test
    func startInAppPremiumUpgrade_pendingAlert_retryStillPending_doesNotDismiss() async throws {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        billingService.premiumUpgradeLifecycleStateReturnValue = .pending
        let subject = makeSubject()
        await subject.startInAppPremiumUpgrade()
        try await coordinator.alertShown.last?.tapAction(title: Localizations.syncNow)

        statusSubject.send(.pending)

        try await waitForAsync { coordinator.alertShown.count == 2 }
        #expect(coordinator.alertShown.last?.title == Localizations.upgradePending)
        #expect(coordinator.routes.isEmpty)
    }

    /// When an upgrade is already pending, tapping "Sync Now" on the upgrade pending alert calls
    /// `retryPendingUpgrade()`.
    @Test
    func startInAppPremiumUpgrade_pendingAlert_syncNow_retriesPendingUpgrade() async throws {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        billingService.premiumUpgradeLifecycleStateReturnValue = .pending
        let subject = makeSubject()
        await subject.startInAppPremiumUpgrade()

        try await coordinator.alertShown.last?.tapAction(title: Localizations.syncNow)

        #expect(billingService.retryPendingUpgradeCalled)
        #expect(!billingService.premiumCheckoutSucceededCalled)
    }

    /// `startInAppPremiumUpgrade(onConfirmed:)` navigates to the Premium upgrade screen when the
    /// account already has Premium.
    @Test
    func startInAppPremiumUpgrade_premium_navigatesToPremiumUpgrade() async {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        billingService.premiumUpgradeLifecycleStateReturnValue = .premium
        let subject = makeSubject()

        await subject.startInAppPremiumUpgrade()

        #expect(coordinator.routes.last == .premiumUpgrade)
        #expect(coordinator.alertShown.isEmpty)
    }

    /// `startInAppPremiumUpgrade(onConfirmed:)` ignores a second call while the first call's
    /// pending check is in flight.
    @Test
    func startInAppPremiumUpgrade_rapidDoubleCall_onlyNavigatesOnce() async throws {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        let (checkResumed, resumeCheck) = AsyncStream<Void>.makeStream()
        billingService.premiumUpgradeLifecycleStateClosure = { _ in
            for await _ in checkResumed {
                break
            }
            return .notPremium
        }
        let subject = makeSubject()
        let firstCall = Task { await subject.startInAppPremiumUpgrade() }
        try await waitForAsync { billingService.premiumUpgradeLifecycleStateCallsCount == 1 }

        await subject.startInAppPremiumUpgrade()
        resumeCheck.yield()
        await firstCall.value

        #expect(billingService.premiumUpgradeLifecycleStateCallsCount == 1)
        #expect(coordinator.routes == [.premiumUpgrade])
    }

    /// `startInAppPremiumUpgrade(onConfirmed:)` shows the upgrade pending alert instead of the
    /// Premium upgrade screen when an upgrade is already pending.
    @Test
    func startInAppPremiumUpgrade_showsPendingAlertWhenAlreadyPending() async {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        billingService.premiumUpgradeLifecycleStateReturnValue = .pending
        let subject = makeSubject()

        await subject.startInAppPremiumUpgrade()

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

        statusSubject.send(.confirmed)

        try await waitForAsync { onConfirmedCalled }
        #expect(onConfirmedCalled)
        #expect(coordinator.routes.last == .premiumUpgrade)
    }

    /// A `.confirmed` after `.pending` has dismissed the upgrade screen navigates to the Premium
    /// upgrade complete screen and calls `onConfirmed`.
    @Test
    func subscribeToPremiumCheckoutStatus_confirmed_afterPending_navigatesToPremiumUpgradeComplete() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        var onConfirmedCalled = false
        let subject = makeSubject()
        await subject.navigateToPremiumUpgrade(onConfirmed: { onConfirmedCalled = true })
        statusSubject.send(.pending)
        try await waitForAsync {
            guard case .dismiss = coordinator.routes.last else { return false }
            return true
        }

        statusSubject.send(.confirmed)

        try await waitForAsync { onConfirmedCalled }
        #expect(coordinator.routes.last == .premiumUpgradeComplete)
    }

    /// A `.confirmed` after a new upgrade starts following an earlier `.pending` doesn't navigate
    /// to the Premium upgrade complete screen.
    @Test
    func subscribeToPremiumCheckoutStatus_confirmed_afterPending_newUpgradeStarted_doesNotNavigate() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        var onConfirmedCalled = false
        let subject = makeSubject()
        await subject.navigateToPremiumUpgrade()
        statusSubject.send(.pending)
        try await waitForAsync {
            guard case .dismiss = coordinator.routes.last else { return false }
            return true
        }
        await subject.startInAppPremiumUpgrade(onConfirmed: { onConfirmedCalled = true })

        statusSubject.send(.confirmed)

        try await waitForAsync { onConfirmedCalled }
        #expect(coordinator.routes.last == .premiumUpgrade)
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

    /// When the billing service emits `.pending` again after "Sync Now" is tapped following the
    /// dismissal of the Premium upgrade screen, the upgrade pending alert is shown again without
    /// another dismiss.
    @Test
    func subscribeToPremiumCheckoutStatus_pending_secondPendingAfterDismiss_doesNotDismissAgain() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
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
        try await coordinator.alertShown.last?.tapAction(title: Localizations.syncNow)

        statusSubject.send(.pending)

        try await waitForAsync { coordinator.alertShown.count == 2 }
        #expect(coordinator.routes.count(where: { route in
            guard case .dismiss = route else { return false }
            return true
        }) == 1)
    }

    /// When the billing service emits `.pending`, tapping "Sync Now" on the upgrade pending alert
    /// calls `retryPendingUpgrade()`.
    @Test
    func subscribeToPremiumCheckoutStatus_pending_syncNow_retriesPendingUpgrade() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
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

        try await coordinator.alertShown.last?.tapAction(title: Localizations.syncNow)

        #expect(billingService.retryPendingUpgradeCalled)
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
        let routeCountBeforeSend = coordinator.routes.count

        statusSubject.send(.syncing)
        // Yield to let the `.receive(on: DispatchQueue.main)` dispatch run.
        await Task.yield()

        #expect(coordinator.routes.count == routeCountBeforeSend)
    }
}
