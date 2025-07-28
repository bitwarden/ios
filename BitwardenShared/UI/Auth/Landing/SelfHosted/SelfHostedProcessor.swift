import BitwardenKit
import BitwardenResources
import Foundation

/// A delegate of `SelfHostedProcessor` that is notified when the user saves their environment settings.
///
protocol SelfHostedProcessorDelegate: AnyObject {
    /// Called when the user saves their environment settings.
    ///
    /// - Parameter urls: The URLs that the user specified for their environment.
    ///
    func didSaveEnvironment(urls: EnvironmentURLData) async
}

// MARK: - SelfHostedProcessor

/// The processor used to manage state and handle actions for the self-hosted screen.
///
final class SelfHostedProcessor: StateProcessor<SelfHostedState, SelfHostedAction, SelfHostedEffect> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The delegate for the processor that is notified when the user saves their environment settings.
    private weak var delegate: SelfHostedProcessorDelegate?

    // MARK: Initialization

    /// Initializes a `SelfHostedProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate for the processor that is notified when the user saves their
    ///     environment settings.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        delegate: SelfHostedProcessorDelegate?,
        state: SelfHostedState
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SelfHostedEffect) async {
        switch effect {
        case .saveEnvironment:
            await saveEnvironment()
        }
    }

    override func receive(_ action: SelfHostedAction) {
        switch action {
        case let .apiUrlChanged(url):
            state.apiServerUrl = url
        case .dismiss:
            coordinator.navigate(to: .dismissPresented)
        case let .iconsUrlChanged(url):
            state.iconsServerUrl = url
        case let .identityUrlChanged(url):
            state.identityServerUrl = url
        case let .serverUrlChanged(url):
            state.serverUrl = url
        case let .webVaultUrlChanged(url):
            state.webVaultServerUrl = url
        }
    }

    // MARK: Private

    /// Returns whether all of the entered URLs are valid URLs.
    ///
    private func areURLsValid() -> Bool {
        let urls = [
            state.apiServerUrl,
            state.iconsServerUrl,
            state.identityServerUrl,
            state.serverUrl,
            state.webVaultServerUrl,
        ]

        return urls
            .filter { !$0.isEmpty }
            .allSatisfy(\.isValidURL)
    }

    /// Saves the environment URLs if they are valid or presents an alert if any are invalid.
    private func saveEnvironment() async {
        guard areURLsValid() else {
            coordinator.showAlert(Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.environmentPageUrlsError
            ))
            return
        }

        let urls = EnvironmentURLData(
            api: URL(string: state.apiServerUrl)?.sanitized,
            base: URL(string: state.serverUrl)?.sanitized,
            events: nil,
            icons: URL(string: state.iconsServerUrl)?.sanitized,
            identity: URL(string: state.identityServerUrl)?.sanitized,
            notifications: nil,
            webVault: URL(string: state.webVaultServerUrl)?.sanitized
        )
        await delegate?.didSaveEnvironment(urls: urls)
        coordinator.navigate(to: .dismissPresented)
    }
}
