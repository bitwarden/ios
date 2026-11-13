import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class VaultUnlockSetupProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var biometricsRepository: MockBiometricsRepository!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: VaultUnlockSetupProcessor!
    var vaultUnlockSetupHelper: MockVaultUnlockSetupHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        biometricsRepository = MockBiometricsRepository()
        configService = MockConfigService()
        configService.featureFlagsBool[.accountSetupOnboardingOnSignIn] = true
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        vaultUnlockSetupHelper = MockVaultUnlockSetupHelper()

        subject = VaultUnlockSetupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                biometricsRepository: biometricsRepository,
                configService: configService,
                errorReporter: errorReporter,
                stateService: stateService,
            ),
            state: VaultUnlockSetupState(accountSetupFlow: .createAccount),
            vaultUnlockSetupHelper: vaultUnlockSetupHelper,
        )
    }

    override func tearDown() {
        super.tearDown()

        biometricsRepository = nil
        configService = nil
        coordinator = nil
        errorReporter = nil
        stateService = nil
        subject = nil
        vaultUnlockSetupHelper = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.continueFlow` continues account setup onboarding when in the create
    /// account flow, without updating the vault unlock setup progress.
    @MainActor
    func test_perform_continueFlow_createAccount() async {
        stateService.activeAccount = .fixture()

        await subject.perform(.continueFlow)

        XCTAssertEqual(coordinator.events, [.didCompleteVaultUnlockSetup])
        XCTAssertNil(stateService.accountSetupVaultUnlock["1"])
    }

    /// `perform(_:)` with `.continueFlow` marks the vault unlock setup progress complete and
    /// continues account setup onboarding when in the create account flow and account setup
    /// onboarding on sign-in is disabled.
    @MainActor
    func test_perform_continueFlow_createAccount_onboardingOnSignInDisabled() async {
        configService.featureFlagsBool[.accountSetupOnboardingOnSignIn] = false
        stateService.activeAccount = .fixture()

        await subject.perform(.continueFlow)

        XCTAssertEqual(coordinator.events, [.didCompleteVaultUnlockSetup])
        XCTAssertEqual(stateService.accountSetupVaultUnlock["1"], .complete)
    }

    /// `perform(_:)` with `.continueFlow` logs an error if updating the vault unlock setup progress
    /// fails in the create account flow and still continues account setup onboarding.
    @MainActor
    func test_perform_continueFlow_createAccount_onboardingOnSignInDisabled_error() async {
        configService.featureFlagsBool[.accountSetupOnboardingOnSignIn] = false

        await subject.perform(.continueFlow)

        XCTAssertEqual(coordinator.events, [.didCompleteVaultUnlockSetup])
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `perform(_:)` with `.continueFlow` marks the vault unlock setup progress complete and
    /// dismisses the view when in the settings flow.
    @MainActor
    func test_perform_continueFlow_settings() async {
        subject.state.accountSetupFlow = .settings
        stateService.activeAccount = .fixture()

        await subject.perform(.continueFlow)

        XCTAssertEqual(coordinator.routes, [.dismiss])
        XCTAssertEqual(stateService.accountSetupVaultUnlock["1"], .complete)
    }

    /// `perform(_:)` with `.continueFlow` logs an error if updating the vault unlock setup progress
    /// fails in the settings flow and still dismisses the view.
    @MainActor
    func test_perform_continueFlow_settings_error() async {
        subject.state.accountSetupFlow = .settings

        await subject.perform(.continueFlow)

        XCTAssertEqual(coordinator.routes, [.dismiss])
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status and hides the PIN unlock
    /// option in the create account flow if account setup onboarding on sign-in is enabled.
    @MainActor
    func test_perform_loadData() async {
        let status = BiometricsUnlockStatus.available(.faceID, enabled: false)
        biometricsRepository.getBiometricUnlockStatusReturnValue = status

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertFalse(subject.state.shouldShowPinUnlock)
        XCTAssertEqual(subject.state.unlockMethods, [.biometrics(.faceID)])
        XCTAssertEqual(
            subject.state.message,
            Localizations.youCanAlsoSetUpOtherUnlockOptionsAnytimeInSettingsAccountSecurity,
        )
    }

    /// `perform(_:)` with `.loadData` shows the PIN unlock option in the create account flow if
    /// account setup onboarding on sign-in is disabled.
    @MainActor
    func test_perform_loadData_onboardingOnSignInDisabled() async {
        configService.featureFlagsBool[.accountSetupOnboardingOnSignIn] = false
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: false)

        await subject.perform(.loadData)

        XCTAssertTrue(subject.state.shouldShowPinUnlock)
        XCTAssertEqual(subject.state.unlockMethods, [.biometrics(.faceID), .pin])
        XCTAssertEqual(
            subject.state.message,
            Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins,
        )
    }

    /// `perform(_:)` with `.loadData` shows the PIN unlock option in the settings flow, even if
    /// account setup onboarding on sign-in is enabled.
    @MainActor
    func test_perform_loadData_settings() async {
        subject.state.accountSetupFlow = .settings
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: false)

        await subject.perform(.loadData)

        XCTAssertTrue(subject.state.shouldShowPinUnlock)
        XCTAssertEqual(subject.state.unlockMethods, [.biometrics(.faceID), .pin])
    }

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status for a device with generic biometrics.
    @MainActor
    func test_perform_loadData_biometrics() async {
        let status = BiometricsUnlockStatus.available(.unknown, enabled: false)
        biometricsRepository.getBiometricUnlockStatusReturnValue = status

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.biometrics(.unknown)])
    }

    /// `perform(_:)` with `.loadData` logs the error and shows an alert if one occurs.
    @MainActor
    func test_perform_loadData_error() async {
        biometricsRepository.getBiometricUnlockStatusThrowableError = BitwardenTestError.example

        await subject.perform(.loadData)

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status when there's no
    /// biometrics available.
    @MainActor
    func test_perform_loadData_noBiometrics() async {
        let status = BiometricsUnlockStatus.notAvailable
        biometricsRepository.getBiometricUnlockStatusReturnValue = status

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [])
    }

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status for a device with Optic ID.
    @MainActor
    func test_perform_loadData_opticID() async {
        let status = BiometricsUnlockStatus.available(.opticID, enabled: false)
        biometricsRepository.getBiometricUnlockStatusReturnValue = status

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.biometrics(.opticID)])
    }

    /// `perform(_:)` with `.loadData` fetches the biometrics unlock status for a device with Touch ID.
    @MainActor
    func test_perform_loadData_touchID() async {
        let status = BiometricsUnlockStatus.available(.touchID, enabled: false)
        biometricsRepository.getBiometricUnlockStatusReturnValue = status

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricsStatus, status)
        XCTAssertEqual(subject.state.unlockMethods, [.biometrics(.touchID)])
    }

    /// `perform(_:)` with `.toggleUnlockMethod` disables biometrics unlock and updates the state.
    @MainActor
    func test_perform_toggleUnlockMethod_biometrics_disable() async {
        subject.state.biometricsStatus = .available(.faceID, enabled: true)
        vaultUnlockSetupHelper.setBiometricUnlockStatus = .available(
            .faceID,
            enabled: false,
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
    /// setup and then continues account setup onboarding, without updating the vault unlock setup
    /// progress.
    @MainActor
    func test_receive_setUpLater() async throws {
        stateService.activeAccount = .fixture()

        subject.receive(.setUpLater)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .setUpUnlockMethodLater {})

        try await alert.tapAction(title: Localizations.cancel)
        XCTAssertTrue(coordinator.routes.isEmpty)

        try await alert.tapAction(title: Localizations.confirm)
        XCTAssertEqual(coordinator.events, [.didCompleteVaultUnlockSetup])

        XCTAssertNil(stateService.accountSetupVaultUnlock["1"])
    }

    /// `receive(_:)` with `.setUpLater` shows an alert confirming the user wants to skip unlock
    /// setup and then sets the vault unlock setup progress to set up later and continues account
    /// setup onboarding if account setup onboarding on sign-in is disabled.
    @MainActor
    func test_receive_setUpLater_onboardingOnSignInDisabled() async throws {
        configService.featureFlagsBool[.accountSetupOnboardingOnSignIn] = false
        stateService.activeAccount = .fixture()

        subject.receive(.setUpLater)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.confirm)

        XCTAssertEqual(coordinator.events, [.didCompleteVaultUnlockSetup])
        XCTAssertEqual(stateService.accountSetupVaultUnlock["1"], .setUpLater)
    }
}
