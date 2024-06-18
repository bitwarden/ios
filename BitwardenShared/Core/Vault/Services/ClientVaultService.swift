import BitwardenSdk
import Foundation

/// A protocol for a service that handles encryption and decryption tasks for the vault. This is
/// similar to `ClientVaultProtocol` but returns the protocols so they can be mocked for testing.
///
protocol ClientVaultService: AnyObject {
    /// Returns an object that handles encryption and decryption for attachments.
    ///
    func attachments() -> ClientAttachmentsProtocol

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
    ///  - Returns: A TOTPCodeState model.
    ///
    func generateTOTPCode(for key: String, date: Date?) throws -> TOTPCodeModel

    /// Returns an object that handles encryption and decryption for password history.
    ///
    func passwordHistory() -> ClientPasswordHistoryProtocol
}

// MARK: - ClientVault

extension ClientVault: ClientVaultService {
    func attachments() -> ClientAttachmentsProtocol {
        attachments() as ClientAttachments
    }

    func ciphers() -> ClientCiphersProtocol {
        ciphers() as ClientCiphers
    }

    func collections() -> ClientCollectionsProtocol {
        collections() as ClientCollections
    }

    func folders() -> ClientFoldersProtocol {
        folders() as ClientFolders
    }

    func generateTOTPCode(for key: String, date: Date? = nil) throws -> TOTPCodeModel {
        let calculationDate: Date = date ?? Date()
        let response = try generateTotp(key: key, time: calculationDate)
        return TOTPCodeModel(
            code: response.code,
            codeGenerationDate: calculationDate,
            period: response.period
        )
    }

    func passwordHistory() -> ClientPasswordHistoryProtocol {
        passwordHistory() as ClientPasswordHistory
    }
}
