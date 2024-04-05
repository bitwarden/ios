import BitwardenSdk

/// The services provided by the `ServiceContainer`.
typealias Services = HasAPIService
    & HasAccountAPIService
    & HasAppIdService
    & HasAppSettingsStore
    & HasAuthAPIService
    & HasAuthRepository
    & HasAuthService
    & HasBiometricsRepository
    & HasCameraService
    & HasCaptchaService
    & HasClientService
    & HasDeviceAPIService
    & HasEnvironmentService
    & HasErrorReporter
    & HasExportVaultService
    & HasFileAPIService
    & HasGeneratorRepository
    & HasNFCReaderService
    & HasNotificationCenterService
    & HasNotificationService
    & HasOrganizationAPIService
    & HasPasteboardService
    & HasPolicyService
    & HasSendRepository
    & HasSettingsRepository
    & HasStateService
    & HasSystemDevice
    & HasTOTPService
    & HasTimeProvider
    & HasTwoStepLoginService
    & HasVaultRepository
    & HasVaultTimeoutService
    & HasWatchService

/// Protocol for an object that provides an `AccountAPIService`.
///
protocol HasAccountAPIService {
    /// The services used by the application to make account related API requests.
    var accountAPIService: AccountAPIService { get }
}

/// Protocol for an object that provides an `APIService`.
///
protocol HasAPIService {
    /// The service used by the application to make API requests.
    var apiService: APIService { get }
}

/// Protocol for an object that provides an `AppIdService`.
///
protocol HasAppIdService {
    /// The service used by the application to manage the app's ID.
    var appIdService: AppIdService { get }
}

/// Protocol for an object that provides an `AppSettingsStore`.
///
protocol HasAppSettingsStore {
    /// The service used by the application to persist app setting values.
    var appSettingsStore: AppSettingsStore { get }
}

/// Protocol for an object that provides an `AuthAPIService`.
///
protocol HasAuthAPIService {
    /// The service used by the application to make auth-related API requests.
    var authAPIService: AuthAPIService { get }
}

/// Protocol for an object that provides an `AuthRepository`.
///
protocol HasAuthRepository {
    /// The repository used by the application to manage auth data for the UI layer.
    var authRepository: AuthRepository { get }
}

/// Protocol for an object that provides an `AuthService`.
///
protocol HasAuthService {
    /// The service used by the application to handle authentication tasks.
    var authService: AuthService { get }
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

/// Protocol for an object that provides a `CaptchaService`.
///
protocol HasCaptchaService {
    /// The service used by the application to generate captcha related artifacts.
    var captchaService: CaptchaService { get }
}

/// Protocol for an object that provides a `ClientAuth`.
///
protocol HasClientAuth {
    /// The client used by the application to handle auth related encryption and decryption tasks.
    var clientAuth: ClientAuthProtocol { get }
}

/// Protocol for an object that provides a `ClientExportersProtocol`.
///
protocol HasClientExporters {
    /// The client used by the application to handle auth related encryption and decryption tasks.
    var clientExporters: ClientExportersProtocol { get }
}

protocol HasClientService {
    /// The client used by the application to handle auth related encryption and decryption tasks.
    var clientService: ClientService { get }
}

/// Protocol for an object that provides a `DeviceAPIService`.
///
protocol HasDeviceAPIService {
    /// The service used by the application to make device-related API requests.
    var deviceAPIService: DeviceAPIService { get }
}

/// Protocol for an object that provides an `EnvironmentService`.
///
protocol HasEnvironmentService {
    /// The service used by the application to manage the environment settings.
    var environmentService: EnvironmentService { get }
}

/// Protocol for an object that provides an `ErrorReporter`.
///
protocol HasErrorReporter {
    /// The service used by the application to report non-fatal errors.
    var errorReporter: ErrorReporter { get }
}

/// Protocol for an object that provides a `ExportVaultService`.
///
protocol HasExportVaultService {
    /// The service used by the application to handle vault export tasks.
    var exportVaultService: ExportVaultService { get }
}

/// Protocol for an object that provides a `FileAPIService`.
///
protocol HasFileAPIService {
    /// The service used by the application to make file-related API requests.
    var fileAPIService: FileAPIService { get }
}

/// Protocol for an object that provides a `GeneratorRepository`.
///
protocol HasGeneratorRepository {
    /// The repository used by the application to manage generator data for the UI layer.
    var generatorRepository: GeneratorRepository { get }
}

/// Protocol for an object that provides a `NFCReaderService`.
///
protocol HasNFCReaderService {
    /// The service used by the application to read NFC tags.
    var nfcReaderService: NFCReaderService { get }
}

/// Protocol for an object that provides a `NotificationService`.
///
protocol HasNotificationService {
    /// The service used by the application to handle notifications.
    var notificationService: NotificationService { get }
}

/// Protocol for an object that provides a `PasteboardService`.
///
protocol HasPasteboardService {
    /// The service used by the application for sharing data with other apps.
    var pasteboardService: PasteboardService { get }
}

/// Protocol for an object that provides a `NotificationCenterService`.
///
protocol HasNotificationCenterService {
    /// The service used by the application to access the system's notification center.
    var notificationCenterService: NotificationCenterService { get }
}

/// Protocol for an object that provides an `OrganizationAPIService`.
///
protocol HasOrganizationAPIService {
    /// The service used by the application to make organization-related API requests.
    var organizationAPIService: OrganizationAPIService { get }
}

/// Protocol for an object that provides a `PolicyService`.
///
protocol HasPolicyService {
    /// The service for managing the polices for the user.
    var policyService: PolicyService { get }
}

/// Protocol for an object that provides a `SendRepository`.
///
public protocol HasSendRepository {
    /// The repository used by the application to manage send data for the UI layer.
    var sendRepository: SendRepository { get }
}

/// Protocol for an object that provides a `SettingsRepository`.
///
protocol HasSettingsRepository {
    /// The repository used by the application to manage data and services access for the UI layer.
    var settingsRepository: SettingsRepository { get }
}

/// Protocol for an object that provides a `StateService`.
///
protocol HasStateService {
    /// The service used by the application to manage account state.
    var stateService: StateService { get }
}

/// Protocol for an object that provides a `SystemDevice`.
///
protocol HasSystemDevice {
    /// The object used by the application to retrieve information about this device.
    var systemDevice: SystemDevice { get }
}

/// Protocol for an object that provides a `TimeProvider`.
///
protocol HasTimeProvider {
    /// Provides the present time for TOTP Code Calculation.
    var timeProvider: TimeProvider { get }
}

/// Protocol for an object that provides a `TOTPService`.
///
protocol HasTOTPService {
    /// A service used to validate authentication keys and generate TOTP codes.
    var totpService: TOTPService { get }
}

/// Protocol for an object that provides a `TwoStepLoginService`.
///
protocol HasTwoStepLoginService {
    /// The service used by the application to generate a two step login URL.
    var twoStepLoginService: TwoStepLoginService { get }
}

/// Protocol for an object that provides a `VaultRepository`.
///
protocol HasVaultRepository {
    /// The repository used by the application to manage vault data for the UI layer.
    var vaultRepository: VaultRepository { get }
}

/// Protocol for an object that provides a `VaultTimeoutService`.
///
protocol HasVaultTimeoutService {
    /// The repository used by the application to manage timeouts for vault access for all accounts.
    var vaultTimeoutService: VaultTimeoutService { get }
}

/// Protocol for an object that provides a `WatchService`.
///
protocol HasWatchService {
    /// The service used by the application to connect to and communicate with the watch app.
    var watchService: WatchService { get }
}
