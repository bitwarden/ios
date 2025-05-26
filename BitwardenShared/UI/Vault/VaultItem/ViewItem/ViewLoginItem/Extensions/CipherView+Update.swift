import BitwardenKit
import BitwardenSdk
import Foundation

extension CipherView {
    // MARK: Properties

    /// A computed array of `CustomFieldState`, representing the custom fields of the cipher.
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
    /// - Parameters:
    ///   - excludeFido2Credentials: Whether to exclude copying any FIDO2 credentials from the login item.
    ///   - isTOTPCodeVisible: Whether the TOTP code is visible.
    ///   - showPassword: A Boolean value indicating whether the password should be visible.
    ///   - showTOTP: A Boolean value indicating whether TOTP should be visible.
    ///
    /// - Returns: A `LoginItemState` representing the login information of the cipher.
    ///
    func loginItemState(
        excludeFido2Credentials: Bool = false,
        isTOTPCodeVisible: Bool = false,
        showPassword: Bool = false,
        showTOTP: Bool
    ) -> LoginItemState {
        LoginItemState(
            canViewPassword: viewPassword,
            editView: edit,
            fido2Credentials: excludeFido2Credentials ? [] : login?.fido2Credentials ?? [],
            isPasswordVisible: showPassword,
            isTOTPAvailable: showTOTP,
            isTOTPCodeVisible: isTOTPCodeVisible,
            password: login?.password ?? "",
            passwordHistoryCount: passwordHistory?.count,
            passwordUpdatedDate: login?.passwordRevisionDate,
            totpState: .init(login?.totp),
            uris: login?.uris?.map(UriState.init) ?? [],
            username: login?.username ?? ""
        )
    }

    /// Creates an `SSHKeyItemState` representation of the cipher.
    ///
    /// This function converts the `sshKey` information of the cipher into an `SSHKeyItemState`,
    /// which is used to manage and display SSH key data in the UI.
    ///
    /// - Returns: An `SSHKeyItemState` representing the SSH key information of the cipher.
    ///
    func sshKeyItemState() -> SSHKeyItemState {
        guard let sshKey else { return .init() }
        return SSHKeyItemState(
            canViewPrivateKey: viewPassword,
            isPrivateKeyVisible: false,
            privateKey: sshKey.privateKey,
            publicKey: sshKey.publicKey,
            keyFingerprint: sshKey.fingerprint
        )
    }

    /// Updates the cipher view with the state information from `AddEditItemState`.
    /// - Parameters:
    ///   - addEditState: The `AddEditItemState` containing the updated state information.
    ///   - timeProvider: The `TimeProvider` to use to get current time.
    /// - Returns: An updated `CipherView` reflecting the changes from the `AddEditItemState`.
    func updatedView(with addEditState: AddEditItemState, timeProvider: TimeProvider = CurrentTime()) -> CipherView {
        var loginState = addEditState.loginState

        // Update the password updated date and the password history if the password has changed.
        var passwordHistory = passwordHistory
        let lastUsedDate = timeProvider.presentTime
        if addEditState.type == .login,
           let previousPassword = login?.password,
           addEditState.loginState.password != previousPassword {
            loginState.passwordUpdatedDate = lastUsedDate

            // Update the password history list.
            let newPasswordHistoryView = PasswordHistoryView(password: previousPassword, lastUsedDate: lastUsedDate)
            if passwordHistory == nil {
                passwordHistory = [newPasswordHistoryView]
            } else {
                passwordHistory!.append(newPasswordHistoryView)
            }
        }

        // Map new fields
        let newFields = mapToCustomFieldViews(from: addEditState.customFieldsState.customFields)

        passwordHistory = updatePasswordHistoryWithHiddenFields(
            passwordHistory: passwordHistory,
            oldFields: fields,
            newFields: newFields,
            lastUsedDate: lastUsedDate
        )

        // Cap the size of the password history list to 5.
        passwordHistory = passwordHistory?.suffix(5)

        // Return the updated cipher.
        return CipherView(
            id: id,
            organizationId: organizationId,
            folderId: addEditState.folderId,
            collectionIds: collectionIds,
            key: key,
            name: addEditState.name,
            notes: addEditState.notes.nilIfEmpty,
            type: BitwardenSdk.CipherType(addEditState.type),
            login: (addEditState.type == .login) ? .init(loginView: login, loginState: loginState) : nil,
            identity: (addEditState.type == .identity) ? addEditState.identityState.identityView : nil,
            card: (addEditState.type == .card) ? addEditState.cardItemState.cardView : nil,
            secureNote: (addEditState.type == .secureNote) ? secureNote : nil,
            sshKey: (addEditState.type == .sshKey) ? sshKey : nil,
            favorite: addEditState.isFavoriteOn,
            reprompt: addEditState.isMasterPasswordRePromptOn ? .password : .none,
            organizationUseTotp: organizationUseTotp,
            edit: edit,
            permissions: permissions,
            viewPassword: viewPassword,
            localData: localData,
            attachments: attachments,
            fields: newFields,
            passwordHistory: passwordHistory,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate
        )
    }

