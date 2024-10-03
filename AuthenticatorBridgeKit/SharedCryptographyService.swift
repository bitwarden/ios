import CryptoKit
import Foundation

// MARK: - SharedCryptographyService

/// A service for handling encrypting/decrypting items to be shared between the main
/// Bitwarden app and the Authenticator app.
///
public protocol SharedCryptographyService: AnyObject {
    /// Takes an array of `AuthenticatorBridgeItemDataModel` with encrypted data and
    /// returns the list with each member decrypted.
    ///
    /// - Parameter items: The encrypted array of items to be decrypted
    /// - Returns: the array of items with their data decrypted
    /// - Throws: AuthenticatorKeychainServiceError.keyNotFound if the Authenticator
    ///     key is not in the shared repository.
    ///
    func decryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataModel]
    ) async throws -> [AuthenticatorBridgeItemDataView]

    /// Takes an array of `AuthenticatorBridgeItemDataView` with decrypted data and
    /// returns the list with each member encrypted.
    ///
    /// - Parameter items: The decrypted array of items to be encrypted
    /// - Returns: the array of items with their data encrypted
    /// - Throws: AuthenticatorKeychainServiceError.keyNotFound if the Authenticator
    ///     key is not in the shared repository.
    ///
    func encryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataView]
    ) async throws -> [AuthenticatorBridgeItemDataModel]
}

/// A concrete implementation of the `SharedCryptographyService` protocol.
///
public class DefaultAuthenticatorCryptographyService: SharedCryptographyService {
    // MARK: Properties

    /// the `SharedKeyRepository` to obtain the shared Authenticator
    /// key to use in encrypting/decrypting
    private let sharedKeychainRepository: SharedKeychainRepository

    // MARK: Initialization

    /// Initialize a `DefaultAuthenticatorCryptographyService`
    ///
    /// - Parameter sharedKeychainRepository: the `SharedKeyRepository` to obtain the shared Authenticator
    ///     key to use in encrypting/decrypting
    ///
    public init(sharedKeychainRepository: SharedKeychainRepository) {
        self.sharedKeychainRepository = sharedKeychainRepository
    }

    // MARK: Methods

    public func decryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataModel]
    ) async throws -> [AuthenticatorBridgeItemDataView] {
        let key = try await sharedKeychainRepository.getAuthenticatorKey()
        let symmetricKey = SymmetricKey(data: key)

        return items.map { item in
            AuthenticatorBridgeItemDataView(
                favorite: item.favorite,
                id: item.id,
                name: (try? decrypt(item.name, withKey: symmetricKey)) ?? "",
                totpKey: try? decrypt(item.totpKey, withKey: symmetricKey),
                username: try? decrypt(item.username, withKey: symmetricKey)
            )
        }
    }

    public func encryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataView]
    ) async throws -> [AuthenticatorBridgeItemDataModel] {
        let key = try await sharedKeychainRepository.getAuthenticatorKey()
        let symmetricKey = SymmetricKey(data: key)

        return items.map { item in
            AuthenticatorBridgeItemDataModel(
                favorite: item.favorite,
                id: item.id,
                name: encrypt(item.name, withKey: symmetricKey) ?? "",
                totpKey: encrypt(item.totpKey, withKey: symmetricKey),
                username: encrypt(item.username, withKey: symmetricKey)
            )
        }
    }

    /// Decrypts a string given a key.
    ///
    /// - Parameters:
    ///   - string: The string to decrypt.
    ///   - key: The key to decrypt with.
    /// - Returns: A decrypted string, or `nil` if the passed-in string was not encoded in Base64.
    ///
    private func decrypt(_ string: String?, withKey key: SymmetricKey) throws -> String? {
        guard let string, !string.isEmpty, let data = Data(base64Encoded: string) else {
            return nil
        }
        let encryptedSealedBox = try AES.GCM.SealedBox(
            combined: data
        )
        let decryptedBox = try AES.GCM.open(
            encryptedSealedBox,
            using: key
        )
        return String(data: decryptedBox, encoding: .utf8)
    }

    /// Encrypt a string with the given key.
    ///
    /// - Parameters:
    ///   - plainText: The string to encrypt
    ///   - key: The key to use to encrypt the string
    /// - Returns: An encrypted string or `nil` if the string was nil
    ///
    private func encrypt(_ plainText: String?, withKey key: SymmetricKey) -> String? {
        guard let plainText else {
            return nil
        }

        let nonce = randomData(lengthInBytes: 12)

        let plainData = plainText.data(using: .utf8)
        let sealedData = try? AES.GCM.seal(plainData!, using: key, nonce: AES.GCM.Nonce(data: nonce))
        return sealedData?.combined?.base64EncodedString()
    }

    /// Generate random data of the length specified
    ///
    /// - Parameter lengthInBytes: the length of the random data to generate
    /// - Returns: random `Data` of the length in bytes requested.
    ///
    private func randomData(lengthInBytes: Int) -> Data {
        var data = Data(count: lengthInBytes)
        _ = data.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, lengthInBytes, bytes.baseAddress!)
        }
        return data
    }
}
