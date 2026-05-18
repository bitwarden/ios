import BitwardenKit
import BitwardenSdk
import Foundation

/// Protocol defining the functionality of a TOTP (Time-based One-Time Password) service.
protocol TOTPService {
    /// Calculates the next TOTP code (the one valid in the upcoming period) for a given key.
    ///
    /// - Parameters:
    ///   - key: The `TOTPKeyModel` to generate the next code for.
    ///
    func getNextTOTPCode(for key: TOTPKeyModel) async throws -> TOTPCodeModel

    /// Calculates the TOTP code for a given key
    ///
    /// - Parameters:
    ///   - key: The `TOTPKeyModel` to generate a code for
    ///
    func getTotpCode(for key: TOTPKeyModel) async throws -> TOTPCodeModel

    /// Retrieves the TOTP configuration for a given key.
    ///
    /// - Parameter key: A string representing the TOTP key.
    /// - Throws: `TOTPKeyError.invalidKeyFormat` if the key format is invalid.
    /// - Returns: A `TOTPKeyModel` containing the configuration details.
    func getTOTPConfiguration(key: String?) throws -> TOTPKeyModel
}

/// Default implementation of the `TOTPService`.
class DefaultTOTPService {
    // MARK: Properties

    /// The service used by the application to handle encryption and decryption tasks.
    private let clientService: ClientService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used to get the present time.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initialize a `DefaultTOTPService`.
    ///
    /// - Parameters:
    ///   - clientService: The service used by the application to handle encryption and decryption tasks.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - timeProvider: The service used to get the present time.
    ///
    init(
        clientService: ClientService,
        errorReporter: ErrorReporter,
        timeProvider: TimeProvider,
    ) {
        self.clientService = clientService
        self.errorReporter = errorReporter
        self.timeProvider = timeProvider
    }
}

extension DefaultTOTPService: TOTPService {
    func getNextTOTPCode(for key: TOTPKeyModel) async throws -> TOTPCodeModel {
        let nextDate = timeProvider.presentTime.addingTimeInterval(Double(key.period))
        return try await clientService.vault().generateTOTPCode(
            for: key.rawAuthenticatorKey,
            date: nextDate,
        )
    }

    func getTotpCode(for key: TOTPKeyModel) async throws -> TOTPCodeModel {
        try await clientService.vault().generateTOTPCode(
            for: key.rawAuthenticatorKey,
            date: timeProvider.presentTime,
        )
    }

    func getTOTPConfiguration(key: String?) throws -> TOTPKeyModel {
        guard let key,
              let config = TOTPKeyModel(authenticatorKey: key) else {
            throw TOTPKeyError.invalidKeyFormat
        }
        return config
    }
}
