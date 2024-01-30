import BitwardenShared
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

class ActionViewController: UIViewController {
    // MARK: Properties

    /// The app's theme.
    var appTheme: AppTheme = .default

    /// The processor that manages application level logic.
    private var appProcessor: AppProcessor?

    /// A helper class for processing the input items from the extension.
    private let actionExtensionHelper = ActionExtensionHelper()

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        actionExtensionHelper.processInputItems(inputItems)

        initializeApp()
    }

    // MARK: Private

    /// Completes the extension request with a dictionary of item data to return to the host app.
    ///
    /// - Parameter itemData: The dictionary of item data to return to the host app from the extension.
    ///
    private func completeRequest(itemData: [String: Any]) {
        let resultsProvider = NSItemProvider(
            item: itemData as NSSecureCoding,
            typeIdentifier: UTType.propertyList.identifier
        )
        let resultsItem = NSExtensionItem()
        resultsItem.attachments = [resultsProvider]
        extensionContext?.completeRequest(returningItems: [resultsItem])
    }

    /// Sets up and initializes the app and UI.
    ///
    private func initializeApp() {
        let errorReporter = OSLogErrorReporter()
        let services = ServiceContainer(errorReporter: errorReporter)
        let appModule = DefaultAppModule(appExtensionDelegate: self, services: services)
        let appProcessor = AppProcessor(appModule: appModule, services: services)
        self.appProcessor = appProcessor

        let initialRoute: AppRoute? = if actionExtensionHelper.isAppExtensionSetup {
            AppRoute.extensionSetup(.extensionActivation(type: .appExtension))
        } else {
            nil
        }

        appProcessor.start(
            appContext: .appExtension,
            initialRoute: initialRoute,
            navigator: self,
            window: nil
        )
    }
}

// MARK: - AppExtensionDelegate

extension ActionViewController: AppExtensionDelegate {
    var authCompletionRoute: AppRoute {
        actionExtensionHelper.authCompletionRoute
    }

    var isInAppExtension: Bool { true }

    var isInAppExtensionSaveLoginFlow: Bool {
        actionExtensionHelper.isProviderSaveLogin
    }

    var uri: String? { actionExtensionHelper.uri }

    func completeAutofillRequest(username: String, password: String, fields: [(String, String)]?) {
        let itemData = actionExtensionHelper.itemDataToCompleteRequest(
            username: username,
            password: password,
            fields: fields ?? []
        )
        completeRequest(itemData: itemData)
    }

    func didCancel() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}

// MARK: - RootNavigator

extension ActionViewController: RootNavigator {
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
