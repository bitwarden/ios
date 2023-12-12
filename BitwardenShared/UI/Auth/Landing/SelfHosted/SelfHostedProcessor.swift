import Foundation

// MARK: - SelfHostedProcessor

/// The processor used to manage state and handle actions for the self-hosted screen.
///
final class SelfHostedProcessor: StateProcessor<SelfHostedState, SelfHostedAction, SelfHostedEffect> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

    // MARK: Initialization

    /// Initializes a `SelfHostedProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(coordinator: AnyCoordinator<AuthRoute>, state: SelfHostedState) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SelfHostedEffect) async {
        switch effect {
        case .saveEnvironment:
            saveEnvironment()
        }
    }

    override func receive(_ action: SelfHostedAction) {
        switch action {
        case let .apiUrlChanged(url):
            state.apiServerUrl = url
        case .dismiss:
            coordinator.navigate(to: .dismiss)
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
    private func saveEnvironment() {
        guard areURLsValid() else {
            coordinator.showAlert(Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.environmentPageUrlsError
            ))
            return
        }

        // TODO: BIT-1062 Save and apply environment

        coordinator.navigate(to: .dismiss)
    }
}
