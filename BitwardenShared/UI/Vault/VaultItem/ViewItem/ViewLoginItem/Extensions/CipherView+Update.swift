import BitwardenSdk

extension CipherView {
    var customFields: [CustomFieldState] {
        fields?.map(CustomFieldState.init) ?? []
    }

    func loginItemState(showPassword: Bool = false) -> LoginItemState {
        .init(
            isPasswordVisible: showPassword,
            password: login?.password ?? "",
            passwordUpdatedDate: login?.passwordRevisionDate,
            uris: login?.uris?.map(UriState.init) ?? [],
            username: login?.username ?? ""
        )
    }

    func updatedView(with addEditState: AddEditItemState) -> CipherView {
        CipherView(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            key: addEditState.configuration.existingCipherView?.key,
            name: addEditState.name,
            notes: addEditState.notes.nilIfEmpty,
            type: type,
            login: .init(loginView: login, loginState: addEditState.loginState),
            identity: identity,
            card: card,
            secureNote: secureNote,
            favorite: addEditState.isFavoriteOn,
            reprompt: addEditState.isMasterPasswordRePromptOn ? .password : .none,
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
