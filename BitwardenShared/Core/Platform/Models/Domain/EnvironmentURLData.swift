import BitwardenKit
import Foundation

extension EnvironmentURLData {
    // MARK: Properties

    /// Whether all of the environment URLs are not set.
    var isEmpty: Bool {
        api == nil
            && base == nil
            && events == nil
            && icons == nil
            && identity == nil
            && notifications == nil
            && webVault == nil
    }

    /// The host of URL to the user's web vault.
    var webVaultHost: String? {
        let url = webVault ?? base
        return url?.host
    }
}
