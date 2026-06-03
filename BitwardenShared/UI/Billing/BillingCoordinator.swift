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
        & HasStateService

    // MARK: Properties

    /// Whether PremiumUpgrade was opened as the root of a modal navController (vault/archive context).
    /// Determines the close behavior of PremiumUpgradeComplete.
    private var isUpgradeAsModalRoot = false

    /// Closure invoked after PremiumUpgradeComplete is dismissed.
    private var premiumUpgradeCompleteOnClose: (() -> Void)?

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    /// The active web authentication session for the Stripe checkout flow.
    private var webAuthSession: ASWebAuthenticationSession?

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
        case let .premiumPlan(subscription):
            showPremiumPlan(subscription: subscription)
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
                self?.showPremiumPlan(subscription: nil)
            }
        let processor = PremiumUpgradeCompleteProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
        )
        let view = PremiumUpgradeCompleteView(store: Store(processor: processor))
        stackNavigator?.present(view)
    }

    /// Shows the premium plan screen.
    ///
    /// - Parameter subscription: An already-fetched subscription; pass `nil` to let the plan screen fetch it.
    ///
    private func showPremiumPlan(subscription: PremiumSubscription?) {
        let state = subscription.map(PremiumPlanState.init(subscription:)) ?? PremiumPlanState()
        let processor = PremiumPlanProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: state,
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
    func performCheckoutWebAuthSession(url: URL) async -> Result<URL, Error> {
        await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: services.billingService.checkoutCallbackUrlScheme,
            ) { [weak self] callbackURL, error in
                self?.webAuthSession = nil
                let result: Result<URL, Error> = if let callbackURL {
                    .success(callbackURL)
                } else if let sessionError = error as? ASWebAuthenticationSessionError,
                          sessionError.code == .canceledLogin {
                    .failure(CancellationError())
                } else {
                    .failure(error ?? CancellationError())
                }
                self?.resumeAfterDismissal(continuation: continuation, outcome: result)
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            webAuthSession = session
            session.start()
        }
    }

    /// Resumes the continuation only after any active sheet dismissal animation completes,
    /// so callers can safely present new UI without UIKit dropping the presentation.
    private func resumeAfterDismissal(
        continuation: CheckedContinuation<Result<URL, Error>, Never>,
        outcome: Result<URL, Error>,
    ) {
        // Traverse from the window root to find the deepest non-dismissing VC —
        // its presentedViewController (the session sheet) is being dismissed.
        var presentingVC = stackNavigator?.rootViewController?.view.window?.rootViewController
        while let child = presentingVC?.presentedViewController, !child.isBeingDismissed {
            presentingVC = child
        }

        if let dismissingVC = presentingVC?.presentedViewController,
           let transitionCoordinator = dismissingVC.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { _ in
                continuation.resume(returning: outcome)
            }
        } else {
            continuation.resume(returning: outcome)
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension BillingCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        stackNavigator?.rootViewController?.view.window ?? UIWindow()
    }
}
