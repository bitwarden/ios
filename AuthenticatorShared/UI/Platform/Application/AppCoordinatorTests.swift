import BitwardenKit
import BitwardenKitMocks
import Testing

@testable import AuthenticatorShared

@MainActor
struct AppCoordinatorTests {
    // MARK: Properties

    let module = MockAppModule()
    let rootNavigator = MockRootNavigator()
    let services = ServiceContainer.withMocks()
    let subject: AppCoordinator

    // MARK: Initialization

    init() {
        subject = AppCoordinator(
            appContext: .mainApp,
            module: module,
            rootNavigator: rootNavigator,
            services: services,
        )
    }

    // MARK: Tests

    /// `switchToSettingsTab(route:)` navigates to the settings tab with the specified route.
    @Test
    func switchToSettingsTab_navigatesToSettingsTab() {
        subject.switchToSettingsTab(route: .settings)

        #expect(module.tabCoordinator.routes.last == .settings(.settings))
    }

    /// `switchToSettingsTab(route:)` navigates to the settings tab with the export items route.
    @Test
    func switchToSettingsTab_navigatesToExportItems() {
        subject.switchToSettingsTab(route: .exportItems)

        #expect(module.tabCoordinator.routes.last == .settings(.exportItems))
    }
}
