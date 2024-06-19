import AuthenticationServices

protocol CredentialProviderContext {
    var configuring: Bool { get }
}

struct PasswordCredentialProviderContext: CredentialProviderContext {
    var configuring: Bool {
        extensionMode == .configureAutofill
    }

    /// The mode that describes how the extension is being used.
    var extensionMode = PasswordExtensionMode.configureAutofill

    init(_ extensionMode: PasswordExtensionMode) {
        self.extensionMode = extensionMode
    }
}

@available(iOSApplicationExtension 17.0, *)
struct DefaultCredentialProviderContext: CredentialProviderContext {
    var configuring: Bool {
        extensionMode == .configureAutofill
    }

    /// The mode that describes how the extension is being used.
    var extensionMode = ExtensionMode.configureAutofill

    init(_ extensionMode: ExtensionMode) {
        self.extensionMode = extensionMode
    }
}
