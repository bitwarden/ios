import AuthenticationServices

/// Context for the credential provider.
public protocol CredentialProviderContext {
    /// The `AppRoute` depending on the `ExtensionMode`.
    var authCompletionRoute: AppRoute? { get }
    /// Whether the provider is being configured.
    var configuring: Bool { get }
    /// The mode in which the autofill extension is running.
    var extensionMode: AutofillExtensionMode { get }
    /// The password credential identity of `autofillCredential(_:)`.
    var passwordCredentialIdentity: ASPasswordCredentialIdentity? { get }
    /// Whether the flow has failed because user interaction is required.
    /// This is a workaround because the SDK transforms the error we throw, so we need a way to tell
    /// the caller that the error was because of user interaction required.
    var flowFailedBecauseUserInteractionRequired: Bool { get set }
    /// Whether the current flow is being executed with user interaction.
    var flowWithUserInteraction: Bool { get }
    /// The `ASCredentialServiceIdentifier` array depending on the `ExtensionMode`.
    var serviceIdentifiers: [ASCredentialServiceIdentifier] { get }
}

/// Default implementation of `CredentialProviderContext`.
public struct DefaultCredentialProviderContext: CredentialProviderContext {
    public var authCompletionRoute: AppRoute? {
        switch extensionMode {
        case .autofillCredential:
            nil
        case .autofillOTP:
            AppRoute.vault(.autofillList)
        case .autofillOTPCredential:
            nil
        case .autofillText:
            AppRoute.vault(.autofillList)
        case .autofillVaultList:
            AppRoute.vault(.autofillList)
        case .autofillFido2Credential:
            nil
        case .autofillFido2VaultList:
            AppRoute.vault(.autofillList)
        case .configureAutofill:
            AppRoute.extensionSetup(.extensionActivation(type: .autofillExtension))
        case .registerFido2Credential:
            AppRoute.vault(.autofillList)
        }
    }

    public var configuring: Bool {
        guard case .configureAutofill = extensionMode else {
            return false
        }
        return true
    }

    public private(set) var extensionMode = AutofillExtensionMode.configureAutofill

    public var flowFailedBecauseUserInteractionRequired: Bool = false

    public var flowWithUserInteraction: Bool {
        switch extensionMode {
        case let .autofillCredential(_, userInteraction):
            userInteraction
        case let .autofillFido2Credential(_, userInteraction):
            userInteraction
        case let .autofillOTPCredential(_, userInteraction):
            userInteraction
        default:
            true
        }
    }

    public var passwordCredentialIdentity: ASPasswordCredentialIdentity? {
        if case let .autofillCredential(credential, _) = extensionMode {
            return credential
        }
        return nil
    }

    public var serviceIdentifiers: [ASCredentialServiceIdentifier] {
        switch extensionMode {
        case let .autofillOTP(serviceIdentifiers):
            serviceIdentifiers
        case let .autofillVaultList(serviceIdentifiers):
            serviceIdentifiers
        case let .autofillFido2VaultList(serviceIdentifiers, _):
            serviceIdentifiers
        default:
            []
        }
    }

    /// Initializes the context.
    /// - Parameter extensionMode: The mode of the extension.
    public init(_ extensionMode: AutofillExtensionMode) {
        self.extensionMode = extensionMode
    }
}
