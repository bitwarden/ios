import AuthenticatorBridgeKit
import AuthenticatorBridgeKitMocks
import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import Networking
import TestHelpers

@testable import BitwardenShared
@testable import BitwardenSharedMocks

extension ServiceContainer {
    @MainActor
    static func withMocks( // swiftlint:disable:this function_body_length
        application: Application? = nil,
        appContextHelper: AppContextHelper = MockAppContextHelper(),
        appInfoService: AppInfoService = MockAppInfoService(),
        appSettingsStore: AppSettingsStore = MockAppSettingsStore(),
        authRepository: AuthRepository = MockAuthRepository(),
        authService: AuthService = MockAuthService(),
        authenticatorSyncService: AuthenticatorSyncService = MockAuthenticatorSyncService(),
        autofillCredentialService: AutofillCredentialService = MockAutofillCredentialService(),
        biometricsRepository: BiometricsRepository = MockBiometricsRepository(),
        biometricsService: BiometricsService = MockBiometricsService(),
        cameraService: CameraService = MockCameraService(),
        changeKdfService: ChangeKdfService = MockChangeKdfService(),
        clientService: ClientService = MockClientService(),
        configService: ConfigService = MockConfigService(),
        environmentService: EnvironmentService = MockEnvironmentService(),
        errorReportBuilder: ErrorReportBuilder = MockErrorReportBuilder(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        eventService: EventService = MockEventService(),
        exportCXFCiphersRepository: ExportCXFCiphersRepository = MockExportCXFCiphersRepository(),
        exportVaultService: ExportVaultService = MockExportVaultService(),
        fido2CredentialStore: Fido2CredentialStore = MockFido2CredentialStore(),
        fido2UserInterfaceHelper: Fido2UserInterfaceHelper = MockFido2UserInterfaceHelper(),
        flightRecorder: FlightRecorder = MockFlightRecorder(),
        generatorRepository: GeneratorRepository = MockGeneratorRepository(),
        importCiphersRepository: ImportCiphersRepository = MockImportCiphersRepository(),
        httpClient: HTTPClient = MockHTTPClient(),
        keychainRepository: KeychainRepository = MockKeychainRepository(),
        keychainService: KeychainService = MockKeychainService(),
        languageStateService: LanguageStateService = MockLanguageStateService(),
        localAuthService: LocalAuthService = MockLocalAuthService(),
        migrationService: MigrationService = MockMigrationService(),
        nfcReaderService: NFCReaderService = MockNFCReaderService(),
        notificationService: NotificationService = MockNotificationService(),
        pasteboardService: PasteboardService = MockPasteboardService(),
        pendingAppIntentActionMediator: PendingAppIntentActionMediator = MockPendingAppIntentActionMediator(),
        policyService: PolicyService = MockPolicyService(),
        notificationCenterService: NotificationCenterService = MockNotificationCenterService(),
        rehydrationHelper: RehydrationHelper = MockRehydrationHelper(),
        reviewPromptService: ReviewPromptService = MockReviewPromptService(),
        searchProcessorMediatorFactory: SearchProcessorMediatorFactory? = nil,
        sendRepository: SendRepository = MockSendRepository(),
        settingsRepository: SettingsRepository = MockSettingsRepository(),
        sharedTimeoutService: SharedTimeoutService = MockSharedTimeoutService(),
        stateService: StateService = MockStateService(),
        syncService: SyncService = MockSyncService(),
        systemDevice: SystemDevice = MockSystemDevice(),
        textAutofillHelperFactory: TextAutofillHelperFactory = MockTextAutofillHelperFactory(),
        timeProvider: TimeProvider = MockTimeProvider(.currentTime),
        trustDeviceService: TrustDeviceService = MockTrustDeviceService(),
        tokenService: TokenService = MockTokenService(),
        totpExpirationManagerFactory: TOTPExpirationManagerFactory = MockTOTPExpirationManagerFactory(),
        totpService: TOTPService = MockTOTPService(),
        twoStepLoginService: TwoStepLoginService = MockTwoStepLoginService(),
        userSessionStateService: UserSessionStateService = MockUserSessionStateService(),
        userVerificationHelperFactory: UserVerificationHelperFactory = MockUserVerificationHelperFactory(),
        vaultRepository: VaultRepository = MockVaultRepository(),
        vaultTimeoutService: VaultTimeoutService = MockVaultTimeoutService(),
        watchService: WatchService = MockWatchService(),
    ) -> ServiceContainer {
        var actualSearchProcessorMediatorFactory: SearchProcessorMediatorFactory
        if let searchProcessorMediatorFactory {
            actualSearchProcessorMediatorFactory = searchProcessorMediatorFactory
        } else {
            // This is needed to provide a default mock value for `makeReturnValue` of the factory
            // or it breaks tests where the factory isn't defined and uses the default factory mock.
            let factoryMock = MockSearchProcessorMediatorFactory()
            factoryMock.makeReturnValue = MockSearchProcessorMediator()
            actualSearchProcessorMediatorFactory = factoryMock
        }

        return ServiceContainer(
            apiService: APIService(
                client: httpClient,
                environmentService: environmentService,
            ),
            appContextHelper: appContextHelper,
            appIdService: AppIdService(appSettingStore: appSettingsStore),
            appInfoService: appInfoService,
            application: application,
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            authService: authService,
            authenticatorSyncService: authenticatorSyncService,
            autofillCredentialService: autofillCredentialService,
            biometricsRepository: biometricsRepository,
            biometricsService: biometricsService,
            cameraService: cameraService,
            changeKdfService: changeKdfService,
            clientService: clientService,
            configService: configService,
            environmentService: environmentService,
            errorReportBuilder: errorReportBuilder,
            errorReporter: errorReporter,
            eventService: eventService,
            exportCXFCiphersRepository: exportCXFCiphersRepository,
            exportVaultService: exportVaultService,
            fido2CredentialStore: fido2CredentialStore,
            fido2UserInterfaceHelper: fido2UserInterfaceHelper,
            flightRecorder: flightRecorder,
            generatorRepository: generatorRepository,
            importCiphersRepository: importCiphersRepository,
            keychainRepository: keychainRepository,
            keychainService: keychainService,
            languageStateService: languageStateService,
            localAuthService: localAuthService,
            migrationService: migrationService,
            nfcReaderService: nfcReaderService,
            notificationCenterService: notificationCenterService,
            notificationService: notificationService,
            pasteboardService: pasteboardService,
            pendingAppIntentActionMediator: pendingAppIntentActionMediator,
            policyService: policyService,
            rehydrationHelper: rehydrationHelper,
            reviewPromptService: reviewPromptService,
            searchProcessorMediatorFactory: actualSearchProcessorMediatorFactory,
            sendRepository: sendRepository,
            settingsRepository: settingsRepository,
            sharedTimeoutService: sharedTimeoutService,
            stateService: stateService,
            syncService: syncService,
            systemDevice: systemDevice,
            textAutofillHelperFactory: textAutofillHelperFactory,
            timeProvider: timeProvider,
            tokenService: tokenService,
            totpExpirationManagerFactory: totpExpirationManagerFactory,
            totpService: totpService,
            trustDeviceService: trustDeviceService,
            twoStepLoginService: twoStepLoginService,
            userSessionStateService: userSessionStateService,
            userVerificationHelperFactory: userVerificationHelperFactory,
            vaultRepository: vaultRepository,
            vaultTimeoutService: vaultTimeoutService,
            watchService: watchService,
        )
    }
}
