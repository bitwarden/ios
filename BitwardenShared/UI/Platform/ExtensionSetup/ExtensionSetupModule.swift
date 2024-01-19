import UIKit

// MARK: - ExtensionSetupModule

/// An object that builds coordinators for the extension setup flow.
@MainActor
protocol ExtensionSetupModule {
    /// Initializes a coordinator for navigating between `ExtensionSetup` routes.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `ExtensionSetupRoute`s.
    ///
    func makeExtensionSetupCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<ExtensionSetupRoute>
}

// MARK: - DefaultAppModule

extension DefaultAppModule: ExtensionSetupModule {
    func makeExtensionSetupCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<ExtensionSetupRoute> {
        ExtensionSetupCoordinator(
            appExtensionDelegate: appExtensionDelegate,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
