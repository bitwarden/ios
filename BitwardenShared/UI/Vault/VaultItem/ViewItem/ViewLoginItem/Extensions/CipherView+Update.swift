import BitwardenSdk

extension CipherView {
    // MARK: Properties

    /// A coputed array of `CustomFieldState`, representing the custom fields of the cipher.
    ///
    var customFields: [CustomFieldState] {
        fields?.map(CustomFieldState.init) ?? []
    }

    // MARK: Methods

    /// Creates a `CardItemState` representation of the cipher.
    ///
    /// This function converts the `card` information of the cipher into a `CardItemState`, which
    /// is used to manage and display card data in the UI.
    ///
    /// - Returns: A `CardItemState` representing the card information of the cipher.
    ///
    func cardItemState() -> CardItemState {
        guard let card else { return CardItemState() }
        return CardItemState(
            brand: {
                var result: DefaultableType<CardComponent.Brand> = .default
                guard let brand = card.brand,
                      let value = CardComponent.Brand(rawValue: brand) else {
                    return result
                }
                result = .custom(value)
                return result
            }(),
            cardholderName: card.cardholderName ?? "",
            cardNumber: card.number ?? "",
            cardSecurityCode: card.code ?? "",
            expirationMonth: {
                var result: DefaultableType<CardComponent.Month> = .default
                guard let month = card.expMonth,
                      let intMonth = Int(month),
                      let value = CardComponent.Month(rawValue: intMonth) else {
                    return result
                }
                result = .custom(value)
                return result
            }(),
            expirationYear: card.expYear ?? ""
        )
    }

    /// Creates an `IdentityItemState` representation of the cipher.
    ///
    /// This function converts the `identity` information of the cipher into an `IdentityItemState`,
    /// which is used to manage and display identity data in the UI.
    ///
    /// - Returns: An `IdentityItemState` representing the identity information of the cipher.
    ///
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

    /// Creates a `LoginItemState` representation of the cipher.
    ///
    /// This function converts the login-related information of the cipher into a `LoginItemState`,
    /// which is used to manage and display login data in the UI.
    ///
    /// - Parameter showPassword: A Boolean value indicating whether the password should be visible.
    /// - Returns: A `LoginItemState` representing the login information of the cipher.
    ///
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

    /// Updates the cipher view with the state information from `AddEditItemState`.
    ///
    /// - Parameter addEditState: The `AddEditItemState` containing the updated state information.
    /// - Returns: An updated `CipherView` reflecting the changes from the `AddEditItemState`.
    ///
    func updatedView(with addEditState: AddEditItemState) -> CipherView {
        CipherView(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            key: addEditState.configuration.existingCipherView?.key,
            name: addEditState.name,
            notes: addEditState.notes.nilIfEmpty,
            type: BitwardenSdk.CipherType(addEditState.type),
            login: (addEditState.type == .login) ? .init(loginView: login, loginState: addEditState.loginState) : nil,
            identity: (addEditState.type == .identity) ? addEditState.identityState.identityView : nil,
            card: (addEditState.type == .card) ? addEditState.cardItemState.cardView : nil,
            secureNote: (addEditState.type == .secureNote) ? secureNote : nil,
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
