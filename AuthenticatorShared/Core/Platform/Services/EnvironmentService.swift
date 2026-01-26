// swiftlint:disable:this file_name

import BitwardenKit
import Foundation

// MARK: - DefaultEnvironmentService

/// A default implementation of an `EnvironmentService` which manages the app's environment URLs.
///
class DefaultEnvironmentService: EnvironmentService {
    // MARK: Private Properties

    /// The app's current environment URLs.
    private var environmentURLs: EnvironmentURLs

    // MARK: Initialization

    /// Initialize a `DefaultEnvironmentService`.
    ///
    init() {
        environmentURLs = EnvironmentURLs(environmentURLData: .defaultUS)
    }

    // MARK: EnvironmentService

    func loadURLsForActiveAccount() async {}

    func setPreAuthURLs(urls: BitwardenKit.EnvironmentURLData) async {}
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
