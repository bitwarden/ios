import XCTest

@testable import BitwardenShared

class VaultUnlockSetupProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var biometricsRepository: MockBiometricsRepository!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var subject: VaultUnlockSetupProcessor!
    var vaultUnlockSetupHelper: MockVaultUnlockSetupHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        biometricsRepository = MockBiometricsRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        vaultUnlockSetupHelper = MockVaultUnlockSetupHelper()

        subject = VaultUnlockSetupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                biometricsRepository: biometricsRepository,
                errorReporter: errorReporter
            ),
            state: VaultUnlockSetupState(),
            vaultUnlockSetupHelper: vaultUnlockSetupHelper
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        biometricsRepository = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
        vaultUnlockSetupHelper = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status.
    @MainActor
    func test_perform_loadData() async {
        let status = BiometricsUnlockStatus.available(.faceID, enabled: false, hasValidIntegrity: false)
        biometricsRepository.biometricUnlockStatus = .success(status)

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.biometrics(.faceID), .pin])
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

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status for a device with Touch ID.
    @MainActor
    func test_perform_loadData_touchID() async {
        let status = BiometricsUnlockStatus.available(.touchID, enabled: false, hasValidIntegrity: false)
        biometricsRepository.biometricUnlockStatus = .success(status)

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.biometrics(.touchID), .pin])
    }

    /// `perform(_:)` with `.toggleUnlockMethod` disables biometrics unlock and updates the state.
    @MainActor
    func test_perform_toggleUnlockMethod_biometrics_disable() async {
        subject.state.biometricsStatus = .available(.faceID, enabled: true, hasValidIntegrity: true)
        vaultUnlockSetupHelper.setBiometricUnlockStatus = .available(
            .faceID,
            enabled: false,
            hasValidIntegrity: false
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
            enabled: true,
            hasValidIntegrity: true
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

    /// `receive(_:)` with `.continueFlow` navigates to autofill setup.
    @MainActor
    func test_receive_continueFlow() {
        subject.receive(.continueFlow)
        // TODO: PM-10278 Navigate to autofill setup
    }

    /// `receive(_:)` with `.setUpLater` skips unlock setup.
    @MainActor
    func test_receive_setUpLater() {
        subject.receive(.setUpLater)
        // TODO: PM-10270 Skip unlock setup
    }
}
