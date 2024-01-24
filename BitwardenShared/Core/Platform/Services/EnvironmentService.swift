import Foundation
import OSLog

// MARK: - EnvironmentService

/// A protocol for an `EnvironmentService` which manages the app's environment URLs.
///
protocol EnvironmentService {
    /// The URL for the API.
    var apiURL: URL { get }

    /// The URL for the events API.
    var eventsURL: URL { get }

    /// The URL for the icons API.
    var iconsURL: URL { get }

    /// The URL for the identity API.
    var identityURL: URL { get }

    /// The URL for sharing a send.
    var sendShareURL: URL { get }

    /// The URL for the web vault.
    var webVaultURL: URL { get }

    /// Loads the URLs for the active account into the environment. This can be called on app launch
    /// whether there's an active account or not to pre-populate the environment. If there's no
    /// active account, the US URLs will be used.
    ///
    func loadURLsForActiveAccount() async

    /// Sets the pre-auth URLs for the environment. This should be called if there isn't an an
    /// active account on app launch or if the user navigates through the add/create account flow.
    ///
    /// - Parameter urls: The URLs to set and use prior to user authentication.
    ///
    func setPreAuthURLs(urls: EnvironmentUrlData) async
}

// MARK: - DefaultEnvironmentService

/// A default implementation of an `EnvironmentService` which manages the app's environment URLs.
///
class DefaultEnvironmentService: EnvironmentService {
    // MARK: Properties

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Private Properties

    /// The app's current environment URLs.
    private var environmentUrls: EnvironmentUrls

    // MARK: Initialization

    /// Initialize a `DefaultEnvironmentService`.
    ///
    /// - Parameter stateService: The service used by the application to manage account state.
    ///
    init(stateService: StateService) {
        self.stateService = stateService

        environmentUrls = EnvironmentUrls(environmentUrlData: .defaultUS)
    }

    // MARK: EnvironmentService

    func loadURLsForActiveAccount() async {
        let urls: EnvironmentUrlData = await (try? stateService.getEnvironmentUrls()) ?? .defaultUS
        environmentUrls = EnvironmentUrls(environmentUrlData: urls)

        // swiftformat:disable:next redundantSelf
        Logger.application.info("Loaded environment URLs: \(String(describing: self.environmentUrls))")
    }

    func setPreAuthURLs(urls: EnvironmentUrlData) async {
        await stateService.setPreAuthEnvironmentUrls(urls)
        environmentUrls = EnvironmentUrls(environmentUrlData: urls)

        // swiftformat:disable:next redundantSelf
        Logger.application.info("Setting pre-auth URLs: \(String(describing: self.environmentUrls))")
    }
}

extension DefaultEnvironmentService {
    var apiURL: URL {
        environmentUrls.apiURL
    }

    var iconsURL: URL {
        environmentUrls.iconsURL
    }

    var identityURL: URL {
        environmentUrls.identityURL
    }

    var eventsURL: URL {
        environmentUrls.eventsURL
    }

    var sendShareURL: URL {
        environmentUrls.sendShareURL
    }

    var webVaultURL: URL {
        environmentUrls.webVaultURL
    }
}
