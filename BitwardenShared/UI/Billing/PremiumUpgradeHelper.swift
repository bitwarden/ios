import BitwardenKit
import BitwardenResources
import Combine
import Foundation

// MARK: - PremiumUpgradeRoute

/// A route type that supports Premium upgrade navigation.
///
protocol PremiumUpgradeRoute {
    /// The route to the Premium upgrade screen.
    static var premiumUpgrade: Self { get }

    /// The route to a standalone Premium upgrade complete screen, shown when an upgrade
    /// resolves outside of the upgrade screen itself (e.g. a "Sync Now" retry succeeding after
    /// the upgrade screen has already been dismissed).
    static var premiumUpgradeComplete: Self { get }

    /// The route to dismiss the current screen with an optional action.
    ///
    /// - Parameter action: The action to perform on dismiss.
    ///
    static func dismiss(_ action: DismissAction?) -> Self
}

extension SendItemRoute: PremiumUpgradeRoute {}
extension SendRoute: PremiumUpgradeRoute {}
extension SettingsRoute: PremiumUpgradeRoute {}
extension VaultItemRoute: PremiumUpgradeRoute {}
extension VaultRoute: PremiumUpgradeRoute {}

// MARK: - PremiumUpgradeRetry

/// Shared logic for the two explicit, user-initiated "retry the pending upgrade's sync" entry
/// points — the "Sync Now" button on the upgrade pending alert, and "Try Again" on the "Sync
/// unsuccessful" alert — so both react identically to the retry actually resolving the upgrade.
///
enum PremiumUpgradeRetry {
    /// Calls `premiumStatusChanged()` and, if the pending upgrade resolved successfully (no
    /// longer pending, and the retry itself didn't fail), navigates to the standalone Premium
    /// upgrade complete screen. A still-pending (not yet Premium) or still-failed outcome gets
    /// no further UI here — the CTA and the "Sync unsuccessful" alert already react to those
    /// independently via the durable `premiumUpgradePendingStatePublisher()` signal.
    ///
    /// - Parameters:
    ///   - billingService: The service used to retry the sync and check the resulting state.
    ///   - coordinator: The coordinator to navigate on success.
    ///
    @MainActor
    static func retryAndShowCompleteIfResolved<Route: PremiumUpgradeRoute, Event>(
        billingService: BillingService,
        coordinator: any Coordinator<Route, Event>,
    ) async {
        await billingService.premiumStatusChanged()
        let state = await billingService.premiumUpgradePendingState()
        if !state.isPending, !state.lastAttemptFailed {
            coordinator.navigate(to: .premiumUpgradeComplete)
        }
    }
}

// MARK: - PremiumUpgradeHelper

/// A helper that centralizes the Premium upgrade navigation flow.
///
protocol PremiumUpgradeHelper { // sourcery: AutoMockable
    /// Checks if in-app upgrade is available and navigates accordingly: to the upgrade screen
    /// if available, or opens the web vault upgrade URL as a fallback.
    ///
    /// - Parameter onConfirmed: An optional closure called when the upgrade is confirmed.
    ///
    func navigateToPremiumUpgrade(onConfirmed: (() async -> Void)?) async

    /// Subscribes to checkout status and navigates directly to the Premium upgrade screen,
    /// skipping the availability check. Use when availability is already known (e.g., action card tap).
    ///
    /// - Parameter onConfirmed: An optional closure called when the upgrade is confirmed.
    ///
    func startInAppPremiumUpgrade(onConfirmed: (() async -> Void)?)
}

extension PremiumUpgradeHelper {
    /// Convenience overload that passes no `onConfirmed` callback.
    func navigateToPremiumUpgrade() async {
        await navigateToPremiumUpgrade(onConfirmed: nil)
    }
}

// MARK: - DefaultPremiumUpgradeHelper

/// The default implementation of `PremiumUpgradeHelper`.
///
@MainActor
class DefaultPremiumUpgradeHelper<Route: PremiumUpgradeRoute, Event>: PremiumUpgradeHelper {
    // MARK: Types

    typealias Services = HasBillingRepository
        & HasBillingService
        & HasEnvironmentService

    // MARK: Private Properties

    /// A cancellable for the Premium checkout status subscription.
    private var premiumStatusChangedCancellable: AnyCancellable?

    /// The coordinator used for navigation.
    private let coordinator: any Coordinator<Route, Event>

    /// An optional closure called inside the pending dismiss action before showing the upgrade
    /// pending alert. Use to dismiss action cards or perform other per-screen cleanup.
    private let onPendingDismiss: (() -> Void)?

    /// The services used by this helper.
    private let services: Services

    /// A closure called to open a URL (used for the web-based upgrade fallback).
    private let setURL: (URL) -> Void

    // MARK: Initialization

    /// Creates a new `DefaultPremiumUpgradeHelper`.
    ///
    /// - Parameters:
    ///   - services: The services used by this helper.
    ///   - coordinator: The coordinator used for navigation.
    ///   - setURL: Opens a URL (used for the web-based upgrade fallback).
    ///   - onPendingDismiss: Called when a pending upgrade is dismissed, before the pending alert.
    ///
    init(
        services: Services,
        coordinator: any Coordinator<Route, Event>,
        setURL: @escaping (URL) -> Void,
        onPendingDismiss: (() -> Void)? = nil,
    ) {
        self.services = services
        self.coordinator = coordinator
        self.setURL = setURL
        self.onPendingDismiss = onPendingDismiss
    }

    // MARK: Methods

    func navigateToPremiumUpgrade(onConfirmed: (() async -> Void)? = nil) async {
        guard await services.billingRepository.isInAppUpgradeAvailable() else {
            setURL(services.environmentService.upgradeToPremiumURL)
            return
        }
        startInAppPremiumUpgrade(onConfirmed: onConfirmed)
    }

    func startInAppPremiumUpgrade(onConfirmed: (() async -> Void)? = nil) {
        subscribeToPremiumCheckoutStatus(onConfirmed: onConfirmed)
        coordinator.navigate(to: .premiumUpgrade)
    }

    // MARK: Private Methods

    /// Subscribes to checkout status updates. On `.confirmed`, calls `onConfirmed`.
    /// On `.pending`, navigates to dismiss and shows the upgrade pending alert.
    ///
    /// - Parameter onConfirmed: An optional closure called when the upgrade is confirmed.
    ///
    private func subscribeToPremiumCheckoutStatus(onConfirmed: (() async -> Void)?) {
        premiumStatusChangedCancellable = services.billingService
            .premiumCheckoutStatusPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .canceled:
                    break
                case .confirmed:
                    premiumStatusChangedCancellable = nil
                    if let onConfirmed {
                        Task { @MainActor in await onConfirmed() }
                    }
                case .pending:
                    coordinator.navigate(to: .dismiss(DismissAction { [weak self] in
                        guard let self else { return }
                        coordinator.hideLoadingOverlay()
                        onPendingDismiss?()
                        coordinator.showAlert(.upgradePending { [weak self] in
                            guard let self else { return }
                            await PremiumUpgradeRetry.retryAndShowCompleteIfResolved(
                                billingService: services.billingService,
                                coordinator: coordinator,
                            )
                        })
                    }))
                case .syncing:
                    // PremiumUpgradeProcessor shows the loading overlay on the upgrade screen.
                    break
                }
            }
    }
}
