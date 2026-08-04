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

    /// The set of tabs currently visible in the tab bar, keyed by route index.
    private var currentTabs: [Int: Navigator] = [:]

    /// The error reporter used by the tab coordinator.
    private var errorReporter: ErrorReporter

    /// The coordinator used to navigate to `GeneratorRoute`s.
    private var generatorCoordinator: AnyCoordinator<GeneratorRoute, Void>?

    /// The navigator used by the generator coordinator.
    private weak var generatorNavigator: StackNavigator?

    /// The module used to create child coordinators.
    private let module: Module

    /// A task to handle organization streams.
    private var organizationStreamTask: Task<Void, Error>?

    /// The policy service used to check for active policies.
    private let policyService: PolicyService

    /// The coordinator used to navigate to `SendRoute`s.
    private var sendCoordinator: AnyCoordinator<SendRoute, Void>?

    /// The navigator used by the send coordinator.
    private weak var sendNavigator: StackNavigator?

    /// The coordinator used to navigate to `SettingsRoute`s.
    private var settingsCoordinator: AnyCoordinator<SettingsRoute, SettingsEvent>?

    /// The navigator used by the settings coordinator.
    private weak var settingsNavigator: StackNavigator?

    /// A delegate of the `SettingsCoordinator`.
    private weak var settingsDelegate: SettingsCoordinatorDelegate?

    /// The coordinator used to navigate to `VaultRoute`s.
    private var vaultCoordinator: AnyCoordinator<VaultRoute, AuthAction>?

    /// A delegate of the `VaultCoordinator`.
    private weak var vaultDelegate: VaultCoordinatorDelegate?

    /// The navigator used by the vault coordinator.
    private weak var vaultNavigator: StackNavigator?

    /// A vault repository used to the vault tab title.
    private var vaultRepository: VaultRepository

    // MARK: Initialization

    /// Creates a new `TabCoordinator`.
    ///
    /// - Parameters:
    ///   - errorReporter: The error reporter used by the tab coordinator.
    ///   - module: The module used to create child coordinators.
    ///   - policyService: The policy service used to check for active policies.
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - settingsDelegate: A delegate of the `SettingsCoordinator`.
    ///   - tabNavigator: The tab navigator that is managed by this coordinator.
    ///   - vaultDelegate: A delegate of the `VaultCoordinator`.
    ///   - vaultRepository: A vault repository used to the vault tab title.
    ///
    init(
        errorReporter: ErrorReporter,
        module: Module,
        policyService: PolicyService,
        rootNavigator: RootNavigator,
        settingsDelegate: SettingsCoordinatorDelegate,
        tabNavigator: TabNavigator,
        vaultDelegate: VaultCoordinatorDelegate,
        vaultRepository: VaultRepository,
    ) {
        self.errorReporter = errorReporter
        self.module = module
        self.policyService = policyService
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
        if case .send = route, !currentTabs.isEmpty, currentTabs[route.index] == nil {
            return
        }

        tabNavigator?.selectedIndex = visualIndex(for: route)
        switch route {
        case let .vault(vaultRoute):
            show(vaultRoute: vaultRoute, context: context)
        case .send:
            break
        case .generator:
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
            message: "`showErrorAlert(error:tryAgain:onDismissed:)` is not supported from TabCoordinator.",
        ))
    }

    func start() {
        guard let rootNavigator, let tabNavigator, let settingsDelegate, let vaultDelegate else { return }

        rootNavigator.show(child: tabNavigator)

        let vaultNav = module.makeNavigationController()
        vaultNav.navigationBar.prefersLargeTitles = false
        vaultNav.navigationBar.accessibilityIdentifier = "MainHeaderBar"
        vaultCoordinator = module.makeVaultCoordinator(
            delegate: vaultDelegate,
            stackNavigator: vaultNav,
        )
        vaultNavigator = vaultNav

        let sendNav = createSendNavigator()
        sendNavigator = sendNav

        let generatorNav = module.makeNavigationController()
        generatorNav.navigationBar.prefersLargeTitles = false
        generatorNav.navigationBar.accessibilityIdentifier = "MainHeaderBar"
        // Remove the hairline divider under the navigation bar to make it appear that the segmented
        // control is part of the navigation bar.
        generatorNav.removeHairlineDivider()
        generatorCoordinator = module.makeGeneratorCoordinator(
            delegate: nil,
            stackNavigator: generatorNav,
        )
        generatorCoordinator?.start()
        generatorNavigator = generatorNav

        let settingsNav = module.makeNavigationController()
        settingsNav.navigationBar.prefersLargeTitles = false
        settingsNav.navigationBar.accessibilityIdentifier = "MainHeaderBar"
        let settingsCoord = module.makeSettingsCoordinator(
            delegate: settingsDelegate,
            stackNavigator: settingsNav,
        )
        settingsCoord.start()
        settingsCoordinator = settingsCoord
        settingsNavigator = settingsNav

        updateTabs(isSendEnabled: true)

        Task { [weak self, policyService] in
            let isSendDisabled = await policyService.getSendPolicyOptions().isSendDisabled
            await MainActor.run { self?.updateTabs(isSendEnabled: !isSendDisabled) }
        }
        streamOrganizations()
    }

    // MARK: Private Methods

    /// Creates and configures a navigation controller for the Send tab, initializing and starting its coordinator.
    ///
    /// - Returns: A configured `UINavigationController` for the Send tab.
    ///
    private func createSendNavigator() -> UINavigationController {
        let sendNav = module.makeNavigationController()
        sendNav.navigationBar.prefersLargeTitles = false
        sendNav.navigationBar.accessibilityIdentifier = "MainHeaderBar"
        sendCoordinator = module.makeSendCoordinator(
            stackNavigator: sendNav,
        )
        sendCoordinator?.start()
        return sendNav
    }

    /// Streams the user's organizations, updating the vault title and send tab visibility reactively.
    private func streamOrganizations() {
        organizationStreamTask = Task { [errorReporter, tabNavigator, vaultRepository, policyService] in
            do {
                for try await organizations in try await vaultRepository.organizationsPublisher() {
                    guard let navigator = tabNavigator?.navigator(for: TabRoute.vault(.list)) else { return }
                    let canShowVaultFilter = await vaultRepository.canShowVaultFilter()
                    if organizations.isEmpty || !canShowVaultFilter {
                        navigator.rootViewController?.title = Localizations.myVault
                    } else {
                        navigator.rootViewController?.title = Localizations.vaults
                    }

                    let isSendDisabled = await policyService.getSendPolicyOptions().isSendDisabled
                    await MainActor.run { [weak self] in
                        self?.updateTabs(isSendEnabled: !isSendDisabled)
                    }
                }
            } catch {
                errorReporter.log(error: error)
            }
        }
    }

    /// Rebuilds the visible tab set, adding or removing the Send tab based on whether it's enabled.
    ///
    /// - Parameter isSendEnabled: Whether the `Send` tab is enabled.
    ///
    @MainActor
    private func updateTabs(isSendEnabled: Bool) {
        if (currentTabs.count == 3 && !isSendEnabled)
            || (currentTabs.count == 4 && isSendEnabled) {
            return
        }

        guard let vaultNavigator,
              let generatorNavigator,
              let settingsNavigator
        else {
            return
        }

        var sendNv: UINavigationController?
        if sendNavigator == nil, isSendEnabled {
            sendNv = createSendNavigator()
            sendNavigator = sendNv
        }

        var tabs: [TabRoute: Navigator] = [
            .vault(.list): vaultNavigator,
            .generator(.generator()): generatorNavigator,
            .settings(.settings(.tab)): settingsNavigator,
        ]
        if isSendEnabled {
            tabs[.send] = sendNavigator
        }
        currentTabs = Dictionary(uniqueKeysWithValues: tabs.map { ($0.key.index, $0.value) })
        tabNavigator?.setNavigators(tabs)
    }

    /// Returns the visual (UITabBarController) index for a route given the current active tab set.
    ///
    /// When Send is hidden, Generator and Settings shift left by one position. This computes
    /// the actual position rather than using the fixed `TabRoute.index` value.
    ///
    /// - Parameter route: The tab route to look up.
    /// - Returns: The visual tab bar index for the route.
    ///
    private func visualIndex(for route: TabRoute) -> Int {
        let sorted = currentTabs.keys.sorted()
        return sorted.firstIndex(of: route.index) ?? route.index
    }
}
