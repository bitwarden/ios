import BitwardenShared
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: Properties

    /// The main window for this scene.
    var window: UIWindow?

    // MARK: Methods

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let appProcessor = (UIApplication.shared.delegate as? AppDelegateType)?.appProcessor,
              let windowScene = scene as? UIWindowScene
        else {
            return
        }

        let appWindow = UIWindow(windowScene: windowScene)
        let rootViewController = RootViewController()
        appProcessor.start(navigator: rootViewController)

        appWindow.rootViewController = rootViewController
        appWindow.makeKeyAndVisible()
        window = appWindow
    }
}
