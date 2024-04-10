import BitwardenSdk

/// The services provided by the `ServiceContainer`.
typealias Services = HasAuthenticatorItemRepository
    & HasCameraService
    & HasCryptographyService
    & HasErrorReporter
    & HasPasteboardService
    & HasTOTPService
    & HasTimeProvider

/// Protocol for an object that provides an `AuthenticatorItemRepository`
///
protocol HasAuthenticatorItemRepository {
    /// The service used to interact with the data layer for items
    var authenticatorItemRepository: AuthenticatorItemRepository { get }
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

/// Protocol for an object that provides an `ErrorReporter`.
///
protocol HasErrorReporter {
    /// The service used by the application to report non-fatal errors.
    var errorReporter: ErrorReporter { get }
}

/// Protocol for an object that provides a `PasteboardService`.
///
protocol HasPasteboardService {
    /// The service used by the application for sharing data with other apps.
    var pasteboardService: PasteboardService { get }
}

/// Protocol for an object that provides a `TOTPService`.
///
protocol HasTOTPService {
    /// A service used to validate authentication keys and generate TOTP codes.
    var totpService: TOTPService { get }
}

/// Protocol for an object that provides a `TimeProvider`.
///
protocol HasTimeProvider {
    /// Provides the present time for TOTP Code Calculation.
    var timeProvider: TimeProvider { get }
}
