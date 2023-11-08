// swiftlint:disable:this file_name

import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension Cipher {
    static func fixture(
        attachments: [Attachment]? = nil,
        card: Card? = nil,
        collectionIds: [String] = [],
        creationDate: DateTime = Date(),
        deletedDate: Date? = nil,
        edit: Bool = true,
        favorite: Bool = false,
        fields: [Field]? = nil,
        folderId: String? = nil,
        id: String? = nil,
        identity: Identity? = nil,
        localData: LocalData? = nil,
        login: BitwardenSdk.Login? = nil,
        name: String = "Bitwarden",
        notes: String? = nil,
        organizationId: String? = nil,
        organizationUseTotp: Bool = false,
        passwordHistory: [PasswordHistory]? = nil,
        reprompt: BitwardenSdk.CipherRepromptType = .none,
        revisionDate: Date = Date(),
        secureNote: SecureNote? = nil,
        type: BitwardenSdk.CipherType = .login,
        viewPassword: Bool = true
    ) -> Cipher {
        Cipher(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            name: name,
            notes: notes,
            type: type,
            login: login,
            identity: identity,
            card: card,
            secureNote: secureNote,
            favorite: favorite,
            reprompt: reprompt,
            organizationUseTotp: organizationUseTotp,
            edit: edit,
            viewPassword: viewPassword,
            localData: localData,
            attachments: attachments,
            fields: fields,
            passwordHistory: passwordHistory,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate
        )
    }
}

extension CipherView {
    static func fixture(
        attachments: [AttachmentView]? = nil,
        card: CardView? = nil,
        collectionIds: [String] = [],
        creationDate: DateTime = Date(),
        deletedDate: Date? = nil,
        edit: Bool = true,
        favorite: Bool = false,
        fields: [FieldView]? = nil,
        folderId: String? = nil,
        id: String? = nil,
        identity: IdentityView? = nil,
        localData: LocalDataView? = nil,
        login: BitwardenSdk.LoginView? = nil,
        name: String = "Bitwarden",
        notes: String? = nil,
        organizationId: String? = nil,
        organizationUseTotp: Bool = false,
        passwordHistory: [PasswordHistoryView]? = nil,
        reprompt: BitwardenSdk.CipherRepromptType = .none,
        revisionDate: Date = Date(),
        secureNote: SecureNoteView? = nil,
        type: BitwardenSdk.CipherType = .login,
        viewPassword: Bool = true
    ) -> CipherView {
        CipherView(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            name: name,
            notes: notes,
            type: type,
            login: login,
            identity: identity,
            card: card,
            secureNote: secureNote,
            favorite: favorite,
            reprompt: reprompt,
            organizationUseTotp: organizationUseTotp,
            edit: edit,
            viewPassword: viewPassword,
            localData: localData,
            attachments: attachments,
            fields: fields,
            passwordHistory: passwordHistory,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate
        )
    }
}
