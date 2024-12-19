import AuthenticationServices
import BitwardenSdk

// MARK: - ImportCXPProcessor

/// The processor used to manage state and handle actions/effects for the Credential Exchange import screen.
///
class ImportCXPProcessor: StateProcessor<ImportCXPState, Void, ImportCXPEffect> {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasImportCiphersRepository
        & HasStateService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<ImportCXPRoute, Void>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `ImportCXPProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<ImportCXPRoute, Void>,
        services: Services,
        state: ImportCXPState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ImportCXPEffect) async {
        switch effect {
        case .appeared:
            await checkEnabled()
        case .cancel:
            cancelWithConfirmation()
        case .mainButtonTapped:
            switch state.status {
            case .failure, .start:
                await startImport()
            case .importing:
                break
            case .success:
                coordinator.navigate(to: .dismiss)
            }
        }
    }

    // MARK: Private

    /// Checks whether the CXP import feature is enabled.
    private func checkEnabled() async {
        guard #available(iOS 18.2, *), await services.configService.getFeatureFlag(.cxpImportMobile) else {
            state.status = .failure(message: Localizations.importingFromAnotherProviderIsNotAvailableForThisDevice)
            return
        }
    }

    /// Starts the import process.
    private func startImport() async {
        #if compiler(>=6.0.3)

        guard #available(iOS 18.2, *), let credentialImportToken = state.credentialImportToken else {
            coordinator.showAlert(
                .defaultAlert(
                    title: Localizations.importError,
                    message: Localizations.importingFromAnotherProviderIsNotAvailableForThisDevice
                )
            )
            return
        }

        state.status = .importing

        do {
            let results = try await services.importCiphersRepository.importCiphers(
                credentialImportToken: credentialImportToken,
                progressDelegate: self
            )

            state.status = .success(
                totalImportedCredentials: results.map(\.count).reduce(0, +),
                importedResults: results
            )
        } catch ImportCiphersRepositoryError.noDataFound {
            state.status = .failure(message: "No data found to import.")
        } catch ImportCiphersRepositoryError.dataEncodingFailed {
            state.status = .failure(message: "Import data encoding failed.")
        } catch {
            state.status = .failure(message: Localizations.thereWasAnIssueImportingAllOfYourPasswordsNoDataWasDeleted)
            services.errorReporter.log(error: error)
        }

        #endif
    }

    /// Shows the alert confirming the user wants to import logins later.
    private func cancelWithConfirmation() {
        guard !state.isFeatureUnvailable else {
            coordinator.navigate(to: .dismiss)
            return
        }

        coordinator.showAlert(.confirmCancelCXPImport { [weak self] in
            guard let self else { return }
            coordinator.navigate(to: .dismiss)
        })
    }
}

extension ImportCXPProcessor: ProgressDelegate {
    func report(progress: Double) {
        state.progress = progress
    }
}
