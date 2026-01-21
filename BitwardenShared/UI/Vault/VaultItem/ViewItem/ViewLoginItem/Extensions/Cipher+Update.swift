import BitwardenSdk
import Foundation

extension Cipher {
    /// Returns a copy of the existing cipher with an updated list of attachments
    ///
    /// - Parameters:
    ///   - attachments: The attachments owned by the cipher.
    ///   - revisionDate: The date of the cipher's last update.
    /// - Returns: A copy of the existing cipher, with the specified properties updated.
    ///
    func update(attachments: [Attachment], revisionDate: Date) -> Cipher {
        Cipher(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            key: key,
            name: name,
            notes: notes,
            type: type,
            login: login,
            identity: identity,
            card: card,
            secureNote: secureNote,
            sshKey: sshKey,
            favorite: favorite,
            reprompt: reprompt,
            organizationUseTotp: organizationUseTotp,
            edit: edit,
            permissions: permissions,
            viewPassword: viewPassword,
            localData: localData,
            attachments: attachments,
            fields: fields,
            passwordHistory: passwordHistory,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate,
            archivedDate: archivedDate,
            data: data,
        )
    }

    /// Returns a copy of the existing cipher with an updated folder ID.
    ///
    /// - Parameter folderId: The folder ID to update in the cipher.
    /// - Returns: A copy of the existing cipher, with the specified properties updated.
    ///
    func update(folderId: String?) -> Cipher {
        Cipher(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            key: key,
            name: name,
            notes: notes,
            type: type,
            login: login,
            identity: identity,
            card: card,
            secureNote: secureNote,
            sshKey: sshKey,
            favorite: favorite,
            reprompt: reprompt,
            organizationUseTotp: organizationUseTotp,
            edit: edit,
            permissions: permissions,
            viewPassword: viewPassword,
            localData: localData,
            attachments: attachments,
            fields: fields,
            passwordHistory: passwordHistory,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate,
            archivedDate: archivedDate,
            data: data,
        )
    }
}
