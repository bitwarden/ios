import BitwardenShared
import SwiftUI
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
        guard let windowScene = scene as? UIWindowScene else { return }
        guard let appProcessor = (UIApplication.shared.delegate as? AppDelegateType)?.appProcessor else {
            if (UIApplication.shared.delegate as? AppDelegateType)?.isTesting == true {
                // If the app is running tests, show a testing view.
                window = UIWindow(windowScene: windowScene)
                window?.makeKeyAndVisible()
                window?.rootViewController = UIHostingController(rootView: ZStack {
                    Color("backgroundSplash").ignoresSafeArea()

                    Image("logoBitwarden")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 238)
                })
            }
            return
        }

        let appWindow = UIWindow(windowScene: windowScene)
        let rootViewController = RootViewController()
        appProcessor.start(
            appContext: .mainApp,
            navigator: rootViewController,
            window: appWindow
        )

        appWindow.rootViewController = rootViewController
        appWindow.makeKeyAndVisible()
        window = appWindow
    }
}
