import BitwardenKit
import BitwardenSdk

/// The services provided by the `ServiceContainer`.
typealias Services = HasAppInfoService
    & HasAppSettingsStore
    & HasApplication
    & HasAuthenticatorItemRepository
    & HasBiometricsRepository
    & HasCameraService
    & HasConfigService
    & HasCryptographyService
    & HasErrorReportBuilder
    & HasErrorReporter
    & HasExportItemsService
    & HasFlightRecorder
    & HasImportItemsService
    & HasLanguageStateService
    & HasNotificationCenterService
    & HasPasteboardService
    & HasStateService
    & HasTOTPExpirationManagerFactory
    & HasTOTPService
    & HasTimeProvider

/// Protocol for an object that provides an `Application`
///
protocol HasApplication {
    /// The service used to interact with the Application service.
    var application: Application? { get }
}

/// Protocol for an object that provides an AppSettingsStore.
///
protocol HasAppSettingsStore {
    var appSettingsStore: AppSettingsStore { get }
}

/// Protocol for an object that provides an `AuthenticatorItemRepository`
///
protocol HasAuthenticatorItemRepository {
    /// The service used to interact with the data layer for items
    var authenticatorItemRepository: AuthenticatorItemRepository { get }
}

/// Protocol for obtaining the device's biometric authentication type.
///
protocol HasBiometricsRepository {
    /// The repository used to obtain the available authentication policies and access controls for the user's device.
    var biometricsRepository: BiometricsRepository { get }
}

/// Protocol for an object that provides a `CameraService`.
///
protocol HasCameraService {
    /// The service used by the application to query for and request camera authorization.
    var cameraService: CameraService { get }
}

/// Protocol for an object that provides a `CryptographyService`
///
protocol HasCryptographyService {
    /// The service used by the application to encrypt and decrypt items
    var cryptographyService: CryptographyService { get }
}

/// Protocol for an object that provides an `ExportItemsService`.
///
protocol HasExportItemsService {
    /// The service used to export items.
    var exportItemsService: ExportItemsService { get }
}

/// Protocol for an object that provides an `ImportItemsService`.
///
protocol HasImportItemsService {
    /// The service used to import items.
    var importItemsService: ImportItemsService { get }
}

/// Protocol for an object that provides a `NotificationCenterService`.
///
protocol HasNotificationCenterService {
    ///  The service used to receive foreground and background notifications.
    var notificationCenterService: NotificationCenterService { get }
}

/// Protocol for an object that provides a `PasteboardService`.
///
protocol HasPasteboardService {
    /// The service used by the application for sharing data with other apps.
    var pasteboardService: PasteboardService { get }
}

/// Protocol for an object that provides a `StateService`.
///
protocol HasStateService {
    /// The service used by the application to manage account state.
    var stateService: StateService { get }
}

/// Protocol for an object that provides a `TOTPService`.
///
protocol HasTOTPService {
    /// A service used to validate authentication keys and generate TOTP codes.
    var totpService: TOTPService { get }
}

/// Protocol for an object that provides a `TOTPExpirationManagerFactory`.
///
protocol HasTOTPExpirationManagerFactory {
    /// Factory to create TOTP expiration managers.
    var totpExpirationManagerFactory: TOTPExpirationManagerFactory { get }
}
