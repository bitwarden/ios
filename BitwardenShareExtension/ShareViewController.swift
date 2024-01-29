import BitwardenShared
import Social
import UIKit

// MARK: - ShareViewController

/// The main interface for the Share Extension. Handles item decoding and app processor
/// initialization.
///
class ShareViewController: UIViewController {
    // MARK: Properties

    /// The app's theme.
    var appTheme: AppTheme = .default

    var authCompletionRoute: AppRoute = .sendItem(.add(content: nil, hasPremium: false))

    /// The processor that manages application level logic.
    private var appProcessor: AppProcessor?

    /// A helper class for processing the input items from the extension.
    private let shareExtensionHelper = ShareExtensionHelper()

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            close()
            return
        }

        Task {
            guard let content = await shareExtensionHelper.processInputItems(inputItems) else {
                close()
                return
            }
            await initializeApp(with: content)
        }
    }

    // MARK: Private

    /// Closes the extension.
    ///
    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    /// Sets up and initializes the app and UI.
    ///
    private func initializeApp(with content: AddSendContentType) async {
        let errorReporter = OSLogErrorReporter()
        let services = ServiceContainer(errorReporter: errorReporter)
        let appModule = DefaultAppModule(appExtensionDelegate: self, services: services)
        let appProcessor = AppProcessor(appModule: appModule, services: services)
        self.appProcessor = appProcessor

        let hasPremium = try? await services.sendRepository.doesActiveAccountHavePremium()

        authCompletionRoute = .sendItem(.add(content: content, hasPremium: hasPremium ?? false))

        appProcessor.start(
            appContext: .appExtension,
            initialRoute: nil,
            navigator: self,
            window: nil
        )
    }
}

// MARK: - AppExtensionDelegate

extension ShareViewController: AppExtensionDelegate {
    var isInAppExtension: Bool { true }

    var uri: String? { nil }

    func didCancel() {
        close()
    }
}

// MARK: - RootNavigator

extension ShareViewController: RootNavigator {
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
