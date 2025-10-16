import BitwardenSdk
import Foundation

/// A protocol for a service that handles encryption and decryption tasks for the vault. This is
/// similar to `VaultClientProtocol` but returns the protocols so they can be mocked for testing.
///
protocol VaultClientService: AnyObject {
    /// Returns an object that handles encryption and decryption for attachments.
    ///
    func attachments() -> AttachmentsClientProtocol

    /// Returns an object that handles encryption and decryption for ciphers.
    ///
    func ciphers() -> CiphersClientProtocol

    /// Returns an object that handles encryption and decryption for collections.
    ///
    func collections() -> CollectionsClientProtocol

    /// Returns an object that handles encryption and decryption for folders.
    ///
    func folders() -> FoldersClientProtocol

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
    func passwordHistory() -> PasswordHistoryClientProtocol
}

// MARK: - VaultClient

extension VaultClient: VaultClientService {
    func attachments() -> AttachmentsClientProtocol {
        attachments() as AttachmentsClient
    }

    func ciphers() -> CiphersClientProtocol {
        ciphers() as CiphersClient
    }

    func collections() -> CollectionsClientProtocol {
        collections() as CollectionsClient
    }

    func folders() -> FoldersClientProtocol {
        folders() as FoldersClient
    }

    func generateTOTPCode(for key: String, date: Date? = nil) throws -> TOTPCodeModel {
        let calculationDate: Date = date ?? Date()
        let response = try generateTotp(key: key, time: calculationDate)
        return TOTPCodeModel(
            code: response.code,
            codeGenerationDate: calculationDate,
            period: response.period,
        )
    }

    func passwordHistory() -> PasswordHistoryClientProtocol {
        passwordHistory() as PasswordHistoryClient
    }
}
