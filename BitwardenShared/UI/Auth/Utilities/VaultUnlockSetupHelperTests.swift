import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: VaultUnlockSetupHelperTests

class VaultUnlockSetupHelperTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var biometricsRepository: MockBiometricsRepository!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: VaultUnlockSetupHelper!

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        biometricsRepository = MockBiometricsRepository()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        subject = DefaultVaultUnlockSetupHelper(
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                biometricsRepository: biometricsRepository,
                errorReporter: errorReporter,
                stateService: stateService
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        biometricsRepository = nil
        errorReporter = nil
        subject = nil
        stateService = nil
    }

    // MARK: Tests

    /// `setBiometricUnlock()` successfully disables biometric unlock.
    func test_setBiometricUnlock_disable() async {
        let disabledStatus = BiometricsUnlockStatus.available(.faceID, enabled: false)
        biometricsRepository.biometricUnlockStatus = .success(disabledStatus)

        var alertsShown = [Alert]()
        let status = await subject.setBiometricUnlock(enabled: false) { alert in
            alertsShown.append(alert)
        }

        XCTAssertTrue(alertsShown.isEmpty)
        XCTAssertEqual(authRepository.allowBiometricUnlock, false)
        XCTAssertEqual(status, disabledStatus)
    }

    /// `setBiometricUnlock()` successfully enables biometric unlock.
    func test_setBiometricUnlock_enable() async {
        let enabledStatus = BiometricsUnlockStatus.available(.faceID, enabled: true)
        biometricsRepository.biometricUnlockStatus = .success(enabledStatus)

        var alertsShown = [Alert]()
        let status = await subject.setBiometricUnlock(enabled: true) { alert in
            alertsShown.append(alert)
        }

        XCTAssertTrue(alertsShown.isEmpty)
        XCTAssertEqual(authRepository.allowBiometricUnlock, true)
        XCTAssertEqual(status, enabledStatus)
    }

    /// `setBiometricUnlock()` shows an alert and logs an error if setting biometric unlock fails.
    func test_setBiometricUnlock_allowBiometricUnlockFailure() async {
        let unlockStatus = BiometricsUnlockStatus.available(.faceID, enabled: true)
        authRepository.allowBiometricUnlockResult = .failure(BitwardenTestError.example)
        biometricsRepository.biometricUnlockStatus = .success(unlockStatus)

        var alertsShown = [Alert]()
        let status = await subject.setBiometricUnlock(enabled: true) { alert in
            alertsShown.append(alert)
        }

        XCTAssertEqual(alertsShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(status, unlockStatus)
    }

    /// `setBiometricUnlock()` shows an alert and logs an error if getting the biometric unlock status fails.
    func test_setBiometricUnlock_getBiometricUnlockStatusFailure() async {
        biometricsRepository.biometricUnlockStatus = .failure(BitwardenTestError.example)

        var alertsShown = [Alert]()
        let status = await subject.setBiometricUnlock(enabled: true) { alert in
            alertsShown.append(alert)
        }

        XCTAssertEqual(alertsShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertNil(status)
    }

    /// `setPinUnlock()` successfully disables pin unlock.
    func test_setPinUnlock_disable() async {
        var alertsShown = [Alert]()
        let pinUnlockEnabled = await subject.setPinUnlock(enabled: false) { alert in
            alertsShown.append(alert)
        }

        XCTAssertFalse(pinUnlockEnabled)
        XCTAssertTrue(authRepository.clearPinsCalled)
    }

    /// `setPinUnlock()` successfully enables pin unlock.
    func test_setPinUnlock_enable() async {
        biometricsRepository.getBiometricAuthenticationTypeResult = .faceID
        stateService.activeAccount = .fixture()

        var alertsShown = [Alert]()
        let pinUnlockEnabled = await subject.setPinUnlock(enabled: true) { alert in
            alertsShown.append(alert)

            if alert == .enterPINCode(completion: { _ in }) {
                try? alert.setText("1234", forTextFieldWithId: "pin")
                Task {
                    try? await alert.tapAction(title: Localizations.submit)
                }
            }

            if alert == .unlockWithPINCodeAlert(biometricType: .faceID, action: { _ in }) {
                XCTAssertEqual(
                    alert.message,
                    Localizations.pinRequireBioOrMasterPasswordRestart(Localizations.faceID)
                )
                Task {
                    try? await alert.tapAction(title: Localizations.no)
                }
            }
        }

        XCTAssertEqual(authRepository.encryptedPin, "1234")
        XCTAssertEqual(authRepository.setPinsRequirePasswordAfterRestart, false)
        XCTAssertTrue(pinUnlockEnabled)
    }

    /// `setPinUnlock()` successfully enables pin unlock with requiring the user's master password
    /// when the app restarts.
    func test_setPinUnlock_enableRequirePasswordAfterRestart() async {
        stateService.activeAccount = .fixture()

        var alertsShown = [Alert]()
        let pinUnlockEnabled = await subject.setPinUnlock(enabled: true) { alert in
            alertsShown.append(alert)

            if alert == .enterPINCode(completion: { _ in }) {
                try? alert.setText("1234", forTextFieldWithId: "pin")
                Task {
                    try? await alert.tapAction(title: Localizations.submit)
                }
            }

            if alert == .unlockWithPINCodeAlert(biometricType: nil, action: { _ in }) {
                Task {
                    try? await alert.tapAction(title: Localizations.yes)
                }
            }
        }

        XCTAssertEqual(authRepository.encryptedPin, "1234")
        XCTAssertEqual(authRepository.setPinsRequirePasswordAfterRestart, true)
        XCTAssertTrue(pinUnlockEnabled)
    }

    /// `setPinUnlock()` doesn't enable pin unlock if the user cancels when entering their pin.
    func test_setPinUnlock_enableEnterPinCancelled() async {
        var alertsShown = [Alert]()
        let pinUnlockEnabled = await subject.setPinUnlock(enabled: true) { alert in
            alertsShown.append(alert)

            if alert == .enterPINCode(completion: { _ in }) {
                Task {
                    try? await alert.tapAction(title: Localizations.cancel)
                }
            }
        }

        XCTAssertFalse(pinUnlockEnabled)
        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertEqual(alertsShown, [.enterPINCode { _ in }])
    }

    /// `setPinUnlock()` successfully enables pin unlock when the user doesn't have a master password.
    func test_setPinUnlock_enableNoPassword() async {
        stateService.activeAccount = .fixtureWithTdeNoPassword()
        stateService.userHasMasterPassword["1"] = false

        var alertsShown = [Alert]()
        let pinUnlockEnabled = await subject.setPinUnlock(enabled: true) { alert in
            alertsShown.append(alert)

            if alert == .enterPINCode(completion: { _ in }) {
                try? alert.setText("1234", forTextFieldWithId: "pin")
                Task {
                    try? await alert.tapAction(title: Localizations.submit)
                }
            }
        }

        XCTAssertTrue(pinUnlockEnabled)
        XCTAssertEqual(authRepository.setPinsRequirePasswordAfterRestart, false)
        XCTAssertEqual(alertsShown, [.enterPINCode { _ in }])
    }

    /// `setPinUnlock()` doesn't enable pin unlock if the user enters an empty pin.
    func test_setPinUnlock_enableEmptyPin() async {
        var alertsShown = [Alert]()
        let pinUnlockEnabled = await subject.setPinUnlock(enabled: true) { alert in
            alertsShown.append(alert)

            if alert == .enterPINCode(completion: { _ in }) {
                Task {
                    try? await alert.tapAction(title: Localizations.submit)
                }
            }
        }

        XCTAssertFalse(pinUnlockEnabled)
        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertEqual(alertsShown, [.enterPINCode { _ in }])
    }

    /// `setPinUnlock()` doesn't enable pin unlock if the user enters a whitespace only pin.
    func test_setPinUnlock_enableWhitespacePin() async {
        var alertsShown = [Alert]()
        let pinUnlockEnabled = await subject.setPinUnlock(enabled: true) { alert in
            alertsShown.append(alert)

            if alert == .enterPINCode(completion: { _ in }) {
                try? alert.setText(" ", forTextFieldWithId: "pin")
                Task {
                    try? await alert.tapAction(title: Localizations.submit)
                }
            }
        }

        XCTAssertFalse(pinUnlockEnabled)
        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertEqual(alertsShown, [.enterPINCode { _ in }])
    }

    /// `setPinUnlock()` shows an alert and logs an error if getting whether the user has a master
    /// password fails.
    func test_setPinUnlock_enableGetUserHasMasterPasswordFailure() async {
        var alertsShown = [Alert]()
        let pinUnlockEnabled = await subject.setPinUnlock(enabled: true) { alert in
            alertsShown.append(alert)

            if alert == .enterPINCode(completion: { _ in }) {
                try? alert.setText("1234", forTextFieldWithId: "pin")
                Task {
                    try? await alert.tapAction(title: Localizations.submit)
                }
            }
        }

        XCTAssertFalse(pinUnlockEnabled)
        XCTAssertEqual(
            alertsShown,
            [
                .enterPINCode { _ in },
                .defaultAlert(title: Localizations.anErrorHasOccurred),
            ]
        )
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `setPinUnlock()` shows an alert and logs an error if setting the user's pin fails.
    func test_setPinUnlock_enableSetPinsFailure() async {
        authRepository.setPinsResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = .fixture()

        var alertsShown = [Alert]()
        let pinUnlockEnabled = await subject.setPinUnlock(enabled: true) { alert in
            alertsShown.append(alert)

            if alert == .enterPINCode(completion: { _ in }) {
                try? alert.setText("1234", forTextFieldWithId: "pin")
                Task {
                    try? await alert.tapAction(title: Localizations.submit)
                }
            }

            if alert == .unlockWithPINCodeAlert(biometricType: nil, action: { _ in }) {
                Task {
                    try? await alert.tapAction(title: Localizations.yes)
                }
            }
        }

        XCTAssertFalse(pinUnlockEnabled)
        XCTAssertEqual(
            alertsShown,
            [
                .enterPINCode { _ in },
                .unlockWithPINCodeAlert(biometricType: nil) { _ in },
                .defaultAlert(title: Localizations.anErrorHasOccurred),
            ]
        )
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }
}
