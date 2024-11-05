import Foundation

extension Bundle {
    /// Return's the app's action extension identifier.
    var appExtensionIdentifier: String {
        "\(bundleIdentifier!).find-login-action-extension"
    }

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

    /// Return's the app's app identifier.
    var appIdentifier: String {
        infoDictionary?["BitwardenAppIdentifier"] as? String
            ?? bundleIdentifier
            ?? "com.x8bit.bitwarden"
    }

    /// Return's the app's app group identifier.
    var groupIdentifier: String {
        "group." + appIdentifier
    }

    /// Return's the app's access group identifier for storing keychain items.
    var keychainAccessGroup: String {
        infoDictionary?["BitwardenKeychainAccessGroup"] as? String ?? appIdentifier
    }

    /// Return's the shared app group identifier. This App Group is shared between the
    /// main Bitwarden app and the Authenticator app.
    var sharedAppGroupIdentifier: String {
        infoDictionary?["BitwardenAuthenticatorSharedAppGroup"] as? String ?? groupIdentifier
    }
}
