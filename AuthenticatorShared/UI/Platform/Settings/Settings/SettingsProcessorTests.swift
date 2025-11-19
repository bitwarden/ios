import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import AuthenticatorShared

class SettingsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var application: MockApplication!
    var appSettingsStore: MockAppSettingsStore!
    var authItemRepository: MockAuthenticatorItemRepository!
    var biometricsRepository: MockBiometricsRepository!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var flightRecorder: MockFlightRecorder!
    var pasteboardService: MockPasteboardService!
    var subject: SettingsProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        application = MockApplication()
        appSettingsStore = MockAppSettingsStore()
        authItemRepository = MockAuthenticatorItemRepository()
        biometricsRepository = MockBiometricsRepository()
        configService = MockConfigService()
        coordinator = MockCoordinator()
        flightRecorder = MockFlightRecorder()
        pasteboardService = MockPasteboardService()
        subject = SettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                application: application,
                appSettingsStore: appSettingsStore,
                authenticatorItemRepository: authItemRepository,
                biometricsRepository: biometricsRepository,
                configService: configService,
                flightRecorder: flightRecorder,
                pasteboardService: pasteboardService,
            ),
            state: SettingsState(),
        )
    }

    override func tearDown() {
        super.tearDown()

        application = nil
        appSettingsStore = nil
        authItemRepository = nil
        biometricsRepository = nil
        configService = nil
        coordinator = nil
        flightRecorder = nil
        pasteboardService = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.flightRecorder(.toggleFlightRecorder(true))` navigates to the enable
    /// flight recorder screen when toggled on.
    @MainActor
    func test_perform_flightRecorder_toggleFlightRecorder_on() async {
        XCTAssertNil(subject.state.flightRecorderState.activeLog)

        await subject.perform(.flightRecorder(.toggleFlightRecorder(true)))

        XCTAssertEqual(coordinator.routes, [.flightRecorder(.enableFlightRecorder)])
    }

    /// `perform(_:)` with `.flightRecorder(.toggleFlightRecorder(false))` disables the flight
    /// recorder when toggled off.
    @MainActor
    func test_perform_flightRecorder_toggleFlightRecorder_off() async throws {
        subject.state.flightRecorderState.activeLog = FlightRecorderData.LogMetadata(
            duration: .eightHours,
            startDate: .now,
        )

        await subject.perform(.flightRecorder(.toggleFlightRecorder(false)))

        XCTAssertTrue(flightRecorder.disableFlightRecorderCalled)
    }

    /// Performing `.loadData` sets the 'defaultSaveOption' to the current value in 'AppSettingsStore'.
    @MainActor
    func test_perform_loadData_defaultSaveOption() async throws {
        appSettingsStore.defaultSaveOption = .saveToBitwarden
        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.defaultSaveOption, .saveToBitwarden)
    }

    /// Performing `.loadData` sets the sync related flags correctly when the sync is off.
    @MainActor
    func test_perform_loadData_syncFlagEnabled_syncOff() async throws {
        authItemRepository.pmSyncEnabled = false
        await subject.perform(.loadData)

        XCTAssertFalse(subject.state.shouldShowDefaultSaveOption)
    }

    /// Performing `.loadData` sets the sync related flags correctly when the sync is on.
    @MainActor
    func test_perform_loadData_syncFlagEnabled_syncOn() async throws {
        authItemRepository.pmSyncEnabled = true
        await subject.perform(.loadData)

        XCTAssertTrue(subject.state.shouldShowDefaultSaveOption)
    }

    /// Performing `.loadData` sets the session timeout to `.never` if biometrics are disabled.
    @MainActor
    func test_perform_loadData_vaultTimeout_biometricsDisabled() async throws {
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.faceID, enabled: false, hasValidIntegrity: true),
        )
        appSettingsStore.setVaultTimeout(minutes: 15, userId: appSettingsStore.localUserId)
        await subject.perform(.loadData)
        XCTAssertEqual(subject.state.sessionTimeoutValue, .never)
    }

    /// Performing `.loadData` sets the session timeout correctly when it is set in app settings..
    @MainActor
    func test_perform_loadData_vaultTimeout_fifteenMinutes() async throws {
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.faceID, enabled: true, hasValidIntegrity: true),
        )
        appSettingsStore.setVaultTimeout(minutes: 15, userId: appSettingsStore.localUserId)
        await subject.perform(.loadData)
        XCTAssertEqual(subject.state.sessionTimeoutValue, .fifteenMinutes)
    }

    /// Performing `.loadData` sets the session timeout to `.never` when there is no timeout
    /// set and biometrics is not available or not enabled.
    @MainActor
    func test_perform_loadData_vaultTimeout_nil() async throws {
        await subject.perform(.loadData)
        XCTAssertEqual(subject.state.sessionTimeoutValue, .never)
    }

    /// Performing `.loadData` sets the session timeout to `.onAppRestart` when there is no timeout
    /// set and biometrics is turned enabled.
    @MainActor
    func test_perform_loadData_vaultTimeout_nilWithBiometrics() async throws {
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.faceID, enabled: true, hasValidIntegrity: true),
        )
        await subject.perform(.loadData)
        XCTAssertEqual(subject.state.sessionTimeoutValue, .onAppRestart)
    }

    /// Receiving `.sessionTimeoutValueChanged` when a user has not yet enabled biometrics enables
    /// biometrics and sets the value.
    ///
    @MainActor
    func test_perform_sessionTimeoutValueChanged_biometricsDisabled() async throws {
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.faceID, enabled: true, hasValidIntegrity: true),
        )
        subject.state.biometricUnlockStatus = .available(.faceID, enabled: false, hasValidIntegrity: true)
        subject.state.sessionTimeoutValue = .never
        await subject.perform(.sessionTimeoutValueChanged(.fifteenMinutes))

        XCTAssertNotNil(biometricsRepository.capturedUserAuthKey)
        XCTAssertEqual(appSettingsStore.vaultTimeout(userId: appSettingsStore.localUserId), 15)
        XCTAssertEqual(subject.state.sessionTimeoutValue, .fifteenMinutes)
    }

    /// Receiving `.sessionTimeoutValueChanged` updates the user's `vaultTimeout` app setting.
    @MainActor
    func test_perform_sessionTimeoutValueChanged_success() async throws {
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.faceID, enabled: true, hasValidIntegrity: true),
        )
        subject.state.biometricUnlockStatus = .available(.faceID, enabled: true, hasValidIntegrity: true)
        subject.state.sessionTimeoutValue = .oneHour
        await subject.perform(.sessionTimeoutValueChanged(.fifteenMinutes))

        XCTAssertEqual(appSettingsStore.vaultTimeout(userId: appSettingsStore.localUserId), 15)
        XCTAssertEqual(subject.state.sessionTimeoutValue, .fifteenMinutes)
    }

    /// `perform(_:)` with `.streamFlightRecorderLog` subscribes to the active flight recorder log.
    @MainActor
    func test_perform_streamFlightRecorderLog() async throws {
        XCTAssertNil(subject.state.flightRecorderState.activeLog)

        let task = Task {
            await subject.perform(.streamFlightRecorderLog)
        }
        defer { task.cancel() }

        let log = FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now)
        flightRecorder.activeLogSubject.send(log)
        try await waitForAsync { self.subject.state.flightRecorderState.activeLog != nil }
        XCTAssertEqual(subject.state.flightRecorderState.activeLog, log)

        flightRecorder.activeLogSubject.send(nil)
        try await waitForAsync { self.subject.state.flightRecorderState.activeLog == nil }
        XCTAssertNil(subject.state.flightRecorderState.activeLog)
    }

    /// Performing `.toggleUnlockWithBiometrics` with a `false` value disables biometric unlock and resets the
    /// session timeout to `.never`
    @MainActor
    func test_perform_toggleUnlockWithBiometrics_off() async throws {
        biometricsRepository.capturedUserAuthKey = "key"
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.faceID, enabled: true, hasValidIntegrity: true),
        )
        subject.state.sessionTimeoutValue = .fifteenMinutes
        appSettingsStore.setVaultTimeout(minutes: 15, userId: appSettingsStore.localUserId)

        await subject.perform(.toggleUnlockWithBiometrics(false))

        XCTAssertNil(biometricsRepository.capturedUserAuthKey)
        XCTAssertEqual(subject.state.sessionTimeoutValue, .never)
    }

    /// Performing `.toggleUnlockWithBiometrics` with a `true` value enables biometric unlock and defaults the
    /// session timeout to `.onAppRestart`.
    @MainActor
    func test_perform_toggleUnlockWithBiometrics_on() async throws {
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.faceID, enabled: true, hasValidIntegrity: true),
        )

        await subject.perform(.toggleUnlockWithBiometrics(true))

        XCTAssertNotNil(biometricsRepository.capturedUserAuthKey)
        XCTAssertEqual(subject.state.sessionTimeoutValue, .onAppRestart)
    }

    /// Receiving `.backupTapped` shows an alert for the backup information.
    @MainActor
    func test_receive_backupTapped() async throws {
        subject.receive(.backupTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.learnMore)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.backupInformation)
    }

    /// Receiving `.defaultSaveChanged` updates the user's `defaultSaveOption` app setting.
    @MainActor
    func test_receive_defaultSaveChanged() {
        subject.state.defaultSaveOption = .none
        subject.receive(.defaultSaveChanged(.saveHere))

        XCTAssertEqual(appSettingsStore.defaultSaveOption, .saveHere)
        XCTAssertEqual(subject.state.defaultSaveOption, .saveHere)
    }

    /// Receiving `.exportItemsTapped` navigates to the export vault screen.
    @MainActor
    func test_receive_exportVaultTapped() {
        subject.receive(.exportItemsTapped)

        XCTAssertEqual(coordinator.routes.last, .exportItems)
    }

    /// `receive(_:)` with action `.flightRecorder(.viewLogsTapped)` navigates to the view flight
    /// recorder logs screen.
    @MainActor
    func test_receive_flightRecorder_viewFlightRecorderLogsTapped() {
        subject.receive(.flightRecorder(.viewLogsTapped))

        XCTAssertEqual(coordinator.routes, [.flightRecorder(.flightRecorderLogs)])
    }

    /// Receiving `.syncWithBitwardenAppTapped` adds the Password Manager settings URL to the state to
    /// navigate the user to the BWPM app's settings.
    @MainActor
    func test_receive_syncWithBitwardenAppTapped_installed() {
        application.canOpenUrlResponse = true
        subject.receive(.syncWithBitwardenAppTapped)

        XCTAssertEqual(subject.state.url, ExternalLinksConstants.passwordManagerSettings)
    }

    /// Receiving `.syncWithBitwardenAppTapped` adds the Password Manager settings App Store URL to
    /// the state to navigate the user to the App Store when the BWPM app is not installed..
    @MainActor
    func test_receive_syncWithBitwardenAppTapped_notInstalled() {
        application.canOpenUrlResponse = false
        subject.receive(.syncWithBitwardenAppTapped)

        XCTAssertEqual(subject.state.url, ExternalLinksConstants.passwordManagerLink)
    }

    /// Receiving `.versionTapped` copies the copyright, the version string and device info to the pasteboard.
    @MainActor
    func test_receive_versionTapped() {
        subject.receive(.versionTapped)
        XCTAssertEqual(
            pasteboardService.copiedString,
            """
            © Bitwarden Inc. 2015–2025

            📝 Bitwarden 1.0 (1)
            📦 Bundle: com.8bit.bitwarden
            📱 Device: iPhone14,2
            🍏 System: iOS 16.4
            """,
        )
        XCTAssertEqual(
            subject.state.toast?.title,
            Toast(title: Localizations.valueHasBeenCopied(Localizations.appInfo)).title,
        )
    }
}
