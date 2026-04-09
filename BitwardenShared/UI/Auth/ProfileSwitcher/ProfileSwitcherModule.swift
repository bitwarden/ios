import BitwardenKit
import Foundation

// MARK: - ProfileSwitcherModule

/// An object that builds coordinators for the profile switcher sheet.
@MainActor
protocol ProfileSwitcherModule {
    /// Initializes a coordinator for navigating between `ProfileSwitcherRoute` objects.
    ///
    /// - Parameters:
    ///   - handler: An object that handles `ProfileSwitcherSheet` actions and effects.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    func makeProfileSwitcherCoordinator(
        handler: ProfileSwitcherHandler,
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<ProfileSwitcherRoute, Void>
}

extension DefaultAppModule: ProfileSwitcherModule {
    func makeProfileSwitcherCoordinator(
        handler: ProfileSwitcherHandler,
        stackNavigator: any StackNavigator,
    ) -> AnyCoordinator<ProfileSwitcherRoute, Void> {
        ProfileSwitcherCoordinator(
            handler: handler,
            services: services,
            stackNavigator: stackNavigator,
        ).asAnyCoordinator()
    }
}
