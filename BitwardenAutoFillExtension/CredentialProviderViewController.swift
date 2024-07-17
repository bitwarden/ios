import AuthenticationServices
import BitwardenSdk
import BitwardenShared
import OSLog

/// An `ASCredentialProviderViewController` that implements credential autofill.
///
class CredentialProviderViewController: ASCredentialProviderViewController {
    // MARK: Properties

    /// The app's theme.
    var appTheme: AppTheme = .default

    /// The processor that manages application level logic.
    private var appProcessor: AppProcessor?

    /// The context of the credential provider to see how the extension is being used.
    private var context: CredentialProviderContext?

    // MARK: ASCredentialProviderViewController

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        initializeApp(with: DefaultCredentialProviderContext(.autofillVaultList(serviceIdentifiers)))
    }

    @available(iOSApplicationExtension 17.0, *)
    override func prepareCredentialList(
        for serviceIdentifiers: [ASCredentialServiceIdentifier],
        requestParameters: ASPasskeyCredentialRequestParameters
    ) {
        initializeApp(with: DefaultCredentialProviderContext(
            .autofillFido2VaultList(serviceIdentifiers, requestParameters)
        ))
    }

    override func prepareInterfaceForExtensionConfiguration() {
        initializeApp(with: DefaultCredentialProviderContext(.configureAutofill))
    }

    @available(iOSApplicationExtension 17.0, *)
    override func prepareInterface(forPasskeyRegistration registrationRequest: any ASCredentialRequest) {
        guard let fido2RegistrationRequest = registrationRequest as? ASPasskeyCredentialRequest else {
            return
        }
        initializeApp(with: DefaultCredentialProviderContext(.registerFido2Credential(fido2RegistrationRequest)))
    }

    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        initializeApp(with: DefaultCredentialProviderContext(.autofillCredential(credentialIdentity)))
    }

    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        guard let recordIdentifier = credentialIdentity.recordIdentifier else {
            cancel(error: ASExtensionError(.credentialIdentityNotFound))
            return
        }

        initializeApp(
            with: DefaultCredentialProviderContext(.autofillCredential(credentialIdentity)),
            userInteraction: false
        )
        provideCredential(for: recordIdentifier)
    }

    @available(iOSApplicationExtension 17.0, *)
    override func provideCredentialWithoutUserInteraction(for credentialRequest: any ASCredentialRequest) {
        switch credentialRequest {
        case let passwordRequest as ASPasswordCredentialRequest:
            provideCredentialWithoutUserInteraction(for: passwordRequest)
        case let passkeyRequest as ASPasskeyCredentialRequest:
            initializeApp(
                with: DefaultCredentialProviderContext(.autofillFido2Credential(passkeyRequest)),
                userInteraction: false
            )
            provideFido2Credential(for: passkeyRequest)
        default:
            break
        }
    }

    // MARK: Private

    /// Cancels the extension request and dismisses the extension's view controller.
    ///
    /// - Parameter error: An optional error describing why the request failed.
    ///
    private func cancel(error: Error? = nil) {
        if let context, context.configuring {
            extensionContext.completeExtensionConfigurationRequest()
        } else if let error {
            extensionContext.cancelRequest(withError: error)
        } else {
            extensionContext.cancelRequest(
                withError: NSError(
                    domain: ASExtensionErrorDomain,
                    code: ASExtensionError.userCanceled.rawValue
                )
            )
        }
    }

    /// Sets up and initializes the app and UI.
    ///
    /// - Parameters:
    ///   - with: The context that describes how the extension is being used.
    ///   - userInteraction: Whether user interaction is allowed or if the app needs to
    ///     start without user interaction.
    ///
    private func initializeApp(with context: CredentialProviderContext, userInteraction: Bool = true) {
        self.context = context

        let errorReporter = OSLogErrorReporter()
        let services = ServiceContainer(errorReporter: errorReporter)
        let appModule = DefaultAppModule(appExtensionDelegate: self, services: services)
        let appProcessor = AppProcessor(appModule: appModule, services: services)
        self.appProcessor = appProcessor

        if userInteraction {
            Task {
                await appProcessor.start(appContext: .appExtension, navigator: self, window: nil)
            }
        }
    }

    /// Attempts to provide the credential with the specified ID to the extension context to handle
    /// autofill.
    ///
    /// - Parameters:
    ///   - id: The identifier of the user-requested credential to return.
    ///   - repromptPasswordValidated: `true` if master password reprompt was required for the
    ///     cipher and the user's master password was validated.
    ///
    private func provideCredential(
        for id: String,
        repromptPasswordValidated: Bool = false
    ) {
        guard let appProcessor else {
            cancel(error: ASExtensionError(.failed))
            return
        }

        Task {
            do {
                let credential = try await appProcessor.provideCredential(
                    for: id,
                    repromptPasswordValidated: repromptPasswordValidated
                )
                extensionContext.completeRequest(withSelectedCredential: credential)
            } catch {
                Logger.appExtension.error("Error providing credential without user interaction: \(error)")
                cancel(error: error)
            }
        }
    }

    /// Provides a Fido2 credential for a passkey request.
    /// - Parameter passkeyRequest: Request to get the credential.
    @available(iOSApplicationExtension 17.0, *)
    private func provideFido2Credential(for passkeyRequest: ASPasskeyCredentialRequest) {
        guard let appProcessor else {
            cancel(error: ASExtensionError(.failed))
            return
        }

        Task {
            do {
                let credential = try await appProcessor.provideFido2Credential(
                    for: passkeyRequest
                )
                await extensionContext.completeAssertionRequest(using: credential)
            } catch {
                Logger.appExtension.error("Error providing credential without user interaction: \(error)")
                cancel(error: error)
            }
        }
    }
}

