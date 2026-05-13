import BitwardenKit
import BitwardenResources
import Combine
import Foundation

// MARK: - PremiumUpgradeHelper

/// A helper that centralizes the premium upgrade navigation flow.
///
protocol PremiumUpgradeHelper { // sourcery: AutoMockable
    /// Checks if in-app upgrade is available and navigates accordingly: to the upgrade screen
    /// if available, or opens the web vault upgrade URL as a fallback.
    ///
    /// - Parameter onConfirmed: An optional closure called when the upgrade is confirmed.
    ///
    func navigateToPremiumUpgrade(onConfirmed: (() async -> Void)?) async

    /// Subscribes to checkout status and navigates directly to the premium upgrade screen,
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
class DefaultPremiumUpgradeHelper: PremiumUpgradeHelper {
    // MARK: Types

    typealias Services = HasBillingRepository
        & HasBillingService
        & HasEnvironmentService

    // MARK: Private Properties

    /// A cancellable for the premium checkout status subscription.
    private var premiumStatusChangedCancellable: AnyCancellable?

    /// A closure called to hide the loading overlay.
    private let hideLoadingOverlay: () -> Void

    /// A closure called to navigate to a dismiss route.
    private let navigateToDismiss: (DismissAction) -> Void

    /// A closure called to navigate to the premium upgrade screen.
    private let navigateToPremiumRoute: () -> Void

    /// An optional closure called inside the pending dismiss action before showing the upgrade
    /// pending alert. Use to dismiss action cards or perform other per-screen cleanup.
    private let onPendingDismiss: (() -> Void)?

    /// The services used by this helper.
    private let services: Services

    /// A closure called to open a URL (used for the web-based upgrade fallback).
    private let setURL: (URL) -> Void

    /// A closure called to show an alert.
    private let showAlert: (Alert) -> Void

    // MARK: Initialization

    /// Creates a new `DefaultPremiumUpgradeHelper`.
    ///
    /// - Parameters:
    ///   - services: The services used by this helper.
    ///   - navigateToPremiumRoute: Navigates to the premium upgrade screen.
    ///   - setURL: Opens a URL (used for the web-based upgrade fallback).
    ///   - navigateToDismiss: Navigates to a dismiss route with an action.
    ///   - showAlert: Shows an alert.
    ///   - hideLoadingOverlay: Hides the loading overlay.
    ///   - onPendingDismiss: Called when a pending upgrade is dismissed, before the pending alert.
    ///
    init(
        services: Services,
        navigateToPremiumRoute: @escaping () -> Void,
        setURL: @escaping (URL) -> Void,
        navigateToDismiss: @escaping (DismissAction) -> Void,
        showAlert: @escaping (Alert) -> Void,
        hideLoadingOverlay: @escaping () -> Void,
        onPendingDismiss: (() -> Void)? = nil,
    ) {
        self.services = services
        self.navigateToPremiumRoute = navigateToPremiumRoute
        self.setURL = setURL
        self.navigateToDismiss = navigateToDismiss
        self.showAlert = showAlert
        self.hideLoadingOverlay = hideLoadingOverlay
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
        navigateToPremiumRoute()
    }

    // MARK: Private Methods

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
                        Task { await onConfirmed() }
                    }
                case .pending:
                    navigateToDismiss(DismissAction { [weak self] in
                        guard let self else { return }
                        hideLoadingOverlay()
                        onPendingDismiss?()
                        showAlert(.upgradePending {
                            await self.services.billingService.premiumStatusChanged()
                        })
                    })
                case .syncing:
                    // PremiumUpgradeProcessor shows the loading overlay on the upgrade screen.
                    break
                }
            }
    }
}
