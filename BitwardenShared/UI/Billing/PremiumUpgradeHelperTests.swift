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
    let environmentService: MockEnvironmentService

    // MARK: Initialization

    init() {
        billingRepository = MockBillingRepository()
        billingService = MockBillingService()
        environmentService = MockEnvironmentService()
    }

    // MARK: Tests — navigateToPremiumUpgrade

    /// `navigateToPremiumUpgrade(onConfirmed:)` navigates to the premium upgrade route when
    /// in-app upgrade is available.
    @Test
    func navigateToPremiumUpgrade_inAppAvailable() async {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        var navigateCalled = false
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            navigateToPremiumRoute: { navigateCalled = true },
            setURL: { _ in },
            navigateToDismiss: { _ in },
            showAlert: { _ in },
            hideLoadingOverlay: {},
        )

        await subject.navigateToPremiumUpgrade()

        #expect(navigateCalled)
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
            navigateToPremiumRoute: {},
            setURL: { capturedURL = $0 },
            navigateToDismiss: { _ in },
            showAlert: { _ in },
            hideLoadingOverlay: {},
        )

        await subject.navigateToPremiumUpgrade()

        #expect(capturedURL == environmentService.upgradeToPremiumURL)
    }

    // MARK: Tests — startInAppPremiumUpgrade

    /// `startInAppPremiumUpgrade(onConfirmed:)` navigates directly without checking availability.
    @Test
    func startInAppPremiumUpgrade_navigatesWithoutAvailabilityCheck() {
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        var navigateCalled = false
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            navigateToPremiumRoute: { navigateCalled = true },
            setURL: { _ in },
            navigateToDismiss: { _ in },
            showAlert: { _ in },
            hideLoadingOverlay: {},
        )

        subject.startInAppPremiumUpgrade()

        #expect(navigateCalled)
        #expect(!billingRepository.isInAppUpgradeAvailableCalled)
    }

    // MARK: Tests — subscribeToPremiumCheckoutStatus

    /// When the billing service emits `.canceled`, nothing happens.
    @Test
    func subscribeToPremiumCheckoutStatus_canceled() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        var navigateToDismissCalled = false
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            navigateToPremiumRoute: {},
            setURL: { _ in },
            navigateToDismiss: { _ in navigateToDismissCalled = true },
            showAlert: { _ in },
            hideLoadingOverlay: {},
        )
        await subject.navigateToPremiumUpgrade()

        statusSubject.send(.canceled)
        // Yield to let the `.receive(on: DispatchQueue.main)` dispatch run.
        await Task.yield()

        #expect(!navigateToDismissCalled)
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
            navigateToPremiumRoute: {},
            setURL: { _ in },
            navigateToDismiss: { _ in },
            showAlert: { _ in },
            hideLoadingOverlay: {},
        )
        await subject.navigateToPremiumUpgrade(onConfirmed: {
            onConfirmedCalled = true
        })

        statusSubject.send(.confirmed)

        try await waitForAsync { onConfirmedCalled }
        #expect(onConfirmedCalled)
    }

    /// When the billing service emits `.pending`, `navigateToDismiss` is called. Executing the
    /// dismiss action hides the overlay and shows the upgrade pending alert.
    @Test
    func subscribeToPremiumCheckoutStatus_pending_noOnPendingDismiss() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        var capturedDismissAction: DismissAction?
        var hideLoadingOverlayCalled = false
        var shownAlerts: [Alert] = []
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            navigateToPremiumRoute: {},
            setURL: { _ in },
            navigateToDismiss: { capturedDismissAction = $0 },
            showAlert: { shownAlerts.append($0) },
            hideLoadingOverlay: { hideLoadingOverlayCalled = true },
        )
        await subject.navigateToPremiumUpgrade()

        statusSubject.send(.pending)

        try await waitForAsync { capturedDismissAction != nil }
        let dismissAction = try #require(capturedDismissAction)
        dismissAction.action()

        #expect(hideLoadingOverlayCalled)
        #expect(shownAlerts.last?.title == Localizations.upgradePending)
    }

    /// When the billing service emits `.pending`, executing the dismiss action calls `onPendingDismiss`.
    @Test
    func subscribeToPremiumCheckoutStatus_pending_callsOnPendingDismiss() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        var capturedDismissAction: DismissAction?
        var onPendingDismissCalled = false
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            navigateToPremiumRoute: {},
            setURL: { _ in },
            navigateToDismiss: { capturedDismissAction = $0 },
            showAlert: { _ in },
            hideLoadingOverlay: {},
            onPendingDismiss: { onPendingDismissCalled = true },
        )
        await subject.navigateToPremiumUpgrade()

        statusSubject.send(.pending)

        try await waitForAsync { capturedDismissAction != nil }
        capturedDismissAction?.action()
        #expect(onPendingDismissCalled)
    }

    /// When the billing service emits `.syncing`, nothing happens (the loading overlay is shown
    /// by `PremiumUpgradeProcessor`).
    @Test
    func subscribeToPremiumCheckoutStatus_syncing() async throws {
        billingRepository.isInAppUpgradeAvailableReturnValue = true
        let statusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = statusSubject.eraseToAnyPublisher()
        var navigateToDismissCalled = false
        let subject = DefaultPremiumUpgradeHelper(
            services: ServiceContainer.withMocks(
                billingRepository: billingRepository,
                billingService: billingService,
                environmentService: environmentService,
            ),
            navigateToPremiumRoute: {},
            setURL: { _ in },
            navigateToDismiss: { _ in navigateToDismissCalled = true },
            showAlert: { _ in },
            hideLoadingOverlay: {},
        )
        await subject.navigateToPremiumUpgrade()

        statusSubject.send(.syncing)
        // Yield to let the `.receive(on: DispatchQueue.main)` dispatch run.
        await Task.yield()

        #expect(!navigateToDismissCalled)
    }
}
