import BitwardenKit
import Foundation
import Networking

/// API response model for a minimal cipher representation.
///
/// This is a lighter version of `CipherDetailsResponseModel` used in bulk operations
/// like sharing multiple ciphers.
///
struct CipherMiniResponseModel: JSONResponse, Equatable {
    // MARK: Properties

    /// The date the cipher was archived.
    let archivedDate: Date?

    /// The cipher's list of attachments.
    let attachments: [AttachmentResponseModel]?

    /// Bank account data if the cipher is a bank account.
    let bankAccount: CipherBankAccountModel?

    /// Card data if the cipher is a card.
    let card: CipherCardModel?

    /// The date the cipher was created.
    let creationDate: Date

    /// The cipher's encrypted data blob.
    ///
    /// - Note: For blob-encrypted ciphers, this contains the full sealed payload and the
    ///   legacy per-type fields (`login`, `card`, `name`, etc.) are `nil`.
    let data: String?

    /// The date the cipher was deleted.
    let deletedDate: Date?

    /// Driver's license data if the cipher is a driver's license.
    let driversLicense: CipherDriversLicenseModel?

    /// The cipher's list of user-defined fields.
    let fields: [CipherFieldModel]?

    /// A identifier for the cipher.
    let id: String

    /// Identity data if the cipher is an identity.
    let identity: CipherIdentityModel?

    /// A key used to decrypt the cipher.
    let key: String?

    /// Login data if the cipher is a login.
    let login: CipherLoginModel?

    /// The name of the cipher.
    ///
    /// - Note: `nil` for blob-encrypted ciphers, where the name lives inside the sealed `data`
    ///   blob; present on the legacy field-level format.
    let name: String?

    /// Notes contained within the cipher.
    let notes: String?

    /// The organization identifier for the cipher.
    let organizationId: String?

    /// Whether the organization for the cipher supports TOTP.
    let organizationUseTotp: Bool

    /// Passport data if the cipher is a passport.
    let passport: CipherPassportModel?

    /// The password history for this cipher.
    let passwordHistory: [CipherPasswordHistoryModel]?

    /// Whether the user needs to be re-prompted for their master password prior to autofilling the
    /// cipher's password.
    @DefaultValue var reprompt: CipherRepromptType

    /// The date the cipher was last updated.
    let revisionDate: Date

    /// Secure note data if the cipher is a secure note.
    let secureNote: CipherSecureNoteModel?

    /// SSH key if the `type` is `.sshKey`.
    let sshKey: CipherSSHKeyModel?

    /// The type of the cipher.
    let type: CipherType
}
