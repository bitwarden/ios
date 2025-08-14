import AuthenticationServices
import BitwardenShared
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: Properties

    /// Whether the app is still starting up. This ensures the splash view isn't dismissed on start
    /// up until the processor has shown the initial view.
    var isStartingUp = true

    /// Window shown as either the splash view on startup or when the app is backgrounded to
    /// prevent private information from being visible in the app switcher.
    var splashWindow: UIWindow?

    /// The main window for this scene.
    var window: UIWindow?

    /// The processor that manages application level logic.
    var appProcessor: AppProcessor? {
        (UIApplication.shared.delegate as? AppDelegateType)?.appProcessor
    }

    // MARK: Methods

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
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
        let appWindow = ShakeWindow(windowScene: windowScene) { [weak self] in
            #if DEBUG_MENU
            self?.appProcessor?.showDebugMenu()
            #endif
        }
        appWindow.rootViewController = rootViewController
        appWindow.makeKeyAndVisible()
        window = appWindow

        #if DEBUG_MENU
        addTapGestureRecognizer(to: appWindow)
        #endif

        // Splash window. This is initially visible until the app's processor has finished starting.
        splashWindow = buildSplashWindow(windowScene: windowScene)

        // Start the app's processor and show the splash view until the initial view is shown.
        Task {
            await appProcessor.start(
                appContext: .mainApp,
                navigator: rootViewController,
                splashWindow: splashWindow,
                window: appWindow
            )
            hideSplash()
            isStartingUp = false

            if let userActivity = connectionOptions.userActivities.first,
               userActivity.activityType == NSUserActivityTypeBrowsingWeb,
               let incomingURL = userActivity.webpageURL {
                appProcessor.handleAppLinks(incomingURL: incomingURL)
            } else if let url = connectionOptions.urlContexts.first?.url {
                await appProcessor.openUrl(url)
            }

            #if SUPPORTS_CXP

            if #available(iOS 26.0, *),
               let userActivity = connectionOptions.userActivities.first {
                await checkAndHandleCredentialExchangeActivity(appProcessor: appProcessor, userActivity: userActivity)
            }

            #endif
        }
    }

    func scene(
        _ scene: UIScene,
        continue userActivity: NSUserActivity
    ) {
        guard let appProcessor else {
            return
        }

        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let incomingURL = userActivity.webpageURL {
            appProcessor.handleAppLinks(incomingURL: incomingURL)
        }

        #if SUPPORTS_CXP

        if #available(iOS 26.0, *) {
            Task {
                await checkAndHandleCredentialExchangeActivity(appProcessor: appProcessor, userActivity: userActivity)
            }
        }

        #endif
    }

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        guard
            let url = urlContexts.first?.url,
            let appProcessor
        else { return }

        Task {
            await appProcessor.openUrl(url)
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
    ///
    private func buildSplashWindow(windowScene: UIWindowScene) -> UIWindow {
        let window = UIWindow(windowScene: windowScene)
        window.isHidden = false
        window.rootViewController = UIStoryboard(
            name: "LaunchScreen",
            bundle: .main
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

    #if DEBUG_MENU
    /// Handle the tap gesture and launch the debug menu.
    @objc
    private func handleTapGesture() {
        appProcessor?.showDebugMenu()
    }
    #endif

    #if DEBUG_MENU
    /// Add the tap gesture recognizer to the window.
    private func addTapGestureRecognizer(to window: UIWindow) {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapGesture)
        )
        tapGesture.numberOfTapsRequired = 3
        tapGesture.numberOfTouchesRequired = 1
        window.addGestureRecognizer(tapGesture)
    }
    #endif
}

// MARK: - SceneDelegate 26.0

#if SUPPORTS_CXP

@available(iOS 26.0, *)
extension SceneDelegate {
    /// Checks  whether there is an `ASCredentialExchangeActivity` in the `userActivity` and handles it.
    /// - Parameters:
    ///   - appProcessor: The `AppProcessor` to handle the logic.
    ///   - userActivity: The activity to handle.
    private func checkAndHandleCredentialExchangeActivity(
        appProcessor: AppProcessor,
        userActivity: NSUserActivity
    ) async {
        guard userActivity.activityType == ASCredentialExchangeActivity,
              let token = userActivity.userInfo?[ASCredentialImportToken] as? UUID else {
            return
        }

        await appProcessor.handleImportCredentials(credentialImportToken: token)
    }
}

#endif
