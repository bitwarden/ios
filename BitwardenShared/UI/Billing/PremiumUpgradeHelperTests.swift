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
struct PremiumUpgradeHelperTests {
    // MARK: Properties

    let billingRepository: MockBillingRepository
    let billingService: MockBillingService
    let coordinator: MockCoordinator<VaultRoute, AuthAction>
    let environmentService: MockEnvironmentService

    // MARK: Initialization

    init() {
        billingRepository = MockBillingRepository()
        billingService = MockBillingService()
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

    /// `navigateToPremiumUpgrade(onConfirmed:)` navigates to the premium upgrade route when
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

    /// `startInAppPremiumUpgrade(onConfirmed:)` navigates directly without checking availability.
    @Test
    func startInAppPremiumUpgrade_navigatesWithoutAvailabilityCheck() {
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

        #expect(coordinator.routes.last == .premiumUpgrade)
        #expect(!billingRepository.isInAppUpgradeAvailableCalled)
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