// MARK: - AppExtensionDelegate

extension CredentialProviderViewController: AppExtensionDelegate {
    var authCompletionRoute: AppRoute? {
        context?.authCompletionRoute
    }

    var canAutofill: Bool { true }

    var isInAppExtension: Bool { true }

    var uri: String? {
        guard let serviceIdentifiers = context?.serviceIdentifiers,
              let serviceIdentifier = serviceIdentifiers.first
        else { return nil }

        return switch serviceIdentifier.type {
        case .domain:
            "https://" + serviceIdentifier.identifier
        case .URL:
            serviceIdentifier.identifier
        @unknown default:
            serviceIdentifier.identifier
        }
    }

    func completeAutofillRequest(username: String, password: String, fields: [(String, String)]?) {
        let passwordCredential = ASPasswordCredential(user: username, password: password)
        extensionContext.completeRequest(withSelectedCredential: passwordCredential)
    }

    func didCancel() {
        cancel()
    }

    func didCompleteAuth() {
        guard let credential = context?.passwordCredentialIdentity else { return }

        guard let appProcessor, let recordIdentifier = credential.recordIdentifier else {
            cancel(error: ASExtensionError(.failed))
            return
        }

        Task {
            do {
                try await appProcessor.repromptForCredentialIfNecessary(
                    for: recordIdentifier
                ) { repromptPasswordValidated in
                    self.provideCredential(
                        for: recordIdentifier,
                        repromptPasswordValidated: repromptPasswordValidated
                    )
                }
            } catch {
                Logger.appExtension.error("Error providing credential: \(error)")
                cancel(error: error)
            }
        }
    }
}

// MARK: - Fido2AppExtensionDelegate

extension CredentialProviderViewController: Fido2AppExtensionDelegate {
    /// The mode in which the autofill extension is running.
    var extensionMode: AutofillExtensionMode {
        context?.extensionMode ?? .configureAutofill
    }

    @available(iOSApplicationExtension 17.0, *)
    func completeRegistrationRequest(asPasskeyRegistrationCredential: ASPasskeyRegistrationCredential) {
        extensionContext.completeRegistrationRequest(using: asPasskeyRegistrationCredential)
    }
}

// MARK: - RootNavigator

extension CredentialProviderViewController: RootNavigator {
    var rootViewController: UIViewController? { self }

    func show(child: Navigator) {
        if let fromViewController = children.first {
            fromViewController.willMove(toParent: nil)
            fromViewController.view.removeFromSuperview()
            fromViewController.removeFromParent()
        }

        if let toViewController = child.rootViewController {
            addChild(toViewController)
            view.addConstrained(subview: toViewController.view)
            toViewController.didMove(toParent: self)
        }
    }
}
