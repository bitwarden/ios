import BitwardenKit
import BitwardenKitMocks
import Testing

@testable import AuthenticatorShared

@MainActor
struct ItemListCoordinatorTests {
    // MARK: Properties

    let delegate = MockItemListCoordinatorDelegate()
    let module = MockAppModule()
    let stackNavigator = MockStackNavigator()
    let subject: ItemListCoordinator
    let totpExpirationManagerFactory = MockTOTPExpirationManagerFactory()

    // MARK: Initialization

    init() {
        totpExpirationManagerFactory.createResults = [
            MockTOTPExpirationManager(),
            MockTOTPExpirationManager(),
        ]

        subject = ItemListCoordinator(
            delegate: delegate,
            module: module,
            services: ServiceContainer.withMocks(
                totpExpirationManagerFactory: totpExpirationManagerFactory,
            ),
            stackNavigator: stackNavigator,
        )
    }

    // MARK: Tests

    /// `navigate(to:)` with `.editItem` presents the edit item view.
    @Test
    func navigateTo_editItem() throws {
        let item = AuthenticatorItemView.fixture()

        subject.navigate(to: .editItem(item: item), context: nil)

        #expect(module.authenticatorItemCoordinator.isStarted)
        #expect(module.authenticatorItemCoordinator.routes == [.editAuthenticatorItem(item)])
    }

    /// `navigate(to:)` with `.flightRecorderSettings` calls the delegate's `switchToSettingsTab` method.
    @Test
    func navigateTo_flightRecorderSettings() {
        subject.navigate(to: .flightRecorderSettings, context: nil)

        #expect(delegate.switchToSettingsTabRoute == .settings)
    }

    /// `navigate(to:)` with `.list` pushes the item list view onto the stack.
    @Test
    func navigateTo_list() throws {
        subject.navigate(to: .list, context: nil)

        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .replaced)
        #expect(action.view is ItemListView)
    }
}

// MARK: - MockItemListCoordinatorDelegate

class MockItemListCoordinatorDelegate: ItemListCoordinatorDelegate {
    var switchToSettingsTabRoute: SettingsRoute?

    func switchToSettingsTab(route: SettingsRoute) {
        switchToSettingsTabRoute = route
    }
}
