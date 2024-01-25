import BitwardenShared
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: Properties

    /// Window shown when the app is backgrounded to prevent private information from being visible in the app switcher.
    var privacyWindow: UIWindow?

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

        // Privacy window.
        privacyWindow = UIWindow(windowScene: windowScene)
        privacyWindow?.windowLevel = UIWindow.Level.alert + 1

        let hostingController = UIHostingController(rootView: PrivacyView())
        privacyWindow?.rootViewController = hostingController
        privacyWindow?.isHidden = false
        privacyWindow?.alpha = 0
    }

    func sceneWillResignActive(_ scene: UIScene) {
        privacyWindow?.alpha = 1
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        UIView.animate(withDuration: UI.duration(0.4)) {
            self.privacyWindow?.alpha = 0
        }
    }
}

// MARK: - PrivacyView

/// The screen shown when the app is backgrounded to prevent private information
/// from being visible in the app switcher.
///
public struct PrivacyView: View {
    public var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                Image(decorative: Asset.Images.logo)
                Spacer()
            }
            Spacer()
        }
        .background(Color(asset: Asset.Colors.backgroundPrimary))
    }
}
