import BitwardenResources
import BitwardenSdk

extension CipherListView {
    /// Determines whether the cipher can be used in basic password autofill operations.
    ///
    /// A cipher qualifies for basic login autofill if it's a login type and contains at least one
    /// of the following copyable fields: username, password, or TOTP code.
    ///
    /// - Returns: `true` if the cipher can be used for basic password autofill, `false` otherwise.
    var canBeUsedInBasicLoginAutofill: Bool {
        type.isLogin && copyableFields.contains { copyableField in
            switch copyableField {
            case .loginPassword, .loginTotp, .loginUsername:
                true
            default:
                false
            }
        }
    }

    /// Whether the cipher passes the `.restrictItemTypes` policy based on the organizations restricted.
    ///
    /// - Parameters:
    ///  - cipher: The cipher to check against the policy.
    ///  - restrictItemTypesOrgIds: The list of organization IDs that are restricted by the policy.
    ///  - Returns: `true` if the cipher is allowed by the policy, `false` otherwise.
    ///
    func passesRestrictItemTypesPolicy(_ restrictItemTypesOrgIds: [String]) -> Bool {
        guard !restrictItemTypesOrgIds.isEmpty, type.isCard else {
            return true
        }
        guard let orgId = organizationId, !orgId.isEmpty else {
            return false
        }
        return !restrictItemTypesOrgIds.contains(orgId)
    }
}

extension CipherListView {
    var isDecryptionFailure: Bool {
        name == Localizations.errorCannotDecrypt
    }

    init(cipherDecryptFailure cipher: Cipher) {
        let type: CipherListViewType = switch cipher.type {
        case .card:
            .card(CardListView(brand: nil))
        case .identity:
            .identity
        case .login:
            .login(
                LoginListView(
                    fido2Credentials: nil,
                    hasFido2: cipher.login?.fido2Credentials != nil,
                    username: nil,
                    totp: nil,
                    uris: nil,
                ),
            )
        case .secureNote:
            .secureNote
        case .sshKey:
            .sshKey
        }

        self.init(
            id: cipher.id,
            organizationId: cipher.organizationId,
            folderId: cipher.folderId,
            collectionIds: cipher.collectionIds,
            key: cipher.key,
            name: Localizations.errorCannotDecrypt,
            subtitle: "",
            type: type,
            favorite: cipher.favorite,
            reprompt: cipher.reprompt,
            organizationUseTotp: cipher.organizationUseTotp,
            edit: cipher.edit,
            permissions: cipher.permissions,
            viewPassword: cipher.viewPassword,
            attachments: UInt32(cipher.attachments?.count ?? 0),
            hasOldAttachments: false,
            creationDate: cipher.creationDate,
            deletedDate: cipher.deletedDate,
            revisionDate: cipher.revisionDate,
            archivedDate: cipher.archivedDate,
            copyableFields: [],
            localData: nil,
        )
    }
}
