import AuthenticationServices
import BitwardenKit
import Foundation

/// A coordinator that manages navigation for global modals.
///
public final class GlobalModalCoordinator: NSObject, Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasAuthService
        & HasConfigService
        & HasEnvironmentService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasServerCommunicationConfigAPIService

    // MARK: Private Properties

    /// The services used by this coordinator.
    private let services: Services

    /// The active web authentication session, retained to prevent premature deallocation.
    private var webAuthSession: ASWebAuthenticationSession?

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    public private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `GlobalModalCoordinator`.
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

    public func navigate(
        to route: GlobalModalRoute,
        context: AnyObject?,
    ) {
        switch route {
        case let .dismissWithAction(onDismiss):
            // PM-34062 Sometimes it doesn't get dismissed because it tries to do it before coming back
            // from the browser to the view. So we wait a bit here and execute this on
            // main thread to handle the edge case.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.stackNavigator?.dismiss(animated: true, completion: {
                    onDismiss?.action()
                })
            }
        case .syncWithBrowser:
            showSyncWithBrowser()
        }
    }

    /// Starts the coordinator.
    public func start() {}

    // MARK: Private Methods

    /// Configures and displays the sync with browser screen.
    private func showSyncWithBrowser() {
        let processor = SyncWithBrowserProcessor(
            coordinator: asAnyCoordinator(),
            delegate: self,
            services: services,
            state: SyncWithBrowserState(),
        )

        let view = SyncWithBrowserView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}

// MARK: - HasErrorAlertServices

extension GlobalModalCoordinator: HasErrorAlertServices {
    public var errorAlertServices: ErrorAlertServices { services }
}

// MARK: - SyncWithBrowserProcessorDelegate

extension GlobalModalCoordinator: SyncWithBrowserProcessorDelegate {
    func dismiss(action: DismissAction?) {
        navigate(to: .dismissWithAction(action))
    }

    func performWebAuthSession(url: URL) async -> URL? {
        await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: services.authService.callbackUrlScheme,
            ) { [weak self] callbackURL, _ in
                // Any error (including user cancellation) is treated as nil — no cookies acquired.
                self?.webAuthSession = nil
                continuation.resume(returning: callbackURL)
            }
            // Keep the shared Safari session so existing SSO cookies are visible.
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            webAuthSession = session
            session.start()
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension GlobalModalCoordinator: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        stackNavigator?.rootViewController?.view.window ?? UIWindow()
    }
}
