import BitwardenKit

public class MockBundle: BundleProtocol {
    public var appExtensionIdentifier = "com.8bit.bitwarden.find-login-action-extension"
    public var appIdentifier = "com.8bit.bitwarden"
    public var appName = "Bitwarden"
    public var appVersion = "1.0"
    public var bundleIdentifier: String? = "com.8bit.bitwarden"
    public var buildNumber = "1"
    public var groupIdentifier = "group.com.8bit.bitwarden"
    public var keychainAccessGroup = "group.com.8bit.bitwarden"
    public var sharedAppGroupIdentifier = "group.com.8bit.bitwarden-authenticator"

    public init() {}
}
