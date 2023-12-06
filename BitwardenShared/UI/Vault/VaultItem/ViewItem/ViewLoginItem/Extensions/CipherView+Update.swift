import BitwardenSdk

extension CipherView {
    func updatedView(with editState: AddEditItemState) -> CipherView {
        let properties = editState.properties
        return CipherView(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            name: properties.name,
            notes: properties.notes.nilIfEmpty,
            type: BitwardenSdk.CipherType(.login),
            login: .init(loginView: login, properties: properties),
            identity: identity,
            card: card,
            secureNote: secureNote,
            favorite: properties.isFavoriteOn,
            reprompt: properties.isMasterPasswordRePromptOn ? .password : .none,
            organizationUseTotp: false,
            edit: true,
            viewPassword: true,
            localData: localData,
            attachments: attachments,
            fields: fields,
            passwordHistory: passwordHistory,
            creationDate: creationDate,
            deletedDate: nil,
            revisionDate: revisionDate
        )
    }
}
