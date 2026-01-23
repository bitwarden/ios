// swiftlint:disable:this file_name

import BitwardenKit
import Foundation
import OSLog

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
            .unitedStates
        } else if environmentURLs.baseURL == EnvironmentURLData.defaultEU.base {
            .europe
        } else {
            .selfHosted
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

    var upgradeToPremiumURL: URL {
        environmentURLs.upgradeToPremiumURL
    }

    var webVaultURL: URL {
        environmentURLs.webVaultURL
    }
}
