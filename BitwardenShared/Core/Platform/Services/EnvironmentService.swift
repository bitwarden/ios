import Foundation
import OSLog

// MARK: - EnvironmentService

/// A protocol for an `EnvironmentService` which manages the app's environment URLs.
///
protocol EnvironmentService {
    /// The URL for the API.
    var apiURL: URL { get }

    /// The environment's base URL.
    var baseURL: URL { get }

    /// The URL for the events API.
    var eventsURL: URL { get }

    /// The URL for the icons API.
    var iconsURL: URL { get }

    /// The URL for the identity API.
    var identityURL: URL { get }

    /// The URL for importing items.
    var importItemsURL: URL { get }

    /// The URL for the recovery code help page.
    var recoveryCodeURL: URL { get }

    /// The region of the current environment.
    var region: RegionType { get }

    /// The URL for sharing a send.
    var sendShareURL: URL { get }

    /// The URL for vault settings.
    var settingsURL: URL { get }

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
    
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Private Properties

    /// The app's current environment URLs.
    private var environmentUrls: EnvironmentUrls

    /// The shared UserDefaults instance (NOTE: this should be the standard one just for the app,
    /// not one in the app group).
    private let standardUserDefaults: UserDefaults

    // MARK: Initialization

    /// Initialize a `DefaultEnvironmentService`.
    /// 
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors
    ///   - stateService: The service used by the application to manage account state.
    ///   - standardUserDefaults: The shared UserDefaults instance.
    ///
    init(errorReporter: ErrorReporter, stateService: StateService, standardUserDefaults: UserDefaults = .standard) {
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.standardUserDefaults = standardUserDefaults

        environmentUrls = EnvironmentUrls(environmentUrlData: .defaultUS)
    }

    // MARK: EnvironmentService

    func loadURLsForActiveAccount() async {
        let urls: EnvironmentUrlData
        let managedSettingsUrls = managedSettingsUrls()
        if let environmentUrls = try? await stateService.getEnvironmentUrls() {
            urls = environmentUrls
        } else if let managedSettingsUrls {
            urls = managedSettingsUrls
        } else if let preAuthUrls = await stateService.getPreAuthEnvironmentUrls() {
            urls = preAuthUrls
        } else {
            urls = .defaultUS
        }

        await setPreAuthURLs(urls: managedSettingsUrls ?? urls)
        environmentUrls = EnvironmentUrls(environmentUrlData: urls)

        errorReporter.setRegion(region.errorReporterName, isPreAuth: false)

        // swiftformat:disable:next redundantSelf
        Logger.application.info("Loaded environment URLs: \(String(describing: self.environmentUrls))")
    }

    func setPreAuthURLs(urls: EnvironmentUrlData) async {
        await stateService.setPreAuthEnvironmentUrls(urls)
        environmentUrls = EnvironmentUrls(environmentUrlData: urls)

        errorReporter.setRegion(region.errorReporterName, isPreAuth: true)

        // swiftformat:disable:next redundantSelf
        Logger.application.info("Setting pre-auth URLs: \(String(describing: self.environmentUrls))")
    }

    // MARK: Private

    /// Returns the URLs that are specified as part of a managed app configuration.
    ///
    /// - Returns: The environment URLs that are specified as part of a managed app configuration.
    ///
    private func managedSettingsUrls() -> EnvironmentUrlData? {
        let managedSettings = standardUserDefaults.dictionary(forKey: "com.apple.configuration.managed")
        guard let baseUrlString = managedSettings?["baseEnvironmentUrl"] as? String,
              let baseUrl = URL(string: baseUrlString)
        else {
            return nil
        }
        return EnvironmentUrlData(base: baseUrl)
    }
}

extension DefaultEnvironmentService {
    var apiURL: URL {
        environmentUrls.apiURL
    }

    var baseURL: URL {
        environmentUrls.baseURL
    }

    var eventsURL: URL {
        environmentUrls.eventsURL
    }

    var iconsURL: URL {
        environmentUrls.iconsURL
    }

    var identityURL: URL {
        environmentUrls.identityURL
    }

    var importItemsURL: URL {
        environmentUrls.importItemsURL
    }

    var recoveryCodeURL: URL {
        environmentUrls.recoveryCodeURL
    }

    var region: RegionType {
        if environmentUrls.baseURL == EnvironmentUrlData.defaultUS.base {
            return .unitedStates
        } else if environmentUrls.baseURL == EnvironmentUrlData.defaultEU.base {
            return .europe
        } else {
            return .selfHosted
        }
    }

    var sendShareURL: URL {
        environmentUrls.sendShareURL
    }

    var settingsURL: URL {
        environmentUrls.settingsURL
    }

    var webVaultURL: URL {
        environmentUrls.webVaultURL
    }
}
