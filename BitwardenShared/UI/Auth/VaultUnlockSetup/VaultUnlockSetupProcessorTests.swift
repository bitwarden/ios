import XCTest

@testable import BitwardenShared

class VaultUnlockSetupProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var biometricsRepository: MockBiometricsRepository!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var subject: VaultUnlockSetupProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        biometricsRepository = MockBiometricsRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()

        subject = VaultUnlockSetupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                biometricsRepository: biometricsRepository,
                errorReporter: errorReporter
            ),
            state: VaultUnlockSetupState()
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        biometricsRepository = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
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

    /// `receive(_:)` with `.toggleUnlockMethod` disables biometrics and updates the state.
    @MainActor
    func test_receive_toggleUnlockMethod_biometrics_disable() {
        let biometricUnlockStatus = BiometricsUnlockStatus.available(.faceID, enabled: false, hasValidIntegrity: false)
        authRepository.allowBiometricUnlockResult = .success(())
        biometricsRepository.biometricUnlockStatus = .success(biometricUnlockStatus)
        subject.state.biometricsStatus = .available(.faceID, enabled: true, hasValidIntegrity: true)

        subject.receive(.toggleUnlockMethod(.biometrics(.faceID), newValue: false))
        waitFor { !subject.state.isBiometricUnlockOn }

        XCTAssertEqual(authRepository.allowBiometricUnlock, false)
        XCTAssertEqual(subject.state.biometricsStatus, biometricUnlockStatus)
        XCTAssertFalse(subject.state.isBiometricUnlockOn)
    }

    /// `receive(_:)` with `.toggleUnlockMethod` logs an error and shows an alert if disabling biometrics fails.
    @MainActor
    func test_receive_toggleUnlockMethod_biometrics_disable_error() {
        let biometricUnlockStatus = BiometricsUnlockStatus.available(.faceID, enabled: true, hasValidIntegrity: true)
        authRepository.allowBiometricUnlockResult = .failure(BitwardenTestError.example)
        biometricsRepository.biometricUnlockStatus = .success(biometricUnlockStatus)
        subject.state.biometricsStatus = biometricUnlockStatus

        subject.receive(.toggleUnlockMethod(.biometrics(.faceID), newValue: false))
        waitFor { !coordinator.alertShown.isEmpty }

        XCTAssertEqual(authRepository.allowBiometricUnlock, false)
        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(subject.state.biometricsStatus, biometricUnlockStatus)
        XCTAssertTrue(subject.state.isBiometricUnlockOn)
    }

    /// `receive(_:)` with `.toggleUnlockMethod` enables biometrics and updates the state.
    @MainActor
    func test_receive_toggleUnlockMethod_biometrics_enable() {
        let biometricUnlockStatus = BiometricsUnlockStatus.available(.faceID, enabled: true, hasValidIntegrity: true)
        authRepository.allowBiometricUnlockResult = .success(())
        biometricsRepository.biometricUnlockStatus = .success(biometricUnlockStatus)

        subject.receive(.toggleUnlockMethod(.biometrics(.faceID), newValue: true))
        waitFor { subject.state.isBiometricUnlockOn }

        XCTAssertEqual(authRepository.allowBiometricUnlock, true)
        XCTAssertEqual(subject.state.biometricsStatus, biometricUnlockStatus)
        XCTAssertTrue(subject.state.isBiometricUnlockOn)
    }

    /// `receive(_:)` with `.toggleUnlockMethod` logs an error and shows an alert if enabling biometrics fails.
    @MainActor
    func test_receive_toggleUnlockMethod_biometrics_enable_error() {
        let biometricUnlockStatus = BiometricsUnlockStatus.available(.faceID, enabled: false, hasValidIntegrity: false)
        authRepository.allowBiometricUnlockResult = .failure(BitwardenTestError.example)
        biometricsRepository.biometricUnlockStatus = .success(biometricUnlockStatus)
        subject.state.biometricsStatus = biometricUnlockStatus

        subject.receive(.toggleUnlockMethod(.biometrics(.faceID), newValue: true))
        waitFor { !coordinator.alertShown.isEmpty }

        XCTAssertEqual(authRepository.allowBiometricUnlock, true)
        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(subject.state.biometricsStatus, biometricUnlockStatus)
        XCTAssertFalse(subject.state.isBiometricUnlockOn)
    }

    /// `receive(_:)` with `.toggleUnlockMethod` updates the pin unlock method in the state.
    @MainActor
    func test_receive_toggleUnlockMethod_pin() {
        subject.receive(.toggleUnlockMethod(.pin, newValue: true))
        XCTAssertTrue(subject.state.isPinUnlockOn)

        subject.receive(.toggleUnlockMethod(.pin, newValue: false))
        XCTAssertFalse(subject.state.isPinUnlockOn)
    }

    /// `receive(_:)` with `.toggleUnlockMethod` updates the touch ID unlock method in the state.
    @MainActor
    func test_receive_toggleUnlockMethod_touchID() {
        subject.state.biometricsStatus = .available(.touchID, enabled: false, hasValidIntegrity: false)
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.touchID, enabled: true, hasValidIntegrity: true)
        )

        subject.receive(.toggleUnlockMethod(.biometrics(.touchID), newValue: true))
        waitFor { subject.state.isBiometricUnlockOn }
        XCTAssertTrue(subject.state.isBiometricUnlockOn)

        biometricsRepository.biometricUnlockStatus = .success(
            .available(.touchID, enabled: false, hasValidIntegrity: false)
        )
        subject.receive(.toggleUnlockMethod(.biometrics(.touchID), newValue: false))
        waitFor { !subject.state.isBiometricUnlockOn }
        XCTAssertFalse(subject.state.isBiometricUnlockOn)
    }
}
