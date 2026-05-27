import AuthenticationServices
import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - BillingCoordinator

/// A coordinator that manages navigation for billing-related views.
///
class BillingCoordinator: NSObject, Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasBillingService
        & HasEnvironmentService
        & HasErrorReportBuilder
        & HasErrorReporter

    // MARK: Properties

    /// Whether PremiumUpgrade was opened as the root of a modal navController (vault/archive context).
    /// Determines the close behavior of PremiumUpgradeComplete.
    private var isUpgradeAsModalRoot = false

    /// The active web authentication session for the Stripe checkout flow.
    private var webAuthSession: ASWebAuthenticationSession?

    /// Closure invoked after PremiumUpgradeComplete is dismissed.
    private var premiumUpgradeCompleteOnClose: (() -> Void)?

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `BillingCoordinator`.
    ///
    /// - Parameters:
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: BillingRoute, context: AnyObject?) {
        switch route {
        case .dismiss:
            if stackNavigator?.isPresenting == true {
                let onClose = premiumUpgradeCompleteOnClose
                premiumUpgradeCompleteOnClose = nil
                stackNavigator?.dismiss(completion: onClose)
            } else if stackNavigator?.pop() == nil {
                stackNavigator?.dismiss()
            }
        case .premiumUpgradeComplete:
            showPremiumUpgradeComplete()
        case .premiumPlan:
            showPremiumPlan()
        case .premiumUpgrade:
            showPremiumUpgrade()
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Shows the premium upgrade complete screen.
    ///
    private func showPremiumUpgradeComplete() {
        premiumUpgradeCompleteOnClose = isUpgradeAsModalRoot
            ? { [weak self] in self?.stackNavigator?.dismiss() }
            : { [weak self] in
                // Pop PremiumUpgradeView silently so back navigation from PremiumPlanView
                // returns to Settings, not to the (now-irrelevant) upgrade screen.
                self?.stackNavigator?.pop(animated: false)
                self?.showPremiumPlan()
            }
        let processor = PremiumUpgradeCompleteProcessor(coordinator: asAnyCoordinator())
        let view = PremiumUpgradeCompleteView(store: Store(processor: processor))
        stackNavigator?.present(view)
    }

    /// Shows the premium plan screen.
    ///
    private func showPremiumPlan() {
        let processor = PremiumPlanProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: PremiumPlanState(),
        )
        let view = PremiumPlanView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator?.push(viewController, navigationTitle: Localizations.plan)
    }

    /// Shows the premium upgrade screen.
    ///
    private func showPremiumUpgrade() {
        let shouldReplaceStack = stackNavigator?.isEmpty == true
        isUpgradeAsModalRoot = shouldReplaceStack
        var state = PremiumUpgradeState()
        state.showCancelButton = shouldReplaceStack
        let processor = PremiumUpgradeProcessor(
            coordinator: asAnyCoordinator(),
            delegate: self,
            services: services,
            state: state,
        )
        let view = PremiumUpgradeView(store: Store(processor: processor))
        if shouldReplaceStack {
            stackNavigator?.replace(view)
        } else {
            let viewController = UIHostingController(rootView: view)
            viewController.navigationItem.largeTitleDisplayMode = .never
            stackNavigator?.push(viewController, navigationTitle: Localizations.upgradeToPremium)
        }
    }
}

// MARK: - HasErrorAlertServices

extension BillingCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}

// MARK: - PremiumUpgradeProcessorDelegate

extension BillingCoordinator: PremiumUpgradeProcessorDelegate {
    func performCheckoutWebAuthSession(url: URL) async -> CheckoutWebAuthSessionOutcome {
        await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: services.billingService.checkoutCallbackUrlScheme,
            ) { [weak self] callbackURL, _ in
                self?.webAuthSession = nil
                if let callbackURL {
                    continuation.resume(returning: .completed(callbackURL: callbackURL))
                } else {
                    continuation.resume(returning: .canceled)
                }
            }
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            webAuthSession = session
            session.start()
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension BillingCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        stackNavigator?.rootViewController?.view.window ?? UIWindow()
    }
}
