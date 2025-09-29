import BitwardenKit
import BitwardenResources
import SwiftUI
import UIKit

// MARK: - TabCoordinator

/// A coordinator that manages navigation in the tab interface.
///
final class TabCoordinator: Coordinator, HasTabNavigator {
    // MARK: Types

    /// The module types required by this coordinator for creating child coordinators.
    typealias Module = GeneratorModule
        & NavigatorBuilderModule
        & SendModule
        & SettingsModule
        & VaultModule

    // MARK: Properties

    /// The root navigator used to display this coordinator's interface.
    weak var rootNavigator: (any RootNavigator)?

    /// The tab navigator that is managed by this coordinator.
    private(set) weak var tabNavigator: TabNavigator?

    // MARK: Private Properties

    /// The error reporter used by the tab coordinator.
    private var errorReporter: ErrorReporter

    /// The coordinator used to navigate to `GeneratorRoute`s.
    private var generatorCoordinator: AnyCoordinator<GeneratorRoute, Void>?

    /// The module used to create child coordinators.
    private let module: Module

    /// A task to handle organization streams.
    private var organizationStreamTask: Task<Void, Error>?

    /// The coordinator used to navigate to `SendRoute`s.
    private var sendCoordinator: AnyCoordinator<SendRoute, Void>?

    /// The coordinator used to navigate to `SettingsRoute`s.
    private var settingsCoordinator: AnyCoordinator<SettingsRoute, SettingsEvent>?

    /// A delegate of the `SettingsCoordinator`.
    private weak var settingsDelegate: SettingsCoordinatorDelegate?

    /// The coordinator used to navigate to `VaultRoute`s.
    private var vaultCoordinator: AnyCoordinator<VaultRoute, AuthAction>?

    /// A delegate of the `VaultCoordinator`.
    private weak var vaultDelegate: VaultCoordinatorDelegate?

    /// A vault repository used to the vault tab title.
    private var vaultRepository: VaultRepository

    // MARK: Initialization

    /// Creates a new `TabCoordinator`.
    ///
    /// - Parameters:
    ///   - errorReporter: The error reporter used by the tab coordinator.
    ///   - module: The module used to create child coordinators.
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - settingsDelegate: A delegate of the `SettingsCoordinator`.
    ///   - tabNavigator: The tab navigator that is managed by this coordinator.
    ///   - vaultDelegate: A delegate of the `VaultCoordinator`.
    ///   - vaultRepository: A vault repository used to the vault tab title.
    ///
    init(
        errorReporter: ErrorReporter,
        module: Module,
        rootNavigator: RootNavigator,
        settingsDelegate: SettingsCoordinatorDelegate,
        tabNavigator: TabNavigator,
        vaultDelegate: VaultCoordinatorDelegate,
        vaultRepository: VaultRepository
    ) {
        self.errorReporter = errorReporter
        self.module = module
        self.rootNavigator = rootNavigator
        self.settingsDelegate = settingsDelegate
        self.tabNavigator = tabNavigator
        self.vaultDelegate = vaultDelegate
        self.vaultRepository = vaultRepository
    }

    deinit {
        organizationStreamTask?.cancel()
        organizationStreamTask = nil
    }

    // MARK: Methods

    func navigate(to route: TabRoute, context: AnyObject?) {
        tabNavigator?.selectedIndex = route.index
        switch route {
        case let .vault(vaultRoute):
            show(vaultRoute: vaultRoute, context: context)
        case .send:
            // TODO: BIT-249 Add show send function for navigating to a send route
            break
        case .generator:
            // TODO: BIT-327 Add show generation function for navigation to a generator route
            break
        case let .settings(settingsRoute):
            settingsCoordinator?.start()
            settingsCoordinator?.navigate(to: settingsRoute, context: context)
        }
    }

    func show(vaultRoute: VaultRoute, context: AnyObject?) {
        vaultCoordinator?.navigate(to: vaultRoute, context: context)
    }

    func showErrorAlert(error: any Error, tryAgain: (() async -> Void)?, onDismissed: (() -> Void)?) async {
        errorReporter.log(error: BitwardenError.generalError(
            type: "TabCoordinator: `showErrorAlert` Not Supported",
            message: "`showErrorAlert(error:tryAgain:onDismissed:)` is not supported from TabCoordinator."
        ))
    }

    func start() {
        guard let rootNavigator, let tabNavigator, let settingsDelegate, let vaultDelegate else { return }

        rootNavigator.show(child: tabNavigator)

        let vaultNavigator = module.makeNavigationController()
        vaultNavigator.navigationBar.prefersLargeTitles = false
        vaultNavigator.navigationBar.accessibilityIdentifier = "MainHeaderBar"
        vaultCoordinator = module.makeVaultCoordinator(
            delegate: vaultDelegate,
            stackNavigator: vaultNavigator
        )

        let sendNavigator = module.makeNavigationController()
        sendNavigator.navigationBar.prefersLargeTitles = false
        sendNavigator.navigationBar.accessibilityIdentifier = "MainHeaderBar"
        sendCoordinator = module.makeSendCoordinator(
            stackNavigator: sendNavigator
        )
        sendCoordinator?.start()

        let generatorNavigator = module.makeNavigationController()
        generatorNavigator.navigationBar.prefersLargeTitles = false
        generatorNavigator.navigationBar.accessibilityIdentifier = "MainHeaderBar"
        // Remove the hairline divider under the navigation bar to make it appear that the segmented
        // control is part of the navigation bar.
        generatorNavigator.removeHairlineDivider()
        generatorCoordinator = module.makeGeneratorCoordinator(
            delegate: nil,
            stackNavigator: generatorNavigator
        )
        generatorCoordinator?.start()

        let settingsNavigator = module.makeNavigationController()
        settingsNavigator.navigationBar.prefersLargeTitles = false
        settingsNavigator.navigationBar.accessibilityIdentifier = "MainHeaderBar"
        let settingsCoordinator = module.makeSettingsCoordinator(
            delegate: settingsDelegate,
            stackNavigator: settingsNavigator
        )
        settingsCoordinator.start()
        self.settingsCoordinator = settingsCoordinator

        let tabsAndNavigators: [TabRoute: Navigator] = [
            .vault(.list): vaultNavigator,
            .send: sendNavigator,
            .generator(.generator()): generatorNavigator,
            .settings(.settings(.tab)): settingsNavigator,
        ]
        tabNavigator.setNavigators(tabsAndNavigators)
        streamOrganizations()
    }

    /// Streams the user's organizations.
    private func streamOrganizations() {
        organizationStreamTask = Task { [errorReporter, tabNavigator, vaultRepository] in
            do {
                for try await organizations in try await vaultRepository.organizationsPublisher() {
                    guard let navigator = tabNavigator?.navigator(for: TabRoute.vault(.list)) else { return }
                    let canShowVaultFilter = await vaultRepository.canShowVaultFilter()
                    if organizations.isEmpty || !canShowVaultFilter {
                        navigator.rootViewController?.title = Localizations.myVault
                    } else {
                        navigator.rootViewController?.title = Localizations.vaults
                    }
                }
            } catch {
                errorReporter.log(error: error)
            }
        }
    }
}
