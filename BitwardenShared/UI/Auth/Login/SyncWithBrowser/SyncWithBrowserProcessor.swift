import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - SyncWithBrowserProcessorDelegate

/// A delegate for the `SyncWithBrowserProcessor` to communicate events back to the coordinator.
///
@MainActor
protocol SyncWithBrowserProcessorDelegate: AnyObject {
    /// Dismiss the view and execute an action, if any.
    ///
    /// - Parameter action: The action to execute after this function runs, if any.
    ///
    func dismiss(action: DismissAction?)

    /// Starts a web authentication session for the SSO cookie acquisition flow and awaits its result.
    ///
    /// - Parameter url: The URL to open in the web authentication session.
    /// - Returns: The callback URL after the session completes, or `nil` if cancelled or errored.
    ///
    func performWebAuthSession(url: URL) async -> URL?
}

// MARK: - SyncWithBrowserProcessor

/// The processor used to manage state and handle actions for the SSO sync error screen.
///
final class SyncWithBrowserProcessor: StateProcessor<
    SyncWithBrowserState,
    SyncWithBrowserAction,
    SyncWithBrowserEffect,
> {
    // MARK: Types

    typealias Services = HasEnvironmentService
        & HasErrorReporter
        & HasServerCommunicationConfigAPIService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<GlobalModalRoute, Void>

    /// The delegate to notify of events.
    private weak var delegate: SyncWithBrowserProcessorDelegate?

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `SyncWithBrowserProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate to notify of events.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<GlobalModalRoute, Void>,
        delegate: SyncWithBrowserProcessorDelegate?,
        services: Services,
        state: SyncWithBrowserState,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SyncWithBrowserEffect) async {
        switch effect {
        case .appeared:
            loadEnvironmentUrl()
        case .launchBrowserTapped:
            let callbackURL = await delegate?.performWebAuthSession(
                url: services.environmentService.proxyCookieRedirectConnectorURL,
            )

            // Dismiss the modal first; deliver cookies via the DismissAction so the origin
            // view/processor receives the result after the sheet is gone.
            delegate?.dismiss(action: DismissAction {
                Task {
                    // In certain scenarios, we need to wait a bit for the animation of the
                    // view to get dismissed ends before calling the callback so the original
                    // request's alert is shown at the right time.
                    try? await Task.sleep(nanoseconds: 300_000_000)

                    await self.services.serverCommunicationConfigAPIService.cookiesAcquired(
                        from: callbackURL,
                    )
                }
            })
        }
    }

    override func receive(_ action: SyncWithBrowserAction) {
        switch action {
        case .continueWithoutSyncingTapped:
            delegate?.dismiss(action: DismissAction {
                // Deliver nil cookies after the modal is dismissed so the proper dialog alert
                // can be presented to the user from the origin view/processor.
                Task {
                    await self.services.serverCommunicationConfigAPIService.cookiesAcquired(
                        from: nil,
                    )
                }
            })
        }
    }

    // MARK: Private methods

    /// Loads the environment URL.
    func loadEnvironmentUrl() {
        state.environmentUrl = services.environmentService.webVaultURL.absoluteString
    }
}
