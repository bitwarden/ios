import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - RegionHelper

/// Helper class with common functionality related to the region selector.
///
class RegionHelper {
    /// Used to perform navigations and showing alert
    let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// Service used to get environment information
    let stateService: StateService

    /// The delegate for the processor that is notified when the user saves their environment settings.
    weak var delegate: RegionDelegate?

    // MARK: Initialization

    /// Creates a new `RegionHelper`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate for the processor.
    ///   - stateService: The services used by the helper .
    ///
    init(coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
         delegate: RegionDelegate,
         stateService: StateService) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.stateService = stateService
    }

    /// Builds an alert for region selection and navigates to the alert.
    ///
    func presentRegionSelectorAlert(title: String, currentRegion: RegionType?) async {
        let actions = RegionType.allCases.map { region in
            AlertAction(title: region.baseURLDescription, style: .default) { _ in
                if let urls = region.defaultURLs {
                    await self.delegate?.setRegion(region, urls)
                } else {
                    await self.coordinator.navigate(
                        to: .selfHosted(currentRegion: currentRegion ?? .unitedStates),
                        context: self.delegate
                    )
                }
            }
        }
        let cancelAction = AlertAction(title: Localizations.cancel, style: .cancel)
        let alert = Alert(
            title: title,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: actions + [cancelAction]
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

        if urls.base == EnvironmentURLData.defaultUS.base {
            await delegate?.setRegion(.unitedStates, urls)
        } else if urls.base == EnvironmentURLData.defaultEU.base {
            await delegate?.setRegion(.europe, urls)
        } else {
            await delegate?.setRegion(.selfHosted, urls)
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
