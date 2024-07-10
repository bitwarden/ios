import UIKit

// MARK: - BitwardenTabBarController

/// A custom `UITabBarController` used for styling the tab items.
///
class BitwardenTabBarController: UITabBarController {
    // MARK: Lifecyle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationControllers()
    }

    /// Sets up the navigation controllers for the tab bar.
    private func setupNavigationControllers() {
        let vaultNavigator = UINavigationController()
        vaultNavigator.navigationBar.prefersLargeTitles = true

        let sendNavigator = UINavigationController()
        sendNavigator.navigationBar.prefersLargeTitles = true

        let generatorNavigator = UINavigationController()
        generatorNavigator.navigationBar.prefersLargeTitles = true

        let settingsNavigator = UINavigationController()
        settingsNavigator.navigationBar.prefersLargeTitles = true

        let tabsAndNavigators: [TabRoute: Navigator] = [
            .vault(.list): vaultNavigator,
            .send: sendNavigator,
            .generator(.generator()): generatorNavigator,
            .settings(.settings): settingsNavigator,
        ]

        setNavigators(tabsAndNavigators)
    }
}
