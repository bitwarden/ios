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

    /// The URL for changing email address.
    var changeEmailURL: URL { get }

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

    /// The URL for setting up two-factor login.
    var setUpTwoFactorURL: URL { get }

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
    func setPreAuthURLs(urls: EnvironmentURLData) async
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
    private var environmentURLs: EnvironmentURLs

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

        environmentURLs = EnvironmentURLs(environmentURLData: .defaultUS)
    }

    // MARK: EnvironmentService

    func loadURLsForActiveAccount() async {
        let urls: EnvironmentURLData
        let managedSettingsURLs = managedSettingsURLs()
        if let environmentURLs = try? await stateService.getEnvironmentURLs() {
            urls = environmentURLs
        } else if let managedSettingsURLs {
            urls = managedSettingsURLs
        } else if let preAuthURLs = await stateService.getPreAuthEnvironmentURLs() {
            urls = preAuthURLs
        } else {
            urls = .defaultUS
        }

        await setPreAuthURLs(urls: managedSettingsURLs ?? urls)
        environmentURLs = EnvironmentURLs(environmentURLData: urls)

        errorReporter.setRegion(region.errorReporterName, isPreAuth: false)

        // swiftformat:disable:next redundantSelf
        Logger.application.info("Loaded environment URLs: \(String(describing: self.environmentURLs))")
    }

    func setPreAuthURLs(urls: EnvironmentURLData) async {
        await stateService.setPreAuthEnvironmentURLs(urls)
        environmentURLs = EnvironmentURLs(environmentURLData: urls)

        errorReporter.setRegion(region.errorReporterName, isPreAuth: true)

        // swiftformat:disable:next redundantSelf
        Logger.application.info("Setting pre-auth URLs: \(String(describing: self.environmentURLs))")
    }

    // MARK: Private

    /// Returns the URLs that are specified as part of a managed app configuration.
    ///
    /// - Returns: The environment URLs that are specified as part of a managed app configuration.
    ///
    private func managedSettingsURLs() -> EnvironmentURLData? {
        let managedSettings = standardUserDefaults.dictionary(forKey: "com.apple.configuration.managed")
        guard let baseURLString = managedSettings?["baseEnvironmentUrl"] as? String,
              let baseURL = URL(string: baseURLString)
        else {
            return nil
        }
        return EnvironmentURLData(base: baseURL)
    }
}

extension DefaultEnvironmentService {
    var apiURL: URL {
        environmentURLs.apiURL
    }

    var baseURL: URL {
        environmentURLs.baseURL
    }

    var changeEmailURL: URL {
        environmentURLs.changeEmailURL
    }

    var eventsURL: URL {
        environmentURLs.eventsURL
    }

    var iconsURL: URL {
        environmentURLs.iconsURL
    }

    var identityURL: URL {
        environmentURLs.identityURL
    }

    var importItemsURL: URL {
        environmentURLs.importItemsURL
    }

    var recoveryCodeURL: URL {
        environmentURLs.recoveryCodeURL
    }

    var region: RegionType {
        if environmentURLs.baseURL == EnvironmentURLData.defaultUS.base {
            return .unitedStates
        } else if environmentURLs.baseURL == EnvironmentURLData.defaultEU.base {
            return .europe
        } else {
            return .selfHosted
        }
    }

    var sendShareURL: URL {
        environmentURLs.sendShareURL
    }

    var settingsURL: URL {
        environmentURLs.settingsURL
    }

    var setUpTwoFactorURL: URL {
        environmentURLs.setUpTwoFactorURL
    }

    var webVaultURL: URL {
        environmentURLs.webVaultURL
    }
}
