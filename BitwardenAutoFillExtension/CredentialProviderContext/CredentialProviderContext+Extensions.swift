import AuthenticationServices
import BitwardenShared

extension CredentialProviderContext {
    /// The `AppRoute` depending on the `ExtensionMode`
    var authCompletionRoute: AppRoute? {
        if #available(iOSApplicationExtension 17.0, *),
           let defaultContext = self as? DefaultCredentialProviderContext {
            switch defaultContext.extensionMode {
            case .autofillCredential:
                return nil
            case .autofillVaultList:
                return AppRoute.vault(.autofillList)
            case .configureAutofill:
                return AppRoute.extensionSetup(.extensionActivation(type: .autofillExtension))
            case .registerFido2Credential:
                return AppRoute.vault(.autofillList)
            }
        } else if let passwordContext = self as? PasswordCredentialProviderContext {
            switch passwordContext.extensionMode {
            case .autofillCredential:
                return nil
            case .autofillVaultList:
                return AppRoute.vault(.autofillList)
            case .configureAutofill:
                return AppRoute.extensionSetup(.extensionActivation(type: .autofillExtension))
            }
        }
        return nil
    }

    /// The `ASCredentialServiceIdentifier` array depending on the `ExtensionMode`
    var serviceIdentifiers: [ASCredentialServiceIdentifier] {
        if #available(iOSApplicationExtension 17.0, *),
           let defaultContext = self as? DefaultCredentialProviderContext {
            if case let .autofillVaultList(serviceIdentifiers, _) = defaultContext.extensionMode {
                return serviceIdentifiers
            }
        } else if let passwordContext = self as? PasswordCredentialProviderContext {
            if case let .autofillVaultList(serviceIdentifiers) = passwordContext.extensionMode {
                return serviceIdentifiers
            }
        }
        return []
    }

    /// The password credential identity of `autofillCredential(_:)`
    var passwordCredentialIdentity: ASPasswordCredentialIdentity? {
        if let passwordContext = self as? PasswordCredentialProviderContext,
           case let .autofillCredential(credential) = passwordContext.extensionMode {
            return credential
        }
        return nil
    }
}
