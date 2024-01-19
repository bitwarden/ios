import BitwardenShared
import MobileCoreServices
import UIKit

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
    var authCompletionRoute: BitwardenShared.AppRoute {
        if actionExtensionHelper.isAppExtensionSetup {
            AppRoute.extensionSetup(.extensionActivation(type: .appExtension))
        } else {
            AppRoute.vault(.autofillList)
        }
    }

    var isInAppExtension: Bool { true }

    var uri: String? { nil }

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
