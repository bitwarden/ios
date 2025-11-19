import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import Networking

@testable import AuthenticatorShared

extension ServiceContainer {
    static func withMocks(
        application: Application? = nil,
        appInfoService: AppInfoService = MockAppInfoService(),
        appSettingsStore: AppSettingsStore = MockAppSettingsStore(),
        authenticatorItemRepository: AuthenticatorItemRepository = MockAuthenticatorItemRepository(),
        biometricsRepository: BiometricsRepository = MockBiometricsRepository(),
        biometricsService: BiometricsService = MockBiometricsService(),
        cameraService: CameraService = MockCameraService(),
        clientService: ClientService = MockClientService(),
        configService: ConfigService = MockConfigService(),
        cryptographyService: CryptographyService = MockCryptographyService(),
        errorReportBuilder: ErrorReportBuilder = MockErrorReportBuilder(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        exportItemsService: ExportItemsService = MockExportItemsService(),
        flightRecorder: FlightRecorder = MockFlightRecorder(),
        importItemsService: ImportItemsService = MockImportItemsService(),
        languageStateService: LanguageStateService = MockLanguageStateService(),
        migrationService: MigrationService = MockMigrationService(),
        notificationCenterService: NotificationCenterService = MockNotificationCenterService(),
        pasteboardService: PasteboardService = MockPasteboardService(),
        stateService: StateService = MockStateService(),
        timeProvider: TimeProvider = MockTimeProvider(.currentTime),
        totpExpirationManagerFactory: TOTPExpirationManagerFactory = MockTOTPExpirationManagerFactory(),
        totpService: TOTPService = MockTOTPService(),
    ) -> ServiceContainer {
        ServiceContainer(
            application: application,
            appInfoService: appInfoService,
            appSettingsStore: appSettingsStore,
            authenticatorItemRepository: authenticatorItemRepository,
            biometricsRepository: biometricsRepository,
            biometricsService: biometricsService,
            cameraService: cameraService,
            clientService: clientService,
            configService: configService,
            cryptographyService: cryptographyService,
            errorReportBuilder: errorReportBuilder,
            errorReporter: errorReporter,
            exportItemsService: exportItemsService,
            flightRecorder: flightRecorder,
            importItemsService: importItemsService,
            languageStateService: languageStateService,
            migrationService: migrationService,
            notificationCenterService: notificationCenterService,
            pasteboardService: pasteboardService,
            stateService: stateService,
            timeProvider: timeProvider,
            totpExpirationManagerFactory: totpExpirationManagerFactory,
            totpService: totpService,
        )
    }
}
