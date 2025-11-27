import BitwardenKit
import SwiftUI

// MARK: - TutorialCoordinator

/// A coordinator that manages navigation in the tutorial.
///
final class TutorialCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    /// The module types required for creating child coordinators.
    typealias Module = DefaultAppModule

    typealias Services = HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// The module used to create child coordinators.
    private let module: Module

    /// The services used
    private let services: Services

    // MARK: Properties

    /// The stack navigator
    private(set) weak var stackNavigator: StackNavigator?

    // Initialization

    /// Creates a new `TutorialCoordinator`
    ///
    /// - Parameters:
    ///   - module: The module used to create child coordinators.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        module: Module,
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.module = module
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func handleEvent(_ event: TutorialEvent, context: AnyObject?) async {}

    func navigate(to route: TutorialRoute, context: AnyObject?) {
        switch route {
        case .dismiss:
            services.stateService.hasSeenWelcomeTutorial = true
            stackNavigator?.dismiss()
        case .tutorial:
            showTutorial()
        }
    }

    func start() {
        navigate(to: .tutorial)
    }

    // MARK: Private Methods

    /// Shows the tutorial.
    ///
    private func showTutorial() {
        let processor = TutorialProcessor(
            coordinator: asAnyCoordinator(),
            state: TutorialState(),
        )
        let view = TutorialView(store: Store(processor: processor))
        stackNavigator?.push(view)
    }
}

// MARK: - HasErrorAlertServices

extension TutorialCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
