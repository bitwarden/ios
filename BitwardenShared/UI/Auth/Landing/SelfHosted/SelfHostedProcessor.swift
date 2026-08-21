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
final class SelfHostedProcessor: StateProcessor<SelfHostedState, SelfHostedAction, SelfHostedEffect> {
    // MARK: Types

    typealias Services = HasClientCertificateService
        & HasCustomHeadersService
        & HasErrorReporter

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
        case .appeared:
            await loadCustomHeaders()
        case let .importClientCertificate(data, alias, password):
            await importClientCertificate(data: data, alias: alias, password: password)
        case .removeClientCertificate:
            await removeClientCertificate()
        case .saveEnvironment:
            await saveEnvironment()
        }
    }

    override func receive(_ action: SelfHostedAction) {
        switch action {
        // URL actions
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
        // Custom header actions
        case .addHeaderTapped:
            state.customHeaders.append(SelfHostedState.CustomHeaderField())
        case let .headerNameChanged(id, name):
            guard let index = state.customHeaders.firstIndex(where: { $0.id == id }) else { return }
            state.customHeaders[index].name = name
        case let .headerValueChanged(id, value):
            guard let index = state.customHeaders.firstIndex(where: { $0.id == id }) else { return }
            state.customHeaders[index].value = value
        case let .headerValueVisibilityChanged(id, isVisible):
            guard let index = state.customHeaders.firstIndex(where: { $0.id == id }) else { return }
            state.customHeaders[index].isValueVisible = isVisible
        case let .removeHeaderTapped(id):
            state.customHeaders.removeAll { $0.id == id }
        // Certificate actions
        case .importCertificateTapped:
            state.showingCertificateImporter = true
        case let .certificateFileSelected(result):
            state.showingCertificateImporter = false
            handleCertificateFileSelection(result)
        case let .certificateInfoSubmitted(alias, password):
            handleCertificateInfoSubmitted(alias: alias, password: password)
        case .confirmOverwriteCertificate:
            handleConfirmOverwriteCertificate()
        case .removeCertificateTapped:
            Task { await perform(.removeClientCertificate) }
        case .dismissCertificateImporter:
            state.showingCertificateImporter = false
        case .dialogDismiss:
            state.dialog = nil
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

    /// Loads the stored custom headers into the state for editing.
    ///
    private func loadCustomHeaders() async {
        guard let id = state.customHeadersId.nilIfEmpty, state.customHeaders.isEmpty else { return }
        do {
            let headers = try await services.customHeadersService.getCustomHeaders(id: id)
            state.customHeaders = headers
                .sorted { $0.key < $1.key }
                .map { SelfHostedState.CustomHeaderField(name: $0.key, value: $0.value) }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Handles the result of the certificate file picker.
    ///
    /// On success, reads the file data and presents the alias and password input dialog.
    /// On failure, presents an error dialog.
    ///
    /// - Parameter result: The result of the file selection.
    ///
    private func handleCertificateFileSelection(_ result: Result<URL, Error>) {
        switch result {
        case let .success(url):
            do {
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                state.pendingCertificateData = data
                state.dialog = .setCertificateData(certificateData: data)
            } catch {
                state.dialog = .error(message: Localizations.unableToReadCertificateFile)
            }
        case let .failure(error):
            state.dialog = .error(message: error.localizedDescription)
        }
    }

    /// Handles the user submitting the alias and password from the certificate import dialog.
    ///
    /// Validates that both fields are non-empty, checks for an alias conflict with any existing
    /// certificate, and then proceeds with the import.
    ///
    /// - Parameters:
    ///   - alias: The alias entered by the user.
    ///   - password: The password entered by the user.
    ///
    private func handleCertificateInfoSubmitted(alias: String, password: String) {
        do {
            try EmptyInputValidator(fieldName: Localizations.password).validate(input: password)
            try EmptyInputValidator(fieldName: Localizations.alias).validate(input: alias)
        } catch {
            coordinator.showAlert(.inputValidationAlert(error: error))
            return
        }

        guard let data = state.pendingCertificateData else {
            state.dialog = .error(message: Localizations.noCertificateDataAvailable)
            return
        }

        if !state.keyAlias.isEmpty, state.keyAlias == alias {
            state.dialog = .confirmOverwriteAlias(
                alias: alias,
                certificateData: data,
                password: password,
            )
            return
        }

        state.dialog = nil
        Task {
            await perform(.importClientCertificate(data: data, alias: alias, password: password))
        }
    }

    /// Handles the user confirming they want to overwrite an existing certificate alias.
    ///
    private func handleConfirmOverwriteCertificate() {
        guard case let .confirmOverwriteAlias(alias, certificateData, password) = state.dialog else {
            return
        }

        state.dialog = nil
        Task {
            await perform(.importClientCertificate(data: certificateData, alias: alias, password: password))
        }
    }

    /// Imports a client certificate from the provided data, alias, and password.
    ///
    /// - Parameters:
    ///   - data: The certificate data in PKCS#12 format.
    ///   - alias: The alias to associate with the certificate.
    ///   - password: The password used to decrypt the PKCS#12 data.
    ///
    private func importClientCertificate(data: Data, alias: String, password: String) async {
        do {
            let previousFingerprint = state.keyFingerprint.nilIfEmpty
            let fingerprint = try await services.clientCertificateService.importCertificate(
                data: data,
                password: password,
                alias: alias,
            )
            // If the user replaced a different certificate, clean up the old Keychain item.
            if let previousFingerprint, previousFingerprint != fingerprint {
                do {
                    try await services.clientCertificateService.removeCertificate(fingerprint: previousFingerprint)
                } catch {
                    services.errorReporter.log(error: error)
                }
            }
            state.keyAlias = alias
            state.keyFingerprint = fingerprint
            state.dialog = nil
            state.pendingCertificateData = nil
        } catch let error as ClientCertificateError {
            state.dialog = .error(message: error.localizedDescription)
        } catch {
            state.dialog = .error(message: Localizations.theCertificateCouldNotBeInstalled)
        }
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

        let previousCustomHeadersId = state.customHeadersId.nilIfEmpty
        let customHeadersId: String?
        do {
            customHeadersId = try await saveCustomHeaders()
        } catch {
            coordinator.showAlert(Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: error.localizedDescription,
            ))
            return
        }

        let urls = EnvironmentURLData(
            api: URL(string: state.apiServerUrl)?.sanitized,
            base: URL(string: state.serverUrl)?.sanitized,
            clientCertificateAlias: state.keyAlias.nilIfEmpty,
            clientCertificateFingerprint: state.keyFingerprint.nilIfEmpty,
            customHeadersId: customHeadersId,
            events: nil as URL?,
            icons: URL(string: state.iconsServerUrl)?.sanitized,
            identity: URL(string: state.identityServerUrl)?.sanitized,
            notifications: nil,
            webVault: URL(string: state.webVaultServerUrl)?.sanitized,
        )
        await delegate?.didSaveEnvironment(urls: urls)

        // Clean up the previously stored headers once the saved environment no longer references
        // them. The removal is reference-counted, so headers still used by another account remain.
        if let previousCustomHeadersId, previousCustomHeadersId != customHeadersId {
            do {
                try await services.customHeadersService.removeCustomHeaders(id: previousCustomHeadersId)
            } catch {
                services.errorReporter.log(error: error)
            }
        }

        coordinator.navigate(to: .dismissPresented)
    }

    /// Persists the edited custom headers and returns the identifier to store in the environment
    /// URLs, reusing the existing identifier when the headers are unchanged.
    ///
    /// - Returns: The identifier of the stored custom headers, or `nil` if none are configured.
    ///
    private func saveCustomHeaders() async throws -> String? {
        let headers = state.customHeadersDictionary
        let previousId = state.customHeadersId.nilIfEmpty

        guard !headers.isEmpty else { return nil }

        if let previousId,
           try await services.customHeadersService.getCustomHeaders(id: previousId) == headers {
            return previousId
        }

        return try await services.customHeadersService.saveCustomHeaders(headers)
    }

    /// Removes the currently stored client certificate and clears the associated state.
    ///
    /// Presents an error alert if the removal fails.
    ///
    private func removeClientCertificate() async {
        do {
            if let fingerprint = state.keyFingerprint.nilIfEmpty {
                try await services.clientCertificateService.removeCertificate(fingerprint: fingerprint)
            }
            state.keyAlias = ""
            state.keyFingerprint = ""
        } catch {
            coordinator.showAlert(Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: error.localizedDescription,
            ))
        }
    }
}
