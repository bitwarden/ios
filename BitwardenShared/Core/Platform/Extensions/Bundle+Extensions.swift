import Foundation

extension Bundle {
    /// Returns the app's name.
    var appName: String {
        infoDictionary?["CFBundleName"] as? String ?? ""
    }

    /// Returns the app's version string (e.g. "2023.8.0").
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// Returns the app's build number (e.g. "123").
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    /// Return's the app's app group identifier.
    var groupIdentifier: String {
        infoDictionary?["BitwardenAppGroupIdentifier"] as? String ?? "group.\(bundleIdentifier!)"
    }
}
