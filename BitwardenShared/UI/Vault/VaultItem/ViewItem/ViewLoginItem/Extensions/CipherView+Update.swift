import BitwardenSdk

extension CipherView {
    var customFields: [CustomFieldState] {
        fields?.map(CustomFieldState.init) ?? []
    }

    func identityItemState() -> IdentityItemState {
        var title: DefaultableType<TitleType> = .default
        if let titleStr = identity?.title, let titleType = TitleType(rawValue: titleStr) {
            title = .custom(titleType)
        }

        return .init(
            title: title,
            firstName: identity?.firstName ?? "",
            lastName: identity?.lastName ?? "",
            middleName: identity?.middleName ?? "",
            userName: identity?.username ?? "",
            company: identity?.company ?? "",
            socialSecurityNumber: identity?.ssn ?? "",
            passportNumber: identity?.passportNumber ?? "",
            licenseNumber: identity?.licenseNumber ?? "",
            email: identity?.email ?? "",
            phone: identity?.phone ?? "",
            address1: identity?.address1 ?? "",
            address2: identity?.address2 ?? "",
            address3: identity?.address3 ?? "",
            cityOrTown: identity?.city ?? "",
            state: identity?.state ?? "",
            postalCode: identity?.postalCode ?? "",
            country: identity?.country ?? ""
        )
    }

    func loginItemState(showPassword: Bool = false) -> LoginItemState {
        .init(
            canViewPassword: viewPassword,
            isPasswordVisible: showPassword,
            password: login?.password ?? "",
            passwordUpdatedDate: login?.passwordRevisionDate,
            totpKey: .init(authenticatorKey: login?.totp ?? ""),
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
