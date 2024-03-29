@testable import AuthenticatorShared

// MARK: - MockAppModule

class MockAppModule:
    AppModule,
    VaultModule {

    var appCoordinator = MockCoordinator<AppRoute, AppEvent>()
    var vaultCoordinator = MockCoordinator<VaultRoute, AuthAction>()

    func makeAppCoordinator(
        appContext _: AppContext,
        navigator _: RootNavigator
    ) -> AnyCoordinator<AppRoute, AppEvent> {
        appCoordinator.asAnyCoordinator()
    }

    func makeVaultCoordinator(
        delegate _: AuthenticatorShared.VaultCoordinatorDelegate,
        stackNavigator _: AuthenticatorShared.StackNavigator
    ) -> AuthenticatorShared.AnyCoordinator<AuthenticatorShared.VaultRoute, AuthAction> {
        vaultCoordinator.asAnyCoordinator()
    }
}