    private func updatePasswordHistoryWithHiddenFields(
        passwordHistory: [PasswordHistoryView]?,
        oldFields: [FieldView]?,
        newFields: [FieldView]?,
        lastUsedDate: Date
    ) -> [PasswordHistoryView]? {
        guard let oldFields else {
            return passwordHistory
        }
        let newPasswordHistoryFields: [PasswordHistoryView] = oldFields
            .filter { field in
                FieldType(fieldType: field.type) == FieldType.hidden &&
                    !field.name.isEmptyOrNil &&
                    !field.value.isEmptyOrNil &&
                    !(newFields?.contains(field) ?? false)
            }.compactMap { hiddenField in
                PasswordHistoryView(
                    password: "\(hiddenField.name ?? ""): \(hiddenField.value ?? "")",
                    lastUsedDate: lastUsedDate
                )
            }
        guard !newPasswordHistoryFields.isEmpty else {
            return passwordHistory
        }
        guard let passwordHistory else {
            return newPasswordHistoryFields
        }
        return passwordHistory + newPasswordHistoryFields
    }

    /// Maps the array of `CustomFieldState` into the an array of `FieldView`.
    private func mapToCustomFieldViews(from customFields: [CustomFieldState]) -> [FieldView]? {
        guard !customFields.isEmpty else {
            return nil
        }

        return customFields.map { FieldView(customFieldState: $0) }
    }
}

extension CipherView {
    /// Returns a copy of the existing cipher with an updated list of collection IDs.
    ///
    /// - Parameter collectionIds: The identifiers of any collections containing the cipher.
    /// - Returns: A copy of the existing cipher, with the specified properties updated.
    ///
    func update(collectionIds: [String]) -> CipherView {
        update(
            collectionIds: collectionIds,
            deletedDate: deletedDate,
            folderId: folderId,
            login: login,
            organizationId: organizationId
        )
    }

    /// Returns a copy of the existing cipher with an updated deleted date.
    ///
    /// - Parameter deletedDate: The deleted date of the cipher.
    /// - Returns: A copy of the existing cipher, with the specified properties updated.
    ///
    func update(deletedDate: Date?) -> CipherView {
        update(
            collectionIds: collectionIds,
            deletedDate: deletedDate,
            folderId: folderId,
            login: login,
            organizationId: organizationId
        )
    }

    /// Returns a copy of the existing cipher with an updated folder id.
    ///
    /// - Parameter folderId: The id of the folder this cipher belongs to.
    /// - Returns: A copy of the existing cipher, with the specified properties updated.
    ///
    func update(folderId: String?) -> CipherView {
        update(
            collectionIds: collectionIds,
            deletedDate: deletedDate,
            folderId: folderId,
            login: login,
            organizationId: organizationId
        )
    }

    /// Returns a copy of the existing cipher with updated login properties.
    ///
    /// - Parameter login: The login property to update.
    /// - Returns: A copy of the existing cipher, with the login property updated.
    ///
    func update(login: BitwardenSdk.LoginView) -> CipherView {
        update(
            collectionIds: collectionIds,
            deletedDate: deletedDate,
            folderId: folderId,
            login: login,
            organizationId: organizationId
        )
    }

    // MARK: Private

    /// Returns a copy of the existing cipher, updating any of the specified properties.
    ///
    /// - Parameters:
    ///   - collectionIds: The identifiers of any collections containing the cipher.
    ///   - deletedDate: The deleted date of the cipher.
    ///   - folderId: The identifier of the cipher's folder
    ///   - login: Login data if the cipher is a login.
    ///   - organizationId: The identifier of the cipher's organization.
    /// - Returns: A copy of the existing cipher, with the specified properties updated.
    ///
    private func update(
        collectionIds: [String],
        deletedDate: Date?,
        folderId: String?,
        login: BitwardenSdk.LoginView?,
        organizationId: String?
    ) -> CipherView {
        CipherView(
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
            revisionDate: revisionDate
        )
    }
}

extension BitwardenSdk.LoginView {
    /// Returns a copy of the existing login with an updated TOTP key.
    ///
    /// - Parameter totp: The TOTP key to update.
    /// - Returns: A copy of the existing login, with the specified properties updated.
    ///
    func update(totp: String?) -> BitwardenSdk.LoginView {
        BitwardenSdk.LoginView(
            username: username,
            password: password,
            passwordRevisionDate: passwordRevisionDate,
            uris: uris,
            totp: totp,
            autofillOnPageLoad: autofillOnPageLoad,
            fido2Credentials: fido2Credentials
        )
    }
}
