import Foundation

@testable import BitwardenShared

extension CipherDetailsResponseModel {
    static func fixture(
        attachments: [AttachmentResponseModel]? = nil,
        card: CipherCardModel? = nil,
        collectionIds: [String]? = nil,
        creationDate: Date,
        deletedDate: Date? = nil,
        edit: Bool = false,
        favorite: Bool = false,
        fields: [CipherFieldModel]? = nil,
        folderId: String? = nil,
        id: String? = nil,
        identity: CipherIdentityModel? = nil,
        login: CipherLoginModel? = nil,
        name: String? = nil,
        notes: String? = nil,
        object: String? = nil,
        organizationId: String? = nil,
        organizationUseTotp: Bool = false,
        passwordHistory: [CipherPasswordHistoryModel]? = nil,
        reprompt: CipherRepromptType? = nil,
        revisionDate: Date,
        secureNote: CipherSecureNoteModel? = nil,
        type: CipherType? = nil,
        viewPassword: Bool = false
    ) -> CipherDetailsResponseModel {
        self.init(
            attachments: attachments,
            card: card,
            collectionIds: collectionIds,
            creationDate: creationDate,
            deletedDate: deletedDate,
            edit: edit,
            favorite: favorite,
            fields: fields,
            folderId: folderId,
            id: id,
            identity: identity,
            login: login,
            name: name,
            notes: notes,
            object: object,
            organizationId: organizationId,
            organizationUseTotp: organizationUseTotp,
            passwordHistory: passwordHistory,
            reprompt: reprompt,
            revisionDate: revisionDate,
            secureNote: secureNote,
            type: type,
            viewPassword: viewPassword
        )
    }
}
