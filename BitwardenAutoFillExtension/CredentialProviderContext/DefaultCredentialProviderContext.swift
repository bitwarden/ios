import AuthenticationServices
import BitwardenShared

@available(iOSApplicationExtension 17.0, *)
struct DefaultCredentialProviderContext: CredentialProviderContext {
    var authCompletionRoute: AppRoute? {
        switch extensionMode {
        case .autofillCredential:
            return nil
        case .autofillVaultList:
            return AppRoute.vault(.autofillList)
        case .configureAutofill:
            return AppRoute.extensionSetup(.extensionActivation(type: .autofillExtension))
        case .registerFido2Credential:
            return AppRoute.vault(.autofillList)
        }
    }

    var configuring: Bool {
        extensionMode == .configureAutofill
    }

    /// The mode that describes how the extension is being used.
    var extensionMode = ExtensionMode.configureAutofill

    var passwordCredentialIdentity: ASPasswordCredentialIdentity? {
        nil
    }

    var serviceIdentifiers: [ASCredentialServiceIdentifier] {
        if case let .autofillVaultList(serviceIdentifiers, _) = extensionMode {
            return serviceIdentifiers
        }
        return []
    }

    /// Initilalizes the context
    /// - Parameter extensionMode: The mode of the extension.
    init(_ extensionMode: ExtensionMode) {
        self.extensionMode = extensionMode
    }
}
