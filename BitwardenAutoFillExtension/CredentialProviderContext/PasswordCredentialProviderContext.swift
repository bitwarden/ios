import AuthenticationServices
import BitwardenShared

struct PasswordCredentialProviderContext: CredentialProviderContext {
    var authCompletionRoute: AppRoute? {
        switch extensionMode {
        case .autofillCredential:
            return nil
        case .autofillVaultList:
            return AppRoute.vault(.autofillList)
        case .configureAutofill:
            return AppRoute.extensionSetup(.extensionActivation(type: .autofillExtension))
        }
    }

    var configuring: Bool {
        extensionMode == .configureAutofill
    }

    /// The mode that describes how the extension is being used.
    var extensionMode = PasswordExtensionMode.configureAutofill

    var passwordCredentialIdentity: ASPasswordCredentialIdentity? {
        if case let .autofillCredential(credential) = extensionMode {
            return credential
        }
        return nil
    }

    var serviceIdentifiers: [ASCredentialServiceIdentifier] {
        if case let .autofillVaultList(serviceIdentifiers) = extensionMode {
            return serviceIdentifiers
        }
        return []
    }

    /// Initilalizes the context
    /// - Parameter extensionMode: The mode of the extension.
    init(_ extensionMode: PasswordExtensionMode) {
        self.extensionMode = extensionMode
    }
}
