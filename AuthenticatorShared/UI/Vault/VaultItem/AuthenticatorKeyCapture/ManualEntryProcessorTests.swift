import BitwardenKitMocks
import XCTest

@testable import AuthenticatorShared

final class ManualEntryProcessorTests: BitwardenTestCase {
    var appSettingsStore: MockAppSettingsStore!
    var authItemRepository: MockAuthenticatorItemRepository!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>!
    var subject: ManualEntryProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        authItemRepository = MockAuthenticatorItemRepository()
        configService = MockConfigService()
        coordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject = ManualEntryProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                appSettingsStore: appSettingsStore,
                authenticatorItemRepository: authItemRepository,
                configService: configService
            ),
            state: DefaultEntryState(deviceSupportsCamera: true)
        )
    }

    override func tearDown() {
        super.tearDown()
        appSettingsStore = nil
        authItemRepository = nil
        configService = nil
        coordinator = nil
        subject = nil
    }

    /// `receive()` with `.appeared` sets the `isPasswordManagerSyncActive` to true when sync is turned on.
    @MainActor
    func test_perform_appeared_allActive() async {
        authItemRepository.pmSyncEnabled = true

        await subject.perform(.appeared)
        XCTAssertTrue(subject.state.isPasswordManagerSyncActive)
    }

    /// `receive()` with `.appeared` sets the `isPasswordManagerSyncActive` to false when sync is turned off.
    @MainActor
    func test_perform_appeared_syncOff() async {
        authItemRepository.pmSyncEnabled = false

        await subject.perform(.appeared)
        XCTAssertFalse(subject.state.isPasswordManagerSyncActive)
    }

    /// `receive()` with `.appeared` sets the `defaultSaveOption` in the state based on the user's
    /// stored default save option.
    @MainActor
    func test_perform_appeared_defaultSaveOption() async {
        appSettingsStore.defaultSaveOption = .none
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.defaultSaveOption, .none)

        appSettingsStore.defaultSaveOption = .saveToBitwarden
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.defaultSaveOption, .saveToBitwarden)

        appSettingsStore.defaultSaveOption = .saveHere
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.defaultSaveOption, .saveHere)
    }

    /// `receive()` with `.scanCodePressed` navigates to `.scanCode`.
    @MainActor
    func test_perform_scanCodePressed() async {
        await subject.perform(.scanCodePressed)
        XCTAssertEqual(coordinator.events, [.showScanCode])
    }

    /// `receive()` with `.addPressed(:)` navigates to `.addManual(:)`.
    @MainActor
    func test_receive_addPressed() async {
        subject.state.authenticatorKey = "YouNeedUniqueNewYork"
        subject.state.name = "NewYork"
        subject.receive(.addPressed(code: "YouNeedUniqueNewYork", name: "NewYork", sendToBitwarden: false))
        let route = AuthenticatorKeyCaptureRoute.addManual(key: "YouNeedUniqueNewYork",
                                                           name: "NewYork",
                                                           sendToBitwarden: false)
        XCTAssertEqual(coordinator.routes, [route])
    }

    /// `receive()` with `.authenticatorKeyChanged(:)` updates the state.
    @MainActor
    func test_receive_authenticatorKeyChanged() async {
        subject.receive(.authenticatorKeyChanged("YouNeedUniqueNewYork"))
        XCTAssertEqual(subject.state.authenticatorKey, "YouNeedUniqueNewYork")
    }

    /// `receive()` with `.dismissPressed` navigates to dismiss.
    @MainActor
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes, [.dismiss()])
    }
}
