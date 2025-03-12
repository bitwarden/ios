import Foundation

// MARK: - BundleProtocol

/// A protocol for an app's bundle. This is used in place of `Bundle` to allow for mocking it
/// during tests.
///
public protocol BundleProtocol {
    /// Return's the app's action extension identifier.
    var appExtensionIdentifier: String { get }

    /// Return's the app's app identifier.
    var appIdentifier: String { get }

    /// Returns the app's name.
    var appName: String { get }

    /// Returns the app's version string (e.g. "2023.8.0").
    var appVersion: String { get }

    /// The app's bundle identifier.
    var bundleIdentifier: String? { get }

    /// Returns the app's build number (e.g. "123").
    var buildNumber: String { get }

    /// Return's the app's app group identifier.
    var groupIdentifier: String { get }

    /// Return's the app's access group identifier for storing keychain items.
    var keychainAccessGroup: String { get }

    /// Return's the shared app group identifier. This App Group is shared between the
    /// Password Manager app and the Authenticator app.
    var sharedAppGroupIdentifier: String { get }
}

// MARK: - Bundle + BundleProtocol

extension Bundle: BundleProtocol {
    public var appExtensionIdentifier: String {
        "\(bundleIdentifier!).find-login-action-extension"
    }

    public var appIdentifier: String {
        infoDictionary?["BitwardenAppIdentifier"] as? String
            ?? bundleIdentifier
            ?? "com.x8bit.bitwarden"
    }

    public var appName: String {
        infoDictionary?["CFBundleName"] as? String ?? ""
    }

    public var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    public var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    public var groupIdentifier: String {
        "group." + appIdentifier
    }

    public var keychainAccessGroup: String {
        infoDictionary?["BitwardenKeychainAccessGroup"] as? String ?? appIdentifier
    }

    public var sharedAppGroupIdentifier: String {
        infoDictionary?["BitwardenAuthenticatorSharedAppGroup"] as? String ?? groupIdentifier
    }
}
