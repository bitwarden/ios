import AuthenticatorBridgeKit
import BitwardenKit
import BitwardenSdk

/// The services provided by the `ServiceContainer`.
typealias Services = HasAPIService
    & HasAccountAPIService
    & HasAppContextHelper
    & HasAppIdService
    & HasAppInfoService
    & HasAppSettingsStore
    & HasApplication
    & HasAuthAPIService
    & HasAuthRepository
    & HasAuthService
    & HasAutofillCredentialService
    & HasBiometricsRepository
    & HasCameraService
    & HasChangeKdfService
    & HasClientService
    & HasConfigService
    & HasDeviceAPIService
    & HasEnvironmentService
    & HasErrorReportBuilder
    & HasErrorReporter
    & HasEventService
    & HasExportCXFCiphersRepository
    & HasExportVaultService
    & HasFido2CredentialStore
    & HasFido2UserInterfaceHelper
    & HasFileAPIService
    & HasFlightRecorder
    & HasGeneratorRepository
    & HasImportCiphersRepository
    & HasLanguageStateService
    & HasLocalAuthService
    & HasNFCReaderService
    & HasNotificationCenterService
    & HasNotificationService
    & HasOrganizationAPIService
    & HasPasteboardService
    & HasPendingAppIntentActionMediator
    & HasPolicyService
    & HasRehydrationHelper
    & HasReviewPromptService
    & HasSendRepository
    & HasSettingsRepository
    & HasSharedTimeoutService
    & HasStateService
    & HasSyncService
    & HasSystemDevice
    & HasTOTPExpirationManagerFactory
    & HasTOTPService
    & HasTextAutofillHelperFactory
    & HasTimeProvider
    & HasTrustDeviceService
    & HasTwoStepLoginService
    & HasUserVerificationHelperFactory
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

/// Protocol for an object that provides an `AppContextHelper`.
///
protocol HasAppContextHelper {
    /// Helper used to know app context.
    var appContextHelper: AppContextHelper { get }
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

/// Protocol for an object that provides an `Application`.
///
protocol HasApplication {
    /// The application instance, if the app isn't running in an extension.
    var application: Application? { get }
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

/// Protocol for an object that provides an `AutofillCredentialService`.
///
protocol HasAutofillCredentialService {
    /// /// The service which manages the ciphers exposed to the system for AutoFill suggestions..
    var autofillCredentialService: AutofillCredentialService { get }
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

/// Protocol for an object that provides a `ChangeKdfService`.
///
protocol HasChangeKdfService {
    /// The service used to change the user's KDF settings.
    var changeKdfService: ChangeKdfService { get }
}

/// Protocol for an object that provides a `ClientService`.
///
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

/// Protocol for an object that provides an `EventService`.
///
protocol HasEventService {
    /// The service used by the application to record events.
    var eventService: EventService { get }
}

/// Protocol for an object that provides an `ExportCXFCiphersRepository`.
///
protocol HasExportCXFCiphersRepository {
    /// The repository to handle exporting ciphers in Credential Exchange Format.
    var exportCXFCiphersRepository: ExportCXFCiphersRepository { get }
}

/// Protocol for an object that provides a `ExportVaultService`.
///
protocol HasExportVaultService {
    /// The service used by the application to handle vault export tasks.
    var exportVaultService: ExportVaultService { get }
}

/// Protocol for an object that provides a `Fido2CredentialStore`.
///
protocol HasFido2CredentialStore {
    /// A store to be used on Fido2 flows to get/save credentials.
    var fido2CredentialStore: Fido2CredentialStore { get }
}

/// Protocol for an object that provides a `Fido2UserInterfaceHelper`.
///
protocol HasFido2UserInterfaceHelper {
    /// A helper to be used on Fido2 flows that requires user interaction and extends the capabilities
    /// of the `Fido2UserInterface` from the SDK.
    var fido2UserInterfaceHelper: Fido2UserInterfaceHelper { get }
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

/// Protocol for an object that provides a `ImportCiphersRepository`.
///
protocol HasImportCiphersRepository {
    /// The repository used by the application to manage importing credential in Credential Exhange flow.
    var importCiphersRepository: ImportCiphersRepository { get }
}

/// Protocol for an object that provides a `LocalAuthService`.
///
protocol HasLocalAuthService {
    /// The service used by the application to evaluate local auth policies.
    var localAuthService: LocalAuthService { get }
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

/// Protocol for an object that provides an `PendingAppIntentActionMediator`.
///
protocol HasPendingAppIntentActionMediator {
    /// The mediator to execute pending `AppIntent` actions.
    var pendingAppIntentActionMediator: PendingAppIntentActionMediator { get }
}

/// Protocol for an object that provides a `PolicyService`.
///
protocol HasPolicyService {
    /// The service for managing the polices for the user.
    var policyService: PolicyService { get }
}

/// Protocol for an object that provides a `RehydrationHelper`.
protocol HasRehydrationHelper {
    /// The helper for app rehydration.
    var rehydrationHelper: RehydrationHelper { get }
}

/// Protocol for an object that provides a `ReviewPromptService`.
protocol HasReviewPromptService {
    /// The service used by the application to determine if a user is eligible for a review prompt.
    var reviewPromptService: ReviewPromptService { get }
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

/// Protocol for an object that has a `SyncService`.
///
protocol HasSyncService {
    /// The service used by the application to sync account data.
    var syncService: SyncService { get }
}

/// Protocol for an object that provides a `SystemDevice`.
///
protocol HasSystemDevice {
    /// The object used by the application to retrieve information about this device.
    var systemDevice: SystemDevice { get }
}

/// Protocol for an object that provides a `TextAutofillHelperFactory`.
///
protocol HasTextAutofillHelperFactory {
    /// Helper to create `TextAutofillHelper`s`.
    var textAutofillHelperFactory: TextAutofillHelperFactory { get }
}

/// Protocol for an object that provides a `TOTPExpirationManagerFactory`.
///
protocol HasTOTPExpirationManagerFactory {
    /// Factory to create TOTP expiration managers.
    var totpExpirationManagerFactory: TOTPExpirationManagerFactory { get }
}

/// Protocol for an object that provides a `TOTPService`.
///
protocol HasTOTPService {
    /// A service used to validate authentication keys and generate TOTP codes.
    var totpService: TOTPService { get }
}

/// Protocol for an object that provides a `TrustDeviceService`.
///
protocol HasTrustDeviceService {
    /// A service used to handle device trust.
    var trustDeviceService: TrustDeviceService { get }
}

/// Protocol for an object that provides a `TwoStepLoginService`.
///
protocol HasTwoStepLoginService {
    /// The service used by the application to generate a two step login URL.
    var twoStepLoginService: TwoStepLoginService { get }
}

/// Protocol for an object that provides a `UserVerificationHelperFactory`.
///
protocol HasUserVerificationHelperFactory {
    /// A factory protocol to create `UserVerificationHelper`s.
    var userVerificationHelperFactory: UserVerificationHelperFactory { get }
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
