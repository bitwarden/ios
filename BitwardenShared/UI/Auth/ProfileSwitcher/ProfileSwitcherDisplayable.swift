import BitwardenKit

// MARK: - ProfileSwitcherDisplayable

/// A protocol for objects that can display a profile switcher.
///
@MainActor
protocol ProfileSwitcherDisplayable: HasStackNavigator {}

extension ProfileSwitcherDisplayable {
    func showProfileSwitcher(
        handler: any ProfileSwitcherHandler,
        module: any NavigatorBuilderModule & ProfileSwitcherModule,
    ) {
        let navigationController = module.makeNavigationController()
        let coordinator = module.makeProfileSwitcherCoordinator(
            handler: handler,
            stackNavigator: navigationController,
        )
        coordinator.start()
        coordinator.navigate(to: .open, context: nil)
        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            sheet.prefersGrabberVisible = true
        }
        stackNavigator?.present(navigationController)
    }
}
