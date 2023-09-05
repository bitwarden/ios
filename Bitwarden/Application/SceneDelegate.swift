import BitwardenShared
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: Properties

    /// The root module to use to create sub-coordinators.
    var appModule: AppModule = DefaultAppModule()

    /// The root coordinator of this scene.
    var appCoordinator: AnyCoordinator<AppRoute>?

    /// The main window for this scene.
    var window: UIWindow?

    // MARK: Methods

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }

        let appWindow = UIWindow(windowScene: windowScene)
        let rootViewController = RootViewController()
        let coordinator = appModule.makeAppCoordinator(navigator: rootViewController)
        coordinator.start()

        appWindow.rootViewController = rootViewController
        appWindow.makeKeyAndVisible()
        appCoordinator = coordinator
        window = appWindow
    }
}
