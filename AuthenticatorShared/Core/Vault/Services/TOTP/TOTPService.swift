import BitwardenSdk
import Foundation

/// Protocol defining the functionality of a TOTP (Time-based One-Time Password) service.
protocol TOTPService {
    /// Calculates the TOTP code for a given key
    ///
    /// - Parameters:
    ///   - key: The `TOTPKeyModel` to generate a code for
    ///
    func getTotpCode(for key: TOTPKeyModel) async throws -> TOTPCodeModel

    /// Retrieves the TOTP configuration for a given key.
    ///
    /// - Parameter key: A string representing the TOTP key.
    /// - Throws: `TOTPServiceError.invalidKeyFormat` if the key format is invalid.
    /// - Returns: A `TOTPKeyModel` containing the configuration details.
    func getTOTPConfiguration(key: String?) throws -> TOTPKeyModel
}

/// Default implementation of the `TOTPService`.
class DefaultTOTPService {
    // MARK: Properties

    /// The service to communicate with the SDK for encryption/decryption tasks.
    private let clientVault: ClientVaultService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used to get the present time.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initialize a `DefaultTOTPService`.
    ///
    /// - Parameters:
    ///   - clientVault: The service to communicate with the SDK for encryption/decryption tasks.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - timeProvider: The service used to get the present time.
    ///
    init(
        clientVault: ClientVaultService,
        errorReporter: ErrorReporter,
        timeProvider: TimeProvider
    ) {
        self.clientVault = clientVault
        self.errorReporter = errorReporter
        self.timeProvider = timeProvider
    }
}

extension DefaultTOTPService: TOTPService {
    func getTotpCode(for key: TOTPKeyModel) async throws -> TOTPCodeModel {
        try await clientVault.generateTOTPCode(
            for: key.rawAuthenticatorKey,
            date: timeProvider.presentTime
        )
    }

    func getTOTPConfiguration(key: String?) throws -> TOTPKeyModel {
        guard let key,
              let config = TOTPKeyModel(authenticatorKey: key) else {
            throw TOTPServiceError.invalidKeyFormat
        }
        return config
    }
}
