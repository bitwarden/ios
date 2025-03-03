import BitwardenKit

class MockBundle: BundleProtocol {
    var appExtensionIdentifier = "com.8bit.bitwarden.find-login-action-extension"
    var appIdentifier = "com.8bit.bitwarden"
    var appName = "Bitwarden"
    var appVersion = "1.0"
    var bundleIdentifier: String? = "com.8bit.bitwarden"
    var buildNumber = "1"
    var groupIdentifier = "group.com.8bit.bitwarden"
    var keychainAccessGroup = "group.com.8bit.bitwarden"
    var sharedAppGroupIdentifier = "group.com.8bit.bitwarden-authenticator"
}
