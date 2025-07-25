import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared

class VaultUnlockSetupProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var biometricsRepository: MockBiometricsRepository!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: VaultUnlockSetupProcessor!
    var vaultUnlockSetupHelper: MockVaultUnlockSetupHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        biometricsRepository = MockBiometricsRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        vaultUnlockSetupHelper = MockVaultUnlockSetupHelper()

        subject = VaultUnlockSetupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                biometricsRepository: biometricsRepository,
                errorReporter: errorReporter,
                stateService: stateService
            ),
            state: VaultUnlockSetupState(accountSetupFlow: .createAccount),
            vaultUnlockSetupHelper: vaultUnlockSetupHelper
        )
    }

    override func tearDown() {
        super.tearDown()

        biometricsRepository = nil
        coordinator = nil
        errorReporter = nil
        stateService = nil
        subject = nil
        vaultUnlockSetupHelper = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.continueFlow` navigates to autofill setup when in the create account flow.
    @MainActor
    func test_perform_continueFlow_createAccount() async {
        stateService.activeAccount = .fixture()

        await subject.perform(.continueFlow)

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertEqual(stateService.accountSetupVaultUnlock["1"], .complete)
    }

    /// `perform(_:)` with `.continueFlow` logs an error if one occurs prior to navigates to
    /// autofill setup.
    @MainActor
    func test_perform_continueFlow_error() async {
        await subject.perform(.continueFlow)

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `perform(_:)` with `.continueFlow` dismisses the view when in the settings flow.
    @MainActor
    func test_perform_continueFlow_settings() async {
        subject.state.accountSetupFlow = .settings
        stateService.activeAccount = .fixture()

        await subject.perform(.continueFlow)

        XCTAssertEqual(coordinator.routes, [.dismiss])
        XCTAssertEqual(stateService.accountSetupVaultUnlock["1"], .complete)
    }

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status.
    @MainActor
    func test_perform_loadData() async {
        let status = BiometricsUnlockStatus.available(.faceID, enabled: false)
        biometricsRepository.biometricUnlockStatus = .success(status)

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.biometrics(.faceID), .pin])
    }

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status for a device with generic biometrics.
    @MainActor
    func test_perform_loadData_biometrics() async {
        let status = BiometricsUnlockStatus.available(.unknown, enabled: false)
        biometricsRepository.biometricUnlockStatus = .success(status)

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.biometrics(.unknown), .pin])
    }

    /// `perform(_:)` with `.loadData` logs the error and shows an alert if one occurs.
    @MainActor
    func test_perform_loadData_error() async {
        biometricsRepository.biometricUnlockStatus = .failure(BitwardenTestError.example)

        await subject.perform(.loadData)

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status when there's no
    /// biometrics available.
    @MainActor
    func test_perform_loadData_noBiometrics() async {
        let status = BiometricsUnlockStatus.notAvailable
        biometricsRepository.biometricUnlockStatus = .success(status)

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.pin])
    }

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status for a device with Optic ID.
    @MainActor
    func test_perform_loadData_opticID() async {
        let status = BiometricsUnlockStatus.available(.opticID, enabled: false)
        biometricsRepository.biometricUnlockStatus = .success(status)

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.biometrics(.opticID), .pin])
    }

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status for a device with Touch ID.
    @MainActor
    func test_perform_loadData_touchID() async {
        let status = BiometricsUnlockStatus.available(.touchID, enabled: false)
        biometricsRepository.biometricUnlockStatus = .success(status)

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.biometrics(.touchID), .pin])
    }

    /// `perform(_:)` with `.toggleUnlockMethod` disables biometrics unlock and updates the state.
    @MainActor
    func test_perform_toggleUnlockMethod_biometrics_disable() async {
        subject.state.biometricsStatus = .available(.faceID, enabled: true)
        vaultUnlockSetupHelper.setBiometricUnlockStatus = .available(
            .faceID,
            enabled: false
        )

        await subject.perform(.toggleUnlockMethod(.biometrics(.faceID), newValue: false))

        XCTAssertTrue(vaultUnlockSetupHelper.setBiometricUnlockCalled)
        XCTAssertFalse(subject.state.isBiometricUnlockOn)
    }

    /// `perform(_:)` with `.toggleUnlockMethod` enables biometrics unlock and updates the state.
    @MainActor
    func test_perform_toggleUnlockMethod_biometrics_enable() async {
        vaultUnlockSetupHelper.setBiometricUnlockStatus = .available(
            .faceID,
            enabled: true
        )

        await subject.perform(.toggleUnlockMethod(.biometrics(.faceID), newValue: true))

        XCTAssertTrue(vaultUnlockSetupHelper.setBiometricUnlockCalled)
        XCTAssertTrue(subject.state.isBiometricUnlockOn)
    }

    /// `perform(_:)` with `.toggleUnlockMethod` disables pin unlock and updates the state.
    @MainActor
    func test_perform_toggleUnlockMethod_pin_disable() async {
        vaultUnlockSetupHelper.setPinUnlockResult = true

        await subject.perform(.toggleUnlockMethod(.pin, newValue: false))

        XCTAssertTrue(vaultUnlockSetupHelper.setPinUnlockCalled)
        XCTAssertTrue(subject.state.isPinUnlockOn)
    }

    /// `perform(_:)` with `.toggleUnlockMethod` enables pin unlock and updates the state.
    @MainActor
    func test_perform_toggleUnlockMethod_pin_enable() async {
        subject.state.isPinUnlockOn = true
        vaultUnlockSetupHelper.setPinUnlockResult = false

        await subject.perform(.toggleUnlockMethod(.pin, newValue: true))

        XCTAssertTrue(vaultUnlockSetupHelper.setPinUnlockCalled)
        XCTAssertFalse(subject.state.isPinUnlockOn)
    }

    /// `receive(_:)` with `.setUpLater` shows an alert confirming the user wants to skip unlock
    /// setup and then navigates to autofill setup.
    @MainActor
    func test_receive_setUpLater() async throws {
        stateService.activeAccount = .fixture()

        subject.receive(.setUpLater)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .setUpUnlockMethodLater {})

        try await alert.tapAction(title: Localizations.cancel)
        XCTAssertTrue(coordinator.routes.isEmpty)

        try await alert.tapAction(title: Localizations.confirm)
        XCTAssertEqual(coordinator.events, [.didCompleteAuth])

        XCTAssertEqual(stateService.accountSetupVaultUnlock["1"], .setUpLater)
    }

    /// `receive(_:)` with `.setUpLater` logs an error if one occurs while saving the set up later flag.
    @MainActor
    func test_receive_setUpLater_error() async throws {
        subject.receive(.setUpLater)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .setUpUnlockMethodLater {})

        try await alert.tapAction(title: Localizations.confirm)
        XCTAssertEqual(coordinator.events, [.didCompleteAuth])

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }
}
