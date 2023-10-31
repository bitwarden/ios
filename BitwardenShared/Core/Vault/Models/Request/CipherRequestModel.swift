import BitwardenSdk
import Foundation
import Networking

/// API request model for adding or updating a cipher.
///
struct CipherRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The cipher's attachment data.
    ///
    /// Note: `attachments2` is the newer version of the `attachment` API property for sending
    /// attachment data.
    let attachments2: [String: AttachmentRequestModel]?

    /// Card data if the cipher is a card.
    let card: CipherCardModel?

    /// Whether the cipher is a favorite.
    let favorite: Bool

    /// The cipher's list of user-defined fields.
    let fields: [CipherFieldModel]?

    /// The folder identifier.
    let folderId: String?

    /// Identity data if the cipher is a identity.
    let identity: CipherIdentityModel?

    /// The date the cipher was last updated.
    let lastKnownRevisionDate: Date

    /// Login data if the cipher is a login.
    let login: CipherLoginModel?

    /// The name of the cipher.
    let name: String

    /// Notes contained within the cipher.
    let notes: String?

    /// The organization identifier for the cipher.
    let organizationID: String?

    /// The password history for this cipher.
    let passwordHistory: [CipherPasswordHistoryModel]?

    /// Whether the user needs to be re-prompted for their master password prior to autofilling the
    /// cipher's password.
    let reprompt: CipherRepromptType

    /// Secure note data if the cipher is a secure note.
    let secureNote: CipherSecureNoteModel?

    /// The type of the cipher.
    let type: CipherType
}

extension CipherRequestModel {
    /// Initialize a `CipherRequestModel` from a `Cipher`.
    ///
    /// - Parameter cipher: The `Cipher` used to initialize a `CipherRequestModel`.
    ///
    init(cipher: Cipher) {
        self.init(
            attachments2: cipher.attachments?.reduce(into: [String: AttachmentRequestModel]()) { result, attachment in
                guard let id = attachment.id else { return }
                result[id] = AttachmentRequestModel(attachment: attachment)
            },
            card: cipher.card.map(CipherCardModel.init),
            favorite: cipher.favorite,
            fields: cipher.fields?.map(CipherFieldModel.init),
            folderId: cipher.folderId,
            identity: cipher.identity.map(CipherIdentityModel.init),
            lastKnownRevisionDate: cipher.revisionDate,
            login: cipher.login.map(CipherLoginModel.init),
            name: cipher.name,
            notes: cipher.notes,
            organizationID: cipher.organizationId,
            passwordHistory: cipher.passwordHistory?.map(CipherPasswordHistoryModel.init),
            reprompt: CipherRepromptType(type: cipher.reprompt),
            secureNote: cipher.secureNote.map(CipherSecureNoteModel.init),
            type: CipherType(type: cipher.type)
        )
    }
}
