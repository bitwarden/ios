import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - RegionHelper

/// Helper class with common functionality related to the region selector.
///
class RegionHelper {
    /// The service used to manage client certificates for mTLS authentication.
    let clientCertificateService: ClientCertificateService

    /// Used to perform navigations and showing alert
    let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The service used to manage custom headers sent with requests to a self-hosted environment.
    let customHeadersService: CustomHeadersService

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// Service used to get environment information
    let stateService: StateService

    /// The delegate for the processor that is notified when the user saves their environment settings.
    weak var delegate: RegionDelegate?

    // MARK: Initialization

    /// Creates a new `RegionHelper`.
    ///
    /// - Parameters:
    ///   - clientCertificateService: The service used to manage client certificates.
    ///   - coordinator: The coordinator that handles navigation.
    ///   - customHeadersService: The service used to manage custom headers.
    ///   - delegate: The delegate for the processor.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The services used by the helper .
    ///
    init(
        clientCertificateService: ClientCertificateService,
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        customHeadersService: CustomHeadersService,
        delegate: RegionDelegate,
        errorReporter: ErrorReporter,
        stateService: StateService,
    ) {
        self.clientCertificateService = clientCertificateService
        self.coordinator = coordinator
        self.customHeadersService = customHeadersService
        self.delegate = delegate
        self.errorReporter = errorReporter
        self.stateService = stateService
    }

    /// Builds an alert for region selection and navigates to the alert.
    ///
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - currentRegion: The currently selected region.
    ///   - excludingRegions: Regions to omit from the picker. Defaults to empty (all selectable regions shown).
    ///
    func presentRegionSelectorAlert(
        title: String,
        currentRegion: RegionType?,
        excludingRegions: [RegionType] = [],
    ) async {
        let actions = RegionType.userSelectableCases
            .filter { !excludingRegions.contains($0) }
            .map { region in
                AlertAction(title: region.baseURLDescription, style: .default) { _ in
                    if let urls = region.defaultURLs {
                        let previousURLs = await self.stateService.getPreAuthEnvironmentURLs()
                        await self.delegate?.setRegion(region, urls)
                        await self.removeDroppedPreAuthCredentials(previousURLs: previousURLs, newURLs: urls)
                    } else {
                        await self.coordinator.navigate(
                            to: .selfHosted(currentRegion: currentRegion ?? .unitedStates),
                            context: self.delegate,
                        )
                    }
                }
            }
        let cancelAction = AlertAction(title: Localizations.cancel, style: .cancel)
        let alert = Alert(
            title: title,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: actions + [cancelAction],
        )
        await coordinator.showAlert(alert)
    }

    /// Sets the region to the last used region.
    ///
    func loadRegion() async {
        guard let urls = await stateService.getPreAuthEnvironmentURLs() else {
            await delegate?.setRegion(.unitedStates, .defaultUS)
            return
        }

        await delegate?.setRegion(urls.region, urls)
    }

    // MARK: Private

    /// Removes Keychain-stored credentials (client certificate identity, custom headers) whose
    /// pre-auth references were dropped by replacing the environment URLs. Removal is
    /// reference-counted, so credentials still used by an account remain in the Keychain.
    ///
    /// - Parameters:
    ///   - previousURLs: The pre-auth environment URLs before the replacement.
    ///   - newURLs: The pre-auth environment URLs after the replacement.
    ///
    private func removeDroppedPreAuthCredentials(
        previousURLs: EnvironmentURLData?,
        newURLs: EnvironmentURLData,
    ) async {
        if let fingerprint = previousURLs?.clientCertificateFingerprint,
           newURLs.clientCertificateFingerprint == nil {
            do {
                try await clientCertificateService.removeCertificate(fingerprint: fingerprint)
            } catch {
                errorReporter.log(error: error)
            }
        }
        if let customHeadersId = previousURLs?.customHeadersId,
           newURLs.customHeadersId == nil {
            do {
                try await customHeadersService.removeCustomHeaders(id: customHeadersId)
            } catch {
                errorReporter.log(error: error)
            }
        }
    }
}

// MARK: - RegionDelegate

/// A delegate of `Region` that is notified when the user saves their environment settings.
///
protocol RegionDelegate: AnyObject {
    /// Sets the region and the URLs to use.
    ///
    /// - Parameters:
    ///   - region: The region to use.
    ///   - urls: The URLs that the app should use for the region.
    ///
    func setRegion(_ region: RegionType, _ urls: EnvironmentURLData) async
}
