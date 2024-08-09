import Foundation

/// Protocol defining the functionality of a TOTP (Time-based One-Time Password) service.
protocol TOTPService {
    /// Retrieves the TOTP configuration for a given key.
    ///
    /// - Parameter key: A string representing the TOTP key.
    /// - Throws: `TOTPServiceError.invalidKeyFormat` if the key format is invalid.
    /// - Returns: A `TOTPKeyModel` containing the configuration details.
    func getTOTPConfiguration(key: String?) throws -> TOTPKeyModel
}

/// Default implementation of the `TOTPService`.
struct DefaultTOTPService: TOTPService {
    /// Retrieves the TOTP configuration for a given key.
    ///
    /// - Parameter key: A string representing the TOTP key.
    /// - Throws: `TOTPServiceError.invalidKeyFormat` if the key format is invalid.
    /// - Returns: A `TOTPKeyModel` containing the configuration details.
    func getTOTPConfiguration(key: String?) throws -> TOTPKeyModel {
        guard let key,
              let config = TOTPKeyModel(authenticatorKey: key) else {
            throw TOTPServiceError.invalidKeyFormat
        }
        return config
    }
}
