import BitwardenShared

// MARK: - MockAppModule

class MockAppModule: AppModule {
    var appCoordinator: AnyCoordinator<AppRoute>?

    func makeAppCoordinator(
        navigator: RootNavigator
    ) -> AnyCoordinator<AppRoute> {
        appCoordinator ?? MockCoordinator().asAnyCoordinator()
    }
}
