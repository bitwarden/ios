import AuthenticationServices
import BitwardenShared
import OSLog

/// An `ASCredentialProviderViewController` that implements credential autofill.
///
class CredentialProviderViewController: ASCredentialProviderViewController {
    // MARK: Types

    /// An enumeration that describes how the extension is being used.
    ///
    enum ExtensionMode {
        /// The extension is autofilling a specific credential.
        case autofillCredential(ASPasswordCredentialIdentity)

        /// The extension is displaying a list of items in the vault that match a service identifier.
        case autofillVaultList([ASCredentialServiceIdentifier])

        /// The extension is being configured to set up autofill.
        case configureAutofill
    }

    // MARK: Properties

    /// The app's theme.
    var appTheme: AppTheme = .default

    /// The processor that manages application level logic.
    private var appProcessor: AppProcessor?

    /// The mode that describes how the extension is being used.
    private var extensionMode = ExtensionMode.configureAutofill

    // MARK: ASCredentialProviderViewController

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        initializeApp(extensionMode: .autofillVaultList(serviceIdentifiers))
    }

    override func prepareInterfaceForExtensionConfiguration() {
        initializeApp(extensionMode: .configureAutofill)
    }

    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        initializeApp(extensionMode: .autofillCredential(credentialIdentity))
    }

    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        guard let recordIdentifier = credentialIdentity.recordIdentifier else {
            cancel(error: ASExtensionError(.credentialIdentityNotFound))
            return
        }

        initializeApp(extensionMode: .autofillCredential(credentialIdentity), userInteraction: false)
        provideCredential(for: recordIdentifier)
    }

    // MARK: Private

    /// Cancels the extension request and dismisses the extension's view controller.
    ///
    /// - Parameter error: An optional error describing why the request failed.
    ///
    private func cancel(error: Error? = nil) {
        if case .configureAutofill = extensionMode {
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
    ///   - extensionMode: The mode that describes how the extension is being used.
    ///   - userInteraction: Whether user interaction is allowed or if the app needs to
    ///     start without user interaction.
    ///
    private func initializeApp(extensionMode: ExtensionMode, userInteraction: Bool = true) {
        self.extensionMode = extensionMode

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
}

// MARK: - AppExtensionDelegate

extension CredentialProviderViewController: AppExtensionDelegate {
    var authCompletionRoute: AppRoute? {
        switch extensionMode {
        case .autofillCredential:
            nil
        case .autofillVaultList:
            AppRoute.vault(.autofillList)
        case .configureAutofill:
            AppRoute.extensionSetup(.extensionActivation(type: .autofillExtension))
        }
    }

    var canAutofill: Bool { true }

    var isInAppExtension: Bool { true }

    var uri: String? {
        guard case let .autofillVaultList(serviceIdentifiers) = extensionMode,
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
        guard case let .autofillCredential(credential) = extensionMode else { return }

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
