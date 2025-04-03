import Foundation
import Networking

/// API response model for a user's cipher.
///
struct CipherDetailsResponseModel: JSONResponse, Equatable {
    // MARK: Properties

    /// The cipher's list of attachments.
    let attachments: [AttachmentResponseModel]?

    /// Card data if the cipher is a card.
    let card: CipherCardModel?

    /// The identifiers for collections which contain this cipher.
    var collectionIds: [String]?

    /// The date the cipher was created.
    let creationDate: Date

    /// The date the cipher was deleted.
    let deletedDate: Date?

    /// Whether the cipher can be edited.
    let edit: Bool

    /// Whether the cipher is a favorite.
    let favorite: Bool

    /// The cipher's list of user-defined fields.
    let fields: [CipherFieldModel]?

    /// The folder identifier.
    let folderId: String?

    /// A identifier for the cipher.
    let id: String

    /// Identity data if the cipher is a identity.
    let identity: CipherIdentityModel?

    /// A key used to decrypt the cipher.
    let key: String?

    /// Login data if the cipher is a login.
    let login: CipherLoginModel?

    /// The name of the cipher.
    let name: String

    /// Notes containing within the cipher.
    let notes: String?

    /// The organization identifier for the cipher.
    let organizationId: String?

    /// Whether the organization for the cipher supports TOTP.
    let organizationUseTotp: Bool

    /// The password history for this cipher.
    let passwordHistory: [CipherPasswordHistoryModel]?

    /// The permissions of the cipher.
    let permissions: CipherPermissionsModel?

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

    /// Whether the password can be viewed.
    let viewPassword: Bool
}
