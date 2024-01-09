import BitwardenSdk
import Foundation

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

    /// Returns a TOTP Code for a key.
    ///
    ///  - Parameters:
    ///    - key: The key used to generate the code.
    ///    - date: The date used to generate the code
    ///  - Returns: A TOTPCode model.
    ///
    func generateTOTPCode(for key: String, date: Date?) async throws -> TOTPCode

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

    func generateTOTPCode(for key: String, date: Date? = nil) async throws -> TOTPCode {
        let calculationDate: Date = date ?? Date()
        let response = try await generateTotp(key: key, time: calculationDate)
        return TOTPCode(code: response.code, date: calculationDate, period: response.period)
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
