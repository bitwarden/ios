import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - SsoSyncErrorProcessorDelegate

/// A delegate for the `SsoSyncErrorProcessor` to communicate events back to the coordinator.
///
@MainActor
protocol SsoSyncErrorProcessorDelegate: AnyObject {
    /// Dismiss the view and execute an action, if any.
    ///
    /// - Parameter action: The action to execute after this function runs, if any.
    ///
    func dismiss(action: DismissAction?)
}

// MARK: - SsoSyncErrorProcessor

/// The processor used to manage state and handle actions for the SSO sync error screen.
///
final class SsoSyncErrorProcessor: StateProcessor<
    SsoSyncErrorState,
    SsoSyncErrorAction,
    SsoSyncErrorEffect,
> {
    // MARK: Types

    typealias Services = HasEnvironmentService
        & HasErrorReporter
        & HasServerCommunicationConfigAPIService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<GlobalModalRoute, Void>

    /// The delegate to notify of events.
    private weak var delegate: SsoSyncErrorProcessorDelegate?

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `SsoSyncErrorProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate to notify of events.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<GlobalModalRoute, Void>,
        delegate: SsoSyncErrorProcessorDelegate?,
        services: Services,
        state: SsoSyncErrorState,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SsoSyncErrorEffect) async {
        switch effect {
        case .appeared:
            loadEnvironmentUrl()
        case .launchBrowserTapped:
            state.url = services.environmentService.proxyCookieRedirectConnectorURL
            delegate?.dismiss(action: nil)
        }
    }

    override func receive(_ action: SsoSyncErrorAction) {
        switch action {
        case .clearURL:
            state.url = nil
        case .continueWithoutSyncingTapped:
            delegate?.dismiss(action: DismissAction {
                // we need to set the cookies acquired to `nil` to cancel the acquisition after the view is
                // dismissed so the proper dialog alert can be presented to the user
                // from the origin view/processor.
                Task {
                    await self.services.serverCommunicationConfigAPIService.cookiesAcquired(
                        cookies: .success(nil),
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
