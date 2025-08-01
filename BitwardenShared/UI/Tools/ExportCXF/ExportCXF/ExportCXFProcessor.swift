import AuthenticationServices
import BitwardenResources
import BitwardenSdk

// MARK: - ExportCXFProcessor

/// The processor used to manage state and handle actions/effects for the Credential Exchange export flow.
///
class ExportCXFProcessor: StateProcessor<ExportCXFState, ExportCXFAction, ExportCXFEffect> {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasExportCXFCiphersRepository
        & HasPolicyService
        & HasStateService
        & HasVaultRepository

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<ExportCXFRoute, Void>

    /// A delegate of the `ExportCXFProcessor` that is used to get presentation anchors.
    private weak var delegate: ExportCXFProcessorDelegate?

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `ExportCXFProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate that is used to get presentation anchors.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<ExportCXFRoute, Void>,
        delegate: ExportCXFProcessorDelegate?,
        services: Services,
        state: ExportCXFState
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ExportCXFEffect) async {
        switch effect {
        case .appeared:
            await load()
        case .cancel:
            cancelWithConfirmation()
        case .mainButtonTapped:
            switch state.status {
            case .failure, .start:
                await prepareExport()
            case .prepared:
                await startExport()
            }
        }
    }

    // MARK: Private

    /// Loads the initial data for the view.
    private func load() async {
        if await services.policyService.policyAppliesToUser(.disablePersonalVaultExport) {
            state.isFeatureUnavailable = true
            state.status = .failure(message: Localizations.disablePersonalVaultExportPolicyInEffect)
            return
        }

        await prepareExport()
    }

    /// Prepares the export process of all items.
    private func prepareExport() async {
        do {
            let allCiphers = try await services.exportCXFCiphersRepository.getAllCiphersToExportCXF()
            guard !allCiphers.isEmpty else {
                state.isFeatureUnavailable = true
                state.status = .failure(message: Localizations.noItems)
                return
            }

            let itemsToExport = services.exportCXFCiphersRepository.buildCiphersToExportSummary(from: allCiphers)
            state.status = .prepared(itemsToExport: itemsToExport)
        } catch {
            services.errorReporter.log(error: error)
            state.status = .failure(message: Localizations.exportVaultFailure)
        }
    }

    /// Starts the export process.
    private func startExport() async {
        #if SUPPORTS_CXP

        guard #available(iOS 26.0, *) else {
            coordinator.showAlert(
                .defaultAlert(
                    title: Localizations.exportingFailed
                )
            )
            return
        }

        guard let delegate else {
            return
        }

        coordinator.showLoadingOverlay(title: Localizations.loading)
        defer { coordinator.hideLoadingOverlay() }

        do {
            let data = try await services.exportCXFCiphersRepository.getExportVaultDataForCXF()
            coordinator.hideLoadingOverlay()
            try await services.exportCXFCiphersRepository.exportCredentials(
                data: data,
                presentationAnchor: { await delegate.presentationAnchorForASCredentialExportManager() }
            )
            coordinator.navigate(to: .dismiss)
        } catch ASAuthorizationError.failed {
            coordinator
                .showAlert(
                    .defaultAlert(
                        title: Localizations.exportingFailed,
                        message: Localizations.youMayNeedToEnableDevicePasscodeOrBiometrics
                    )
                )
        } catch {
            state.status = .failure(message: Localizations.thereHasBeenAnIssueExportingItems)
            services.errorReporter.log(error: error)
        }

        #endif
    }

    /// Shows the alert confirming the user wants to export items later.
    private func cancelWithConfirmation() {
        guard !state.isFeatureUnavailable else {
            coordinator.navigate(to: .dismiss)
            return
        }

        coordinator.showAlert(.confirmCancelCXFExport { [weak self] in
            guard let self else { return }
            coordinator.navigate(to: .dismiss)
        })
    }
}

// MARK: - ExportVaultProcessorDelegate

/// A protocol delegate for the `ExportCXFProcessor`.
protocol ExportCXFProcessorDelegate: AnyObject {
    /// Returns an `ASPresentationAnchor` to be used when creating an `ASCredentialExportManager`.
    /// - Returns: An `ASPresentationAnchor`.
    @MainActor
    func presentationAnchorForASCredentialExportManager() async -> ASPresentationAnchor
}
