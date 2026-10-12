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

    /// The route to the Premium upgrade complete screen.
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

// MARK: - PremiumUpgradeHelper

/// A helper that centralizes the Premium upgrade navigation flow.
///
protocol PremiumUpgradeHelper { // sourcery: AutoMockable
    /// Navigates to the Premium upgrade screen. Shows the upgrade pending alert instead if an upgrade
    /// is already pending, or opens the web vault upgrade URL if in-app upgrade isn't available.
    ///
    /// - Parameters:
    ///   - onConfirmed: An optional closure called when the upgrade is confirmed.
    ///
    func navigateToPremiumUpgrade(onConfirmed: (() async -> Void)?) async

    /// Subscribes to checkout status, then navigates to the Premium upgrade screen. Shows the upgrade
    /// pending alert without subscribing instead if an upgrade is already pending. Skips the
    /// availability check, so use when availability is already known (e.g., action card tap).
    ///
    /// - Parameters:
    ///   - onConfirmed: An optional closure called when the upgrade is confirmed.
    ///
    func startInAppPremiumUpgrade(onConfirmed: (() async -> Void)?) async
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

    /// The coordinator used for navigation.
    private let coordinator: any Coordinator<Route, Event>

    /// Whether a pending check started by `startInAppPremiumUpgrade(onConfirmed:)` is in flight.
    private var isResolvingStartRequest = false

    /// Whether the current subscription opened the Premium upgrade screen and no `.pending` status
    /// has dismissed it since.
    private var isShowingUpgradeScreen = false

    /// An optional closure called inside the pending dismiss action before showing the upgrade
    /// pending alert. Use to hide action cards or perform other per-screen cleanup.
    private let onPendingDismiss: (() -> Void)?

    /// A cancellable for the Premium checkout status subscription.
    private var premiumStatusChangedCancellable: AnyCancellable?

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
        await startInAppPremiumUpgrade(onConfirmed: onConfirmed)
    }

    func startInAppPremiumUpgrade(onConfirmed: (() async -> Void)? = nil) async {
        guard !isResolvingStartRequest else { return }
        isResolvingStartRequest = true
        defer { isResolvingStartRequest = false }
        guard await services.billingService.premiumUpgradeLifecycleState() != .pending else {
            showUpgradePendingAlert(onConfirmed: onConfirmed)
            return
        }
        subscribeToPremiumCheckoutStatus(onConfirmed: onConfirmed)
        isShowingUpgradeScreen = true
        coordinator.navigate(to: .premiumUpgrade)
    }

    // MARK: Private Methods

    /// Cancels the checkout status subscription and calls `onPendingDismiss`, then shows the
    /// upgrade pending alert. "Sync Now" subscribes to checkout status again, then calls
    /// `retryPendingUpgrade()`.
    ///
    /// - Parameters:
    ///   - onConfirmed: An optional closure called when a retry confirms the upgrade.
    ///
    private func showUpgradePendingAlert(onConfirmed: (() async -> Void)?) {
        premiumStatusChangedCancellable = nil
        onPendingDismiss?()
        coordinator.showAlert(.upgradePending { [weak self] in
            guard let self else { return }
            subscribeToPremiumCheckoutStatus(onConfirmed: onConfirmed)
            await services.billingService.retryPendingUpgrade()
        })
    }

    /// Subscribes to checkout status updates. On `.confirmed`, shows the Premium upgrade complete
    /// screen if the upgrade screen isn't showing, then calls `onConfirmed`. On `.pending`,
    /// dismisses the upgrade screen if it's showing, then shows the upgrade pending alert.
    ///
    /// - Parameters:
    ///   - onConfirmed: An optional closure called when the upgrade is confirmed.
    ///
    private func subscribeToPremiumCheckoutStatus(onConfirmed: (() async -> Void)?) {
        isShowingUpgradeScreen = false
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
                    if !isShowingUpgradeScreen {
                        coordinator.navigate(to: .premiumUpgradeComplete)
                    }
                    if let onConfirmed {
                        Task { @MainActor in await onConfirmed() }
                    }
                case .pending:
                    guard isShowingUpgradeScreen else {
                        showUpgradePendingAlert(onConfirmed: onConfirmed)
                        return
                    }
                    isShowingUpgradeScreen = false
                    coordinator.navigate(to: .dismiss(DismissAction { [weak self] in
                        guard let self else { return }
                        coordinator.hideLoadingOverlay()
                        showUpgradePendingAlert(onConfirmed: onConfirmed)
                    }))
                case .syncing:
                    // PremiumUpgradeProcessor shows the loading overlay on the upgrade screen.
                    break
                }
            }
    }
}
