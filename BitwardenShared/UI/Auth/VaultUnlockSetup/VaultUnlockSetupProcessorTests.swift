import XCTest

@testable import BitwardenShared

class VaultUnlockSetupProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var biometricsRepository: MockBiometricsRepository!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var subject: VaultUnlockSetupProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        biometricsRepository = MockBiometricsRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()

        subject = VaultUnlockSetupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                biometricsRepository: biometricsRepository,
                errorReporter: errorReporter
            ),
            state: VaultUnlockSetupState()
        )
    }

    override func tearDown() {
        super.tearDown()

        biometricsRepository = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status.
    func test_perform_loadData() async {
        let status = BiometricsUnlockStatus.available(.faceID, enabled: false, hasValidIntegrity: false)
        biometricsRepository.biometricUnlockStatus = .success(status)

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.faceID, .pin])
    }

    /// `perform(_:)` with `.loadData` logs the error and shows an alert if one occurs.
    func test_perform_loadData_error() async {
        biometricsRepository.biometricUnlockStatus = .failure(BitwardenTestError.example)

        await subject.perform(.loadData)

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status when there's no
    /// biometrics available.
    func test_perform_loadData_noBiometrics() async {
        let status = BiometricsUnlockStatus.notAvailable
        biometricsRepository.biometricUnlockStatus = .success(status)

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.pin])
    }

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status for a device with Touch ID.
    func test_perform_loadData_touchID() async {
        let status = BiometricsUnlockStatus.available(.touchID, enabled: false, hasValidIntegrity: false)
        biometricsRepository.biometricUnlockStatus = .success(status)

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.touchID, .pin])
    }

    /// `receive(_:)` with `.continueFlow` navigates to autofill setup.
    func test_receive_continueFlow() {
        subject.receive(.continueFlow)
        // TODO: PM-10278 Navigate to autofill setup
    }

    /// `receive(_:)` with `.setUpLater` skips unlock setup.
    func test_receive_setUpLater() {
        subject.receive(.setUpLater)
        // TODO: PM-10270 Skip unlock setup
    }

    /// `receive(_:)` with `.toggleUnlockMethod` updates the Face ID unlock method in the state.
    func test_receive_toggleUnlockMethod_faceID() {
        subject.receive(.toggleUnlockMethod(.faceID, newValue: true))
        XCTAssertTrue(subject.state.isBiometricUnlockOn)

        subject.receive(.toggleUnlockMethod(.faceID, newValue: false))
        XCTAssertFalse(subject.state.isBiometricUnlockOn)
    }

    /// `receive(_:)` with `.toggleUnlockMethod` updates the pin unlock method in the state.
    func test_receive_toggleUnlockMethod_pin() {
        subject.receive(.toggleUnlockMethod(.pin, newValue: true))
        XCTAssertTrue(subject.state.isPinUnlockOn)

        subject.receive(.toggleUnlockMethod(.pin, newValue: false))
        XCTAssertFalse(subject.state.isPinUnlockOn)
    }

    /// `receive(_:)` with `.toggleUnlockMethod` updates the touch ID unlock method in the state.
    func test_receive_toggleUnlockMethod_touchID() {
        subject.receive(.toggleUnlockMethod(.touchID, newValue: true))
        XCTAssertTrue(subject.state.isBiometricUnlockOn)

        subject.receive(.toggleUnlockMethod(.touchID, newValue: false))
        XCTAssertFalse(subject.state.isBiometricUnlockOn)
    }
}
