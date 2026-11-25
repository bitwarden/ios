import Foundation
import OSLog

// MARK: - DefaultEnvironmentService

/// A default implementation of an `EnvironmentService` which manages the app's environment URLs.
///
public class DefaultEnvironmentService: EnvironmentService {
    // MARK: Properties

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The service used by the application to manage environment URL state.
    let stateService: EnvironmentStateService

    // MARK: Private Properties

    /// Backing store for `currentClientCertificateFingerprint`. Access via the computed property.
    private nonisolated(unsafe) var _currentClientCertificateFingerprint: String?

    /// Backing store for `environmentURLs`. Access via the computed property.
    private nonisolated(unsafe) var _environmentURLs: EnvironmentURLs

    /// The SHA-256 fingerprint of the client certificate for the current environment.
    private var currentClientCertificateFingerprint: String? {
        get { lock.withLock { _currentClientCertificateFingerprint } }
        set { lock.withLock { _currentClientCertificateFingerprint = newValue } }
    }

    /// The app's current environment URLs.
    private var environmentURLs: EnvironmentURLs {
        get { lock.withLock { _environmentURLs } }
        set { lock.withLock { _environmentURLs = newValue } }
    }

    /// Lock protecting mutable environment state accessed from concurrent async tasks.
    private let lock = NSLock()

    /// The shared UserDefaults instance (NOTE: this should be the standard one just for the app,
    /// not one in the app group).
    private let standardUserDefaults: UserDefaults

    // MARK: Initialization

    /// Initialize a `DefaultEnvironmentService`.
    ///
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors
    ///   - standardUserDefaults: The shared UserDefaults instance.
    ///   - stateService: The service used by the application to manage environment URL state.
    ///
    public init(
        errorReporter: ErrorReporter,
        standardUserDefaults: UserDefaults = .standard,
        stateService: EnvironmentStateService,
    ) {
        self.errorReporter = errorReporter
        self.standardUserDefaults = standardUserDefaults
        self.stateService = stateService

        _environmentURLs = EnvironmentURLs(environmentURLData: .defaultUS)
    }

    // MARK: EnvironmentService

    public func getPreAuthURLs() async -> EnvironmentURLData? {
        await stateService.getPreAuthEnvironmentURLs()
    }

    public func loadURLsForActiveAccount() async {
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
        currentClientCertificateFingerprint = urls.clientCertificateFingerprint
        environmentURLs = EnvironmentURLs(environmentURLData: urls)

        errorReporter.setRegion(region.errorReporterName, isPreAuth: false)

        // swiftformat:disable:next redundantSelf
        Logger.application.info("Loaded environment URLs: \(String(describing: self.environmentURLs))")
    }

    public func setPreAuthURLs(urls: EnvironmentURLData) async {
        await stateService.setPreAuthEnvironmentURLs(urls)
        currentClientCertificateFingerprint = urls.clientCertificateFingerprint
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

public extension DefaultEnvironmentService {
    /// The URL for the API.
    var apiURL: URL {
        environmentURLs.apiURL
    }

    /// The environment's base URL.
    var baseURL: URL {
        environmentURLs.baseURL
    }

    /// The URL for changing email address.
    var changeEmailURL: URL {
        environmentURLs.changeEmailURL
    }

    /// The SHA-256 fingerprint of the client certificate used for mTLS, if configured.
    var clientCertificateFingerprint: String? {
        currentClientCertificateFingerprint
    }

    /// The URL for the events API.
    var eventsURL: URL {
        environmentURLs.eventsURL
    }

    /// The URL for fetching Fill-Assist targeting rules.
    var fillAssistRulesURL: URL {
        environmentURLs.fillAssistRulesURL
    }

    /// The URL for the icons API.
    var iconsURL: URL {
        environmentURLs.iconsURL
    }

    /// The URL for the identity API.
    var identityURL: URL {
        environmentURLs.identityURL
    }

    /// The URL for importing items.
    var importItemsURL: URL {
        environmentURLs.importItemsURL
    }

    /// The URL for managing the subscription plan.
    var manageSubscriptionURL: URL {
        environmentURLs.manageSubscriptionURL
    }

    /// The URL for a proxy on cookie redirect (used on SSO sync error).
    var proxyCookieRedirectConnectorURL: URL {
        environmentURLs.proxyCookieRedirectConnectorURL
    }

    /// The URL for the recovery code help page.
    var recoveryCodeURL: URL {
        environmentURLs.recoveryCodeURL
    }

    /// The region of the current environment.
    var region: RegionType {
        environmentURLs.region
    }

    /// The URL for sharing a send.
    var sendShareURL: URL {
        environmentURLs.sendShareURL
    }

    /// The URL for vault settings.
    var settingsURL: URL {
        environmentURLs.settingsURL
    }

    /// The URL for setting up two-factor login.
    var setUpTwoFactorURL: URL {
        environmentURLs.setUpTwoFactorURL
    }

    /// The URL for upgrading to Premium.
    var upgradeToPremiumURL: URL {
        environmentURLs.upgradeToPremiumURL
    }

    /// The URL for the web vault.
    var webVaultURL: URL {
        environmentURLs.webVaultURL
    }
}
