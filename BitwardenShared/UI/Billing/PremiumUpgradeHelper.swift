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

    /// Whether `startInAppPremiumUpgrade(onConfirmed:)` navigated to the Premium upgrade screen
    /// for the checkout status subscription currently live in `premiumStatusChangedCancellable`.
    /// `false` when it instead found an upgrade already pending and showed the pending alert
    /// directly without navigating anywhere — in that case, a later `.pending` emission (e.g.
    /// from tapping "Sync Now" and the retry not confirming either) must not try to dismiss a
    /// screen that was never opened.
    private var navigatedToUpgradeScreen = false

    /// Whether a `startInAppPremiumUpgrade(onConfirmed:)` call's pending-state check is currently
    /// in flight. Unlike the old, synchronous "check availability then navigate immediately"
    /// call, this now awaits a storage read before deciding, opening a real (if brief) window for
    /// a rapid double-tap on the same entry point to fire two overlapping checks — each of which
    /// would otherwise navigate or show the pending alert on its own. Guards against that.
    private var isResolvingStartRequest = false

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
        guard !isResolvingStartRequest else { return }
        isResolvingStartRequest = true
        subscribeToPremiumCheckoutStatus(onConfirmed: onConfirmed)
        Task { [weak self] in
            guard let self else { return }
            defer { isResolvingStartRequest = false }
            // Checked here, not just left to each caller's own CTA visibility (e.g. the Vault
            // tab's action card, hidden while pending): a pending upgrade doesn't stop any of
            // the other eight entry points into this flow (Settings > Plan, Send, item views,
            // etc.) from starting a second, redundant checkout. Intercepting at this single,
            // shared choke point closes all of them at once instead of gating each separately.
            guard await services.billingService.premiumUpgradePendingState().isPending else {
                navigatedToUpgradeScreen = true
                coordinator.navigate(to: .premiumUpgrade)
                return
            }
            navigatedToUpgradeScreen = false
            showUpgradePendingAlert()
        }
    }

    // MARK: Private Methods

    /// Calls `onPendingDismiss`, then shows the upgrade pending alert with "Sync Now" wired to
    /// `reconcileCheckoutSuccess()`.
    ///
    private func showUpgradePendingAlert() {
        onPendingDismiss?()
        coordinator.showAlert(.upgradePending { [weak self] in
            await self?.services.billingService.reconcileCheckoutSuccess()
        })
    }

    /// Subscribes to checkout status updates. On `.confirmed`, calls `onConfirmed`.
    /// On `.pending`, dismisses the Premium upgrade screen first if one was navigated to for
    /// this subscription, then shows the upgrade pending alert.
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
                    guard navigatedToUpgradeScreen else {
                        showUpgradePendingAlert()
                        return
                    }
                    coordinator.navigate(to: .dismiss(DismissAction { [weak self] in
                        guard let self else { return }
                        coordinator.hideLoadingOverlay()
                        showUpgradePendingAlert()
                    }))
                case .syncing:
                    // PremiumUpgradeProcessor shows the loading overlay on the upgrade screen.
                    break
                }
            }
    }
}
