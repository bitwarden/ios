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

    /// `handleEvent(.didStart)` with biometrics enabled and a non-never vault timeout presents
    /// the auth overlay with `isModalInPresentation` set to prevent swipe-to-dismiss bypasses.
    @Test
    func handleEvent_didStart_biometricsEnabledAndTimeout_setsModalInPresentation() async {
        let biometricsRepository = MockBiometricsRepository()
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        let stateService = MockStateService()
        stateService.vaultTimeout = .immediately
        let mockRootNavigator = MockRootNavigator()
        mockRootNavigator.rootViewController = MockUIViewController()
        let localSubject = AppCoordinator(
            appContext: .mainApp,
            module: MockAppModule(),
            rootNavigator: mockRootNavigator,
            services: ServiceContainer.withMocks(
                biometricsRepository: biometricsRepository,
                stateService: stateService,
            ),
        )

        await localSubject.handleEvent(.didStart)

        let presentedVC = (mockRootNavigator.rootViewController as? MockUIViewController)?.presentedView
        #expect(presentedVC?.isModalInPresentation == true)
        #expect(presentedVC?.modalPresentationStyle == .overFullScreen)
    }

    /// `handleEvent(.vaultTimeout)` presents the auth overlay with `isModalInPresentation` set
    /// and `modalPresentationStyle` set to `.fullScreen` to prevent swipe-to-dismiss bypasses.
    @Test
    func handleEvent_vaultTimeout_setsModalInPresentation() async {
        let mockRootNavigator = MockRootNavigator()
        mockRootNavigator.rootViewController = MockUIViewController()
        let localSubject = AppCoordinator(
            appContext: .mainApp,
            module: MockAppModule(),
            rootNavigator: mockRootNavigator,
            services: ServiceContainer.withMocks(),
        )

        await localSubject.handleEvent(.vaultTimeout)

        let presentedVC = (mockRootNavigator.rootViewController as? MockUIViewController)?.presentedView
        #expect(presentedVC?.isModalInPresentation == true)
        #expect(presentedVC?.modalPresentationStyle == .overFullScreen)
    }

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
