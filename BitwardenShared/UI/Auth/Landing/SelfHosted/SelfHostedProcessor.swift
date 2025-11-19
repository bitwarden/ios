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

/// The processor used to manage state and handle actions for the self-hosted environment configuration.
///
class SelfHostedProcessor: StateProcessor<SelfHostedState, SelfHostedAction, SelfHostedEffect> {
    // MARK: Types

    typealias Services = HasClientCertificateService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The delegate for the processor that is notified when the user saves their environment settings.
    private weak var delegate: SelfHostedProcessorDelegate?

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a `SelfHostedProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate for the processor that is notified when the user saves their
    ///     environment settings.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        delegate: SelfHostedProcessorDelegate?,
        services: Services,
        state: SelfHostedState,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SelfHostedEffect) async {
        switch effect {
        case .saveEnvironment:
            await saveEnvironment()
        case let .importClientCertificate(data, password):
            await importClientCertificate(data: data, password: password)
        case .importClientCertificateWithPassword:
            await importClientCertificateWithStoredPassword()
        case .removeClientCertificate:
            await removeClientCertificate()
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
        case .clientCertificateConfigureTapped:
            state.isClientCertificateSheetPresented = true
        case .importCertificateTapped:
            state.showingCertificateImporter = true
        case let .certificateFileSelected(result):
            state.showingCertificateImporter = false
            handleCertificateFileSelection(result)
        case let .certificatePasswordChanged(password):
            state.certificatePassword = password
        case .dismissCertificateImporter:
            state.showingCertificateImporter = false
        case .dismissPasswordPrompt:
            state.showingPasswordPrompt = false
            state.certificatePassword = ""
            state.pendingCertificateData = nil
        case .confirmCertificatePassword:
            Task { await perform(.importClientCertificateWithPassword) }
        case .removeCertificate:
            Task { await perform(.removeClientCertificate) }
        case .clientCertificateSheetDismissed:
            state.isClientCertificateSheetPresented = false
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
                message: Localizations.environmentPageUrlsError,
            ))
            return
        }

        let urls = EnvironmentURLData(
            api: URL(string: state.apiServerUrl)?.sanitized,
            base: URL(string: state.serverUrl)?.sanitized,
            events: nil as URL?,
            icons: URL(string: state.iconsServerUrl)?.sanitized,
            identity: URL(string: state.identityServerUrl)?.sanitized,
            notifications: nil,
            webVault: URL(string: state.webVaultServerUrl)?.sanitized,
        )
        await delegate?.didSaveEnvironment(urls: urls)
        coordinator.navigate(to: .dismissPresented)
    }

    /// Imports a client certificate from the provided data and password.
    ///
    /// - Parameters:
    ///   - data: The certificate data in PKCS#12 format.
    ///   - password: The password for the certificate.
    ///
    private func importClientCertificate(data: Data, password: String) async {
        do {
            let configuration = try await services.clientCertificateService.importCertificate(
                data: data,
                password: password
            )
            state.clientCertificateConfiguration = configuration
            coordinator.showAlert(Alert.defaultAlert(
                title: "Success",
                message: "Client certificate imported successfully."
            ))
        } catch {
            coordinator.showAlert(Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: error.localizedDescription
            ))
        }
    }

    /// Imports the certificate using the stored certificate data and user-entered password.
    ///
    private func importClientCertificateWithStoredPassword() async {
        guard let data = state.pendingCertificateData else {
            coordinator.showAlert(Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: "No certificate data available."
            ))
            return
        }

        do {
            let configuration = try await services.clientCertificateService.importCertificate(
                data: data,
                password: state.certificatePassword
            )

            // Success - update state and clean up
            state.clientCertificateConfiguration = configuration
            state.showingPasswordPrompt = false
            state.certificatePassword = ""
            state.pendingCertificateData = nil

            coordinator.showAlert(Alert.defaultAlert(
                title: "Success",
                message: "Client certificate imported successfully."
            ))
        } catch {
            coordinator.showAlert(Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: "Failed to import certificate: \(error.localizedDescription)"
            ))
        }
    }

    /// Removes the current client certificate.
    ///
    private func removeClientCertificate() async {
        do {
            try await services.clientCertificateService.removeCertificate()
            state.clientCertificateConfiguration = .disabled
            coordinator.showAlert(Alert.defaultAlert(
                title: "Success",
                message: "Client certificate removed successfully."
            ))
        } catch {
            coordinator.showAlert(Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: error.localizedDescription
            ))
        }
    }

    /// Handles the certificate file selection result.
    ///
    /// - Parameter result: The result of file selection.
    ///
    private func handleCertificateFileSelection(_ result: Result<URL, Error>) {
        switch result {
        case let .success(url):
            // Try to read the file and prompt for password if needed
            do {
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                // Try importing with empty password first
                Task {
                    do {
                        let configuration = try await services.clientCertificateService.importCertificate(
                            data: data,
                            password: ""
                        )
                        state.clientCertificateConfiguration = configuration
                        coordinator.showAlert(Alert.defaultAlert(
                            title: "Success",
                            message: "Client certificate imported successfully."
                        ))
                    } catch {
                        // If it fails, we likely need a password
                        state.pendingCertificateData = data
                        state.showingPasswordPrompt = true
                    }
                }
            } catch {
                coordinator.showAlert(Alert.defaultAlert(
                    title: Localizations.anErrorHasOccurred,
                    message: "Failed to read certificate file: \(error.localizedDescription)"
                ))
            }
        case let .failure(error):
            coordinator.showAlert(Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: "Failed to select certificate: \(error.localizedDescription)"
            ))
        }
    }
}
