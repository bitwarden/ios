import BitwardenSdk

/// A protocol for a service that handles encryption and decryption tasks for the vault. This is
/// similar to `ClientVaultProtocol` but returns the protocols so they can be mocked for testing.
///
protocol ClientVaultService: AnyObject {
    /// Returns an object that handles encryption and decryption for ciphers.
    ///
    func ciphers() -> ClientCiphersProtocol

    /// Returns an object that handles encryption and decryption for collections.
    ///
    func collections() -> ClientCollectionsProtocol

    /// Returns an object that handles encryption and decryption for folders.
    ///
    func folders() -> ClientFoldersProtocol

    /// Returns an object that handles encryption and decryption for password history.
    ///
    func passwordHistory() -> ClientPasswordHistoryProtocol

    /// Returns an object that handles encryption and decryption for sends.
    ///
    func sends() -> ClientSendsProtocol
}

// MARK: - ClientVault

extension ClientVault: ClientVaultService {
    func collections() -> ClientCollectionsProtocol {
        collections() as ClientCollections
    }

    func folders() -> ClientFoldersProtocol {
        folders() as ClientFolders
    }

    func passwordHistory() -> ClientPasswordHistoryProtocol {
        passwordHistory() as ClientPasswordHistory
    }

    func sends() -> ClientSendsProtocol {
        sends() as ClientSends
    }

    func ciphers() -> ClientCiphersProtocol {
        ciphers() as ClientCiphers
    }
}
