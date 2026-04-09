import BitwardenKit
import BitwardenKitMocks
import Testing

@testable import AuthenticatorShared

@MainActor
struct TabCoordinatorTests {
    // MARK: Properties

    let errorReporter = MockErrorReporter()
    let itemListDelegate = MockItemListCoordinatorDelegate()
    let module = MockAppModule()
    let rootNavigator = MockRootNavigator()
    let tabNavigator = MockTabNavigator()
    let subject: TabCoordinator

    // MARK: Initialization

    init() {
        subject = TabCoordinator(
            errorReporter: errorReporter,
            itemListDelegate: itemListDelegate,
            module: module,
            rootNavigator: rootNavigator,
            tabNavigator: tabNavigator,
        )
    }

    // MARK: Tests

    /// `start()` shows the tab navigator as a child of the root navigator.
    @Test
    func start_showsTabNavigator() {
        subject.start()

        #expect(rootNavigator.navigatorShown === tabNavigator)
    }

    /// `start()` sets up the tab navigator with the correct navigators.
    @Test
    func start_setsNavigators() {
        subject.start()

        #expect(tabNavigator.navigators.count == 2)
    }

    /// `navigate(to:)` with `.itemList` navigates to the item list route.
    @Test
    func navigateTo_itemList() {
        subject.start()

        subject.navigate(to: .itemList(.list), context: nil)

        #expect(module.itemListCoordinator.routes == [.list])
        #expect(module.itemListCoordinatorDelegate === itemListDelegate)
        #expect(tabNavigator.selectedIndex == TabRoute.itemList(.list).index)
    }

    /// `navigate(to:)` with `.settings` navigates to the settings route.
    @Test
    func navigateTo_settings() {
        subject.start()

        subject.navigate(to: .settings(.settings), context: nil)

        #expect(module.settingsCoordinator.routes == [.settings])
        #expect(tabNavigator.selectedIndex == TabRoute.settings(.settings).index)
    }
}
