import BitwardenResources
import BitwardenSdk

extension CipherListView {
    // MARK: Properties

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

    /// Whether the cipher is archived.
    var isArchived: Bool {
        archivedDate != nil
    }

    // MARK: Methods

    /// Whether the cipher belongs to a group.
    /// - Parameter group: The group to filter.
    /// - Returns: `true` if the cipher belongs to the group, `false` otherwise.
    func belongsToGroup(_ group: VaultListGroup) -> Bool {
        switch group {
        case .archive:
            archivedDate != nil
        case .card:
            type.isCard
        case let .collection(id, _, _):
            collectionIds.contains(id)
        case let .folder(id, _):
            folderId == id
        case .identity:
            type == .identity
        case .login:
            type.isLogin
        case .noFolder:
            folderId == nil
        case .secureNote:
            type == .secureNote
        case .sshKey:
            type == .sshKey
        case .totp:
            type.loginListView?.totp != nil
        case .trash:
            deletedDate != nil
        }
    }

    /// Determines how well the cipher matches a search query.
    ///
    /// This method performs a multi-level search across the cipher's properties to determine
    /// the quality of the match. The query should be preprocessed (lowercased and diacritic-folded)
    /// before calling this method.
    ///
    /// - Parameter query: The preprocessed search query (lowercased and diacritic-folded).
    ///
    /// - Returns: A `CipherMatchResult` indicating the match quality:
    ///   - `.exact`: The cipher name matches the query
    ///   - `.fuzzy`: Some other cipher properties match the query
    ///   - `.none`: No match found
    ///
    func matchesSearchQuery(_ query: String) -> CipherMatchResult {
        guard !query.isEmpty else {
            return .none
        }

        if name.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current).contains(query) {
            return .exact
        }

        // Fuzzy match: ID starts with query (requires minimum 8 characters for UUID prefix matching)
        if query.count >= 8, id?.starts(with: query) == true {
            return .fuzzy
        }

        // Fuzzy match other fields: Login Username, Card Brand, Last 4 card numbers, Identity full name.
        // This can all be done here since how the SDK builds the cipher's subtitle.
        if subtitle.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current).contains(query) == true {
            return .fuzzy
        }

        if type.loginListView?.uris?
            .contains(where: { $0.uri?.lowercased().contains(query) == true }) == true {
            return .fuzzy
        }

        return .none
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
