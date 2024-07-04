import AuthenticationServices
import BitwardenShared

protocol CredentialProviderContext {
    /// The `AppRoute` depending on the `ExtensionMode`.
    var authCompletionRoute: AppRoute? { get }
    /// Whether the provider is being configured.
    var configuring: Bool { get }
    /// The password credential identity of `autofillCredential(_:)`.
    var passwordCredentialIdentity: ASPasswordCredentialIdentity? { get }
    /// The `ASCredentialServiceIdentifier` array depending on the `ExtensionMode`.
    var serviceIdentifiers: [ASCredentialServiceIdentifier] { get }
}
