import BitwardenKit

// MARK: - ProfileSwitcherProcessor

/// The processor used to manage state and handle actions for the profile switcher sheet.
/// In practice, it just acts largely as a passthrough for the `ProfileSwitcherHandler` so as to
/// preserve flows in apps running on iOS pre-26.
final class ProfileSwitcherProcessor: StateProcessor<
    ProfileSwitcherState,
    ProfileSwitcherAction,
    ProfileSwitcherEffect,
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<ProfileSwitcherRoute, Void>

    /// The services used by this processor.
    private let services: Services

    /// An object that handles `ProfileSwitcherView` actions and effects.
    private let handler: ProfileSwitcherHandler

    // MARK: Initialization

    /// Creates a new `ProfileSwitcherProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - handler: An object that handles `ProfileSwitcherView` actions and effects.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of this processor.
    init(
        coordinator: AnyCoordinator<ProfileSwitcherRoute, Void>,
        handler: ProfileSwitcherHandler,
        services: Services,
        state: ProfileSwitcherState,
    ) {
        self.coordinator = coordinator
        self.handler = handler
        self.services = services
        super.init(state: state)
    }

    override func receive(_ action: ProfileSwitcherAction) {
        handler.handleProfileSwitcherAction(action)
    }

    override func perform(_ effect: ProfileSwitcherEffect) async {
        await handler.handleProfileSwitcherEffect(effect)
    }
}
