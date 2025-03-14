import CryptoKit
import Foundation

// MARK: - CryptographyService

/// A protocol for a `CryptographyService` which manages encrypting and decrypting `AuthenticationItem` objects
///
protocol CryptographyService {
    func encrypt(_ authenticatorItemView: AuthenticatorItemView) async throws -> AuthenticatorItem

    func decrypt(_ authenticatorItem: AuthenticatorItem) async throws -> AuthenticatorItemView
}

class DefaultCryptographyService: CryptographyService {
    // MARK: Properties

    /// A service to get the encryption secret key
    ///
    let cryptographyKeyService: CryptographyKeyService

    // MARK: Initialization

    /// Initializes a `CryptographyService`.
    ///
    /// - Parameters:
    ///   - cryptographyKeyService: A service for getting the cryptography key
    ///
    init(
        cryptographyKeyService: CryptographyKeyService
    ) {
        self.cryptographyKeyService = cryptographyKeyService
    }

    // MARK: Methods

    /// Encrypts an `AuthenticatorItemView` so that it can be stored in Core Data.
    ///
    /// - Parameters:
    ///   - authenticatorItemView: The item to encrypt.
    /// - Returns: An encrypted `AuthenticatorItem`.
    ///
    func encrypt(_ authenticatorItemView: AuthenticatorItemView) async throws -> AuthenticatorItem {
        let secretKey = try await cryptographyKeyService.getOrCreateSecretKey(userId: "local")

        guard let encryptedName = try encryptString(authenticatorItemView.name, withKey: secretKey) else {
            throw CryptographyError.unableToEncryptRequiredField
        }

        return try AuthenticatorItem(
            favorite: authenticatorItemView.favorite,
            id: authenticatorItemView.id,
            name: encryptedName,
            totpKey: encryptString(authenticatorItemView.totpKey, withKey: secretKey),
            username: encryptString(authenticatorItemView.username, withKey: secretKey)
        )
    }

    /// Decrypts an `AuthenticatorItem`.
    ///
    /// - Parameters:
    ///   - authenticatorItem: The item to decrypt.
    /// - Returns: An unencrypted `AuthenticatorItemView`.
    ///
    func decrypt(_ authenticatorItem: AuthenticatorItem) async throws -> AuthenticatorItemView {
        let secretKey = try await cryptographyKeyService.getOrCreateSecretKey(userId: "local")

        return try AuthenticatorItemView(
            favorite: authenticatorItem.favorite,
            id: authenticatorItem.id,
            name: decryptString(authenticatorItem.name, withKey: secretKey) ?? "",
            totpKey: decryptString(authenticatorItem.totpKey, withKey: secretKey),
            username: decryptString(authenticatorItem.username, withKey: secretKey)
        )
    }

    // MARK: Private Methods

    /// Encrypts a string given a key.
    ///
    /// - Parameters:
    ///   - string: The string to encrypt.
    ///   - withKey: The key to encrypt with.
    /// - Returns: An encrypted string, or `nil` if it was unable to convert the passed-in string into data.
    ///
    func encryptString(_ string: String?, withKey secretKey: SymmetricKey) throws -> String? {
        guard let data = string?.data(using: .utf8) else {
            return nil
        }

        let encryptedSealedBox = try AES.GCM.seal(
            data,
            using: secretKey
        )

        return encryptedSealedBox.combined?.base64EncodedString()
    }

    /// Decrypts a string given a key.
    ///
    /// - Parameters:
    ///   - string: The string to decrypt.
    ///   - withKey: The key to decrypt with.
    /// - Returns: A decrypted string, or `nil` if the passed-in string was not encoded in Base64.
    func decryptString(_ string: String?, withKey secretKey: SymmetricKey) throws -> String? {
        guard let string = string?.nilIfEmpty, let data = Data(base64Encoded: string) else {
            return nil
        }

        let encryptedSealedBox = try AES.GCM.SealedBox(
            combined: data
        )

        let decryptedBox = try AES.GCM.open(
            encryptedSealedBox,
            using: secretKey
        )

        return String(data: decryptedBox, encoding: .utf8)
    }
}

// MARK: - CryptographyError

enum CryptographyError: Error {
    case unableToEncryptRequiredField
    case unableToParseSecretKey
}
