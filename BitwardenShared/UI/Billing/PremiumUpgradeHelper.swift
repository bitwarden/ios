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
    /// Calls `retry`, then, if the pending upgrade resolved successfully (no longer pending, and
    /// the retry itself didn't fail), navigates to the standalone Premium upgrade complete
    /// screen. A still-pending (not yet Premium) or still-failed outcome gets no further UI
    /// here — the CTA and the "Sync unsuccessful" alert already react to those independently via
    /// the durable `premiumUpgradePendingStatePublisher()` signal.
    ///
    /// - Parameters:
    ///   - billingService: The service used to check the resulting state after `retry` runs.
    ///   - coordinator: The coordinator to navigate on success.
    ///   - retry: The retry action to perform — `reconcileCheckoutSuccess()` for the "Sync Now"
    ///     alert, `premiumStatusChanged()` for the "Sync unsuccessful" alert's "Try Again".
    ///
    @MainActor
    static func retryAndShowCompleteIfResolved<Route: PremiumUpgradeRoute, Event>(
        billingService: BillingService,
        coordinator: any Coordinator<Route, Event>,
        retry: () async -> Void,
    ) async {
        await retry()
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
        // Set before the `await` below, not after: `subscribeToPremiumCheckoutStatus(onConfirmed:)`
        // attaches the new live subscription synchronously, right now — if a status arrived in the
        // gap before the pending-state check resolves, its handler would otherwise judge it
        // against the previous call's leftover value instead of "haven't navigated yet."
        navigatedToUpgradeScreen = false
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
            showUpgradePendingAlert()
        }
    }

    // MARK: Private Methods

    /// Calls `onPendingDismiss`, then shows the upgrade pending alert with "Sync Now" wired to
    /// `reconcileCheckoutSuccess()` — navigating to the standalone Premium upgrade complete
    /// screen if the retry actually resolves the upgrade. A still-pending (not yet Premium) or
    /// still-failed outcome gets no further UI here: the CTA and the "Sync unsuccessful" alert
    /// already react to those independently via the durable `premiumUpgradePendingStatePublisher()`
    /// signal.
    ///
    private func showUpgradePendingAlert() {
        onPendingDismiss?()
        coordinator.showAlert(.upgradePending { [weak self] in
            guard let self else { return }
            await PremiumUpgradeRetry.retryAndShowCompleteIfResolved(
                billingService: services.billingService,
                coordinator: coordinator,
            ) {
                await self.services.billingService.reconcileCheckoutSuccess()
            }
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
                    // Consume the flag: the screen this refers to is about to be dismissed, so a
                    // later `.pending` (e.g. a "Sync Now" retry that also doesn't confirm) must
                    // not dismiss it a second time.
                    navigatedToUpgradeScreen = false
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
