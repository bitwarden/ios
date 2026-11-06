import BitwardenSdk
import Foundation

// MARK: - CipherStorageService

// sourcery: AutoMockable
/// A service that locally persists the SDK-encrypted `Cipher`s created by the passkey
/// scenarios, so they survive app relaunches.
///
protocol CipherStorageService: AnyObject {
    /// Loads the persisted ciphers, if any.
    ///
    /// - Returns: The persisted ciphers, in the order they were saved. Empty if none are stored.
    ///
    func loadCiphers() -> [Cipher]

    /// Persists the given ciphers, replacing whatever was previously stored.
    ///
    /// - Parameter ciphers: The full list of ciphers to persist.
    ///
    func save(ciphers: [Cipher])
}

// MARK: - DefaultCipherStorageService

/// The default `CipherStorageService` implementation, backed by `UserDefaults`. This is safe
/// to store outside the keychain because every sensitive field is already SDK ciphertext —
/// useless without the synthetic identity's key, which is kept in the keychain (see
/// `SyntheticIdentity`).
///
final class DefaultCipherStorageService: CipherStorageService {
    // MARK: Private Properties

    /// The `UserDefaults` key under which the persisted ciphers are stored.
    private static let storageKey = "PasskeyStoredCiphers"

    /// The `UserDefaults` instance used for persistence.
    private let userDefaults: UserDefaults

    // MARK: Initialization

    /// Initializes a `DefaultCipherStorageService`.
    ///
    /// - Parameter userDefaults: The `UserDefaults` instance used for persistence.
    ///
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: Methods

    func loadCiphers() -> [Cipher] {
        guard let data = userDefaults.data(forKey: Self.storageKey),
              let storedCiphers = try? JSONDecoder().decode([StoredCipher].self, from: data) else {
            return []
        }
        return storedCiphers.map(\.cipher)
    }

    func save(ciphers: [Cipher]) {
        let storedCiphers = ciphers.compactMap(StoredCipher.init(cipher:))
        guard let data = try? JSONEncoder().encode(storedCiphers) else { return }
        userDefaults.set(data, forKey: Self.storageKey)
    }
}
