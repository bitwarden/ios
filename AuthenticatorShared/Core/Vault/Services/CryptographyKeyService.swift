import CryptoKit
import Foundation

/// A services that manages getting and creating the app's encryption secret key.
///
actor CryptographyKeyService {
    // MARK: Properties

    /// A repository to provide the encryption secret key
    ///
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `CryptographyKeyService`
    ///
    /// - Parameters:
    ///   - stateService: The state service for UserDefaults
    ///
    init(stateService: StateService) {
        self.stateService = stateService
    }

    // MARK: Methods

    /// Returns the encryption secret key if it exists or creates a new one
    ///
    /// - Parameters:
    ///   - userId: the user ID
    /// - Returns: the encryption secret key
    ///
    func getOrCreateSecretKey(userId: String) async throws -> SymmetricKey {
        do {
            guard let secretKey = try await stateService.getSecretKey(userId: userId),
                  let key = SymmetricKey(base64EncodedString: secretKey) else {
                throw CryptographyError.unableToParseSecretKey
            }
            return key
        } catch {
            let key = SymmetricKey(size: .bits256)
            try await stateService.setSecretKey(
                key.base64EncodedString(),
                userId: userId
            )
            return key
        }
    }
}

// MARK: - SymmetricKey Extensions

extension SymmetricKey {
    // MARK: Initialization

    /// Creates a `SymmetricKey` from a Base64-encoded `String`.
    ///
    /// - Parameters:
    ///   - base64EncodedString: The Base64-encoded string from which to generate the `SymmetricKey`.
    ///
    init?(base64EncodedString: String) {
        guard let data = Data(base64Encoded: base64EncodedString) else {
            return nil
        }

        self.init(data: data)
    }

    // MARK: Methods

    /// Serializes a `SymmetricKey` to a Base64-encoded `String`.
    func base64EncodedString() -> String {
        withUnsafeBytes { body in
            Data(body).base64EncodedString()
        }
    }
}
