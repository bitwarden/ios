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
            uris: login?.uris?.map { uriView in
                CipherLoginUriModel(loginUriView: uriView)
            } ?? [],
            username: login?.username ?? ""
        )
    }

    func updatedView(with editState: CipherItemState) -> CipherView {
        CipherView(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            key: editState.configuration.existingCipherView?.key,
            name: editState.name,
            notes: editState.notes.nilIfEmpty,
            type: BitwardenSdk.CipherType(.login),
            login: .init(loginView: login, loginState: editState.loginState),
            identity: identity,
            card: card,
            secureNote: secureNote,
            favorite: editState.isFavoriteOn,
            reprompt: editState.isMasterPasswordRePromptOn ? .password : .none,
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
