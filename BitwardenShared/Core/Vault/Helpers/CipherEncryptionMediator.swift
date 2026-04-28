import BitwardenSdk

/// A mediator that helps with some cipher operations involving encryption.
protocol CipherEncryptionMediator { // sourcery: AutoMockable
    /// Encrypts the cipher. If the cipher was migrated by the SDK (e.g. added a cipher key), the
    /// cipher will be updated locally and on the server.
    ///
    /// - Parameter cipherView: The cipher to encrypt.
    /// - Returns: The encrypted cipher.
    ///
    func encryptAndUpdateCipher(_ cipherView: CipherView) async throws -> Cipher

    /// Sets the delegate to use.
    /// - Parameter delegate: The delegate to use.
    func setDelegate(_ delegate: CipherEncryptionMediatorDelegate)

    /// Checks if `cipherView` lacks a cipher key and if so tries to update it with the server
    /// returning the updated version.
    ///
    /// - Parameter cipherView: The cipher to check and update.
    /// - Returns: The updated cipher with the key if the operation has been done,
    /// otherwise the original cipher is returned.
    /// - Remark: Use this instead of `encryptAndUpdateCipher` when you need to keep updating a cipher view after
    /// this is run; e.g. archiving. This will only fetch the cipher again if the cipher key has been updated.
    func updateCipherKeyIfNeeded(_ cipherView: CipherView) async throws -> CipherView
}

/// A delegate to be used by the `CipherEncryptionMediator`.
protocol CipherEncryptionMediatorDelegate: AnyObject { // sourcery: AutoMockable
    /// Attempt to fetch a cipher with the given id.
    ///
    /// - Parameter id: The id of the cipher to find.
    /// - Returns: The cipher if it was found and `nil` if not.
    ///
    func fetchCipher(withId id: String) async throws -> CipherView?
}

/// Default implementation of `CipherEncryptionMediator`.
class DefaultCipherEncryptionMediator: CipherEncryptionMediator {
    // MARK: Properties

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The delegate to be used by the `CipherEncryptionMediator`.
    private weak var delegate: CipherEncryptionMediatorDelegate?

    /// Initializes a `DefaultCipherEncryptionMediator`.
    /// - Parameters:
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    init(cipherService: CipherService, clientService: ClientService) {
        self.cipherService = cipherService
        self.clientService = clientService
    }

    // MARK: Methods

    func encryptAndUpdateCipher(_ cipherView: CipherView) async throws -> Cipher {
        let cipherEncryptionContext = try await clientService.vault().ciphers().encrypt(cipherView: cipherView)

        let didAddCipherKey = cipherView.key == nil && cipherEncryptionContext.cipher.key != nil
        if didAddCipherKey {
            try await cipherService.updateCipherWithServer(
                cipherEncryptionContext.cipher,
                encryptedFor: cipherEncryptionContext.encryptedFor,
            )
        }

        return cipherEncryptionContext.cipher
    }

    func setDelegate(_ delegate: CipherEncryptionMediatorDelegate) {
        self.delegate = delegate
    }

    func updateCipherKeyIfNeeded(_ cipherView: CipherView) async throws -> CipherView {
        guard let cipherId = cipherView.id, cipherView.key == nil else {
            return cipherView
        }

        let cipherEncryptionContext = try await clientService.vault().ciphers().encrypt(cipherView: cipherView)
        guard cipherEncryptionContext.cipher.key != nil else {
            return cipherView
        }

        try await cipherService.updateCipherWithServer(
            cipherEncryptionContext.cipher,
            encryptedFor: cipherEncryptionContext.encryptedFor,
        )

        guard let updatedCipherView = try await delegate?.fetchCipher(withId: cipherId) else {
            return cipherView
        }

        return updatedCipherView
    }
}
