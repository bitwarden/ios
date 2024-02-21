import AuthenticationServices
import BitwardenShared

/// An `ASCredentialProviderViewController` that implements credential autofill.
///
class CredentialProviderViewController: ASCredentialProviderViewController {
    // MARK: Properties

    /// The app's theme.
    var appTheme: AppTheme = .default

    /// The processor that manages application level logic.
    private var appProcessor: AppProcessor?

    /// Whether the extension was opened to configure the extension after it was enabled.
    private var isConfiguring = false

    /// A list of service identifiers used to filter credentials for autofill.
    private var serviceIdentifiers = [ASCredentialServiceIdentifier]()

    // MARK: ASCredentialProviderViewController

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        self.serviceIdentifiers = serviceIdentifiers
        initializeApp()
    }

//     Implement this method if your extension supports showing credentials in the QuickType bar.
//     When the user selects a credential from your app, this method will be called with the
//     ASPasswordCredentialIdentity your app has previously saved to the ASCredentialIdentityStore.
//     Provide the password by completing the extension request with the associated ASPasswordCredential.
//     If using the credential would require showing custom UI for authenticating the user, cancel
//     the request with error code ASExtensionError.userInteractionRequired.
//    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
//        let databaseIsUnlocked = true
//        if (databaseIsUnlocked) {
//            let passwordCredential = ASPasswordCredential(user: "j_appleseed", password: "apple1234")
//            self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
//        } else {
//            self.extensionContext.cancelRequest(
//                withError: NSError(
//                    domain: ASExtensionErrorDomain,
//                    code: ASExtensionError.userInteractionRequired.rawValue
//                )
//            )
//        }
//    }

//     Implement this method if provideCredentialWithoutUserInteraction(for:) can fail with
//     ASExtensionError.userInteractionRequired. In this case, the system may present your extension's
//     UI and call this method. Show appropriate UI for authenticating the user then provide the password
//     by completing the extension request with the associated ASPasswordCredential.
//
//    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
//    }

    override func prepareInterfaceForExtensionConfiguration() {
        isConfiguring = true
        initializeApp()
    }

    // MARK: Private

    /// Cancels the extension request and dismisses the extension's view controller.
    ///
    private func cancel() {
        if isConfiguring {
            extensionContext.completeExtensionConfigurationRequest()
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
    private func initializeApp() {
        let errorReporter = OSLogErrorReporter()
        let services = ServiceContainer(errorReporter: errorReporter)
        let appModule = DefaultAppModule(appExtensionDelegate: self, services: services)
        let appProcessor = AppProcessor(appModule: appModule, services: services)
        self.appProcessor = appProcessor

        Task {
            await appProcessor.start(appContext: .appExtension, navigator: self, window: nil)
        }
    }
}

// MARK: - AppExtensionDelegate

extension CredentialProviderViewController: AppExtensionDelegate {
    var isInAppExtension: Bool { true }

    var authCompletionRoute: AppRoute {
        if isConfiguring {
            AppRoute.extensionSetup(.extensionActivation(type: .autofillExtension))
        } else {
            AppRoute.vault(.autofillList)
        }
    }

    var uri: String? {
        guard let serviceIdentifier = serviceIdentifiers.first else { return nil }
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
