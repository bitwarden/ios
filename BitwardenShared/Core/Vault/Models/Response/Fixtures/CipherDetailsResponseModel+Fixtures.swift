import Foundation

@testable import BitwardenShared

extension CipherDetailsResponseModel {
    static func fixture(
        attachments: [AttachmentResponseModel]? = nil,
        card: CipherCardModel? = nil,
        collectionIds: [String] = [],
        creationDate: Date = Date(),
        deletedDate: Date? = nil,
        edit: Bool = false,
        favorite: Bool = false,
        fields: [CipherFieldModel]? = nil,
        folderId: String? = nil,
        id: String = UUID().uuidString,
        identity: CipherIdentityModel? = nil,
        key: String? = nil,
        login: CipherLoginModel? = nil,
        name: String = "Test Cipher",
        notes: String? = nil,
        organizationId: String? = nil,
        organizationUseTotp: Bool = false,
        passwordHistory: [CipherPasswordHistoryModel]? = nil,
        reprompt: CipherRepromptType = .none,
        revisionDate: Date = Date(),
        secureNote: CipherSecureNoteModel? = nil,
        type: CipherType = .login,
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
            key: key,
            login: login,
            name: name,
            notes: notes,
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
