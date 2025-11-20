import BitwardenKit
import SwiftUI
import TestHarnessShared
import UIKit

/// The app's `UIWindowSceneDelegate` which manages the app's window and scene lifecycle.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: Properties

    /// The processor that manages application level logic.
    var appProcessor: AppProcessor? {
        (UIApplication.shared.delegate as? AppDelegateType)?.appProcessor
    }

    /// Whether the app is still starting up. This ensures the splash view isn't dismissed on start
    /// up until the processor has shown the initial view.
    var isStartingUp = true

    /// Window shown as either the splash view on startup or when the app is backgrounded to
    /// prevent private information from being visible in the app switcher.
    var splashWindow: UIWindow?

    /// The main window for this scene.
    var window: UIWindow?

    // MARK: Methods

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions,
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        guard let appProcessor else {
            if (UIApplication.shared.delegate as? AppDelegateType)?.isTesting == true {
                // If the app is running tests, show a testing view.
                window = buildSplashWindow(windowScene: windowScene)
                window?.makeKeyAndVisible()
            }
            return
        }

        let rootViewController = RootViewController()
        let appWindow = UIWindow(windowScene: windowScene)
        appWindow.rootViewController = rootViewController
        appWindow.makeKeyAndVisible()
        window = appWindow

        // Splash window. This is initially visible until the app's processor has finished starting.
        splashWindow = buildSplashWindow(windowScene: windowScene)

        // Start the app's processor and show the splash view until the initial view is shown.
        Task {
            await appProcessor.start(
                navigator: rootViewController,
                window: appWindow,
            )
            hideSplash()
            isStartingUp = false
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        showSplash()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard !isStartingUp else { return }
        hideSplash()
    }

    // MARK: Private

    /// Builds the splash window for display in the specified window scene.
    ///
    /// - Parameter windowScene: The window scene that the splash window will be shown in.
    /// - Returns: A window containing the splash view.
    private func buildSplashWindow(windowScene: UIWindowScene) -> UIWindow {
        let window = UIWindow(windowScene: windowScene)
        window.isHidden = false
        window.rootViewController = UIStoryboard(
            name: "LaunchScreen",
            bundle: .main,
        ).instantiateInitialViewController()
        window.windowLevel = UIWindow.Level.alert + 1
        return window
    }

    /// Hides the splash view.
    private func hideSplash() {
        UIView.animate(withDuration: UI.duration(0.4)) {
            self.splashWindow?.alpha = 0
        }
    }

    /// Shows the splash view.
    private func showSplash() {
        splashWindow?.alpha = 1
    }
}
