import AuthenticationServices

// MARK: - GeneratePasswordExtensionDelegate

/// A bridge that connects `GeneratorCoordinatorDelegate` to `CredentialProviderExtensionDelegate`
/// for the generate-password-with-UI extension flow (iOS 26.2+).
///
/// The `VaultCoordinator` creates one of these when handling the `.generatePassword` route,
/// passes it as the delegate to a newly-created `GeneratorCoordinator`, and retains it for the
/// duration of the flow. When the user completes or cancels the generator, this object forwards
/// the result to the credential-provider extension delegate, which in turn completes or cancels
/// the `ASCredentialProviderExtensionContext` request.
///
@available(iOS 26.2, iOSApplicationExtension 26.2, *)
final class GeneratePasswordExtensionDelegate: GeneratorCoordinatorDelegate {
    // MARK: Private Properties

    /// A delegate used to communicate with the credential provider extension.
    private weak var extensionDelegate: CredentialProviderExtensionDelegate?

    // MARK: Initialization

    /// Creates a new `GeneratePasswordExtensionDelegate`.
    ///
    /// - Parameter extensionDelegate: A delegate used to communicate with the credential provider extension.
    ///
    init(extensionDelegate: CredentialProviderExtensionDelegate) {
        self.extensionDelegate = extensionDelegate
    }

    // MARK: GeneratorCoordinatorDelegate

    func didCancelGenerator() {
        extensionDelegate?.didCancel()
    }

    func didCompleteGenerator(for type: GeneratorType, with value: String) {
        let kind: ASGeneratedPassword.Kind
        switch type {
        case .passphrase:
            kind = .passphrase
        case .password, .username:
            // TODO: PM-29569 Derive kind from request rules once SDK exposes the mapping API.
            // Heuristic: a password that contains any non-alphanumeric character is "strong".
            // The Bitwarden generator guarantees at least one special character when the option
            // is enabled, so this reliably distinguishes .strong from .alphanumeric.
            let hasSpecialCharacter = value.unicodeScalars.contains { scalar in
                !CharacterSet.alphanumerics.contains(scalar)
            }
            kind = hasSpecialCharacter ? .strong : .alphanumeric
        }
        extensionDelegate?.completeGeneratePasswordRequest(kind: kind, password: value)
    }
}
