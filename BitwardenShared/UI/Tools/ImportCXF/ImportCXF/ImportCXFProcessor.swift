import AuthenticationServices
import BitwardenResources
import BitwardenSdk

// MARK: - ImportCXFProcessor

/// The processor used to manage state and handle actions/effects for the Credential Exchange import screen.
///
class ImportCXFProcessor: StateProcessor<ImportCXFState, Void, ImportCXFEffect> {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasImportCiphersRepository
        & HasPolicyService
        & HasStateService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<ImportCXFRoute, Void>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `ImportCXFProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<ImportCXFRoute, Void>,
        services: Services,
        state: ImportCXFState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ImportCXFEffect) async {
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

    /// Checks whether the CXF import feature is enabled.
    private func checkEnabled() async {
        guard #available(iOS 26.0, *), await services.configService.getFeatureFlag(.cxpImportMobile) else {
            state.status = .failure(message: Localizations.importingFromAnotherProviderIsNotAvailableForThisDevice)
            return
        }
        if await services.policyService.policyAppliesToUser(.personalOwnership) {
            state.isFeatureUnavailable = true
            state.status = .failure(message: Localizations.personalOwnershipPolicyInEffect)
        }
    }

    /// Starts the import process.
    private func startImport() async {
        #if SUPPORTS_CXP

        guard #available(iOS 26.0, *), let credentialImportToken = state.credentialImportToken else {
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
                onProgress: { progress in state.progress = progress }
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
        guard !state.isFeatureUnavailable else {
            coordinator.navigate(to: .dismiss)
            return
        }

        coordinator.showAlert(.confirmCancelCXFImport { [weak self] in
            guard let self else { return }
            coordinator.navigate(to: .dismiss)
        })
    }
}
