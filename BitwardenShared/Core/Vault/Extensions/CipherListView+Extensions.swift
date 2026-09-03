import BitwardenResources
import BitwardenSdk
import Foundation

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

    /// Whether the cipher is normally hidden for flows by being archived or deleted.
    var isHidden: Bool {
        archivedDate != nil || deletedDate != nil
    }

    /// Whether this cipher can be archived. Mirrors `CipherView.canBeArchived`.
    var canBeArchived: Bool {
        archivedDate == nil && deletedDate == nil
    }

    /// Whether this cipher can be unarchived. Mirrors `CipherView.canBeUnarchived`.
    var canBeUnarchived: Bool {
        archivedDate != nil && deletedDate == nil
    }

    // MARK: Methods

    /// Computes, synchronously and without decrypting anything beyond what's already in this
    /// list view, the set of more-options actions applicable to this cipher. Used to populate the
    /// vault list row's VoiceOver custom accessibility actions without a `fetchCipher` round trip.
    ///
    /// Scope note: intentionally matches `Alert.moreOptions`'s scope exactly (e.g. no Identity
    /// fields, no bank IBAN/SWIFT/PIN/branch number), even though `copyableFields` exposes more
    /// than the sheet currently surfaces.
    ///
    /// - Parameter hasPremium: Whether the active account has Premium, used to gate the Copy TOTP
    ///   action.
    /// - Returns: The list of applicable more-options action kinds, in the order they should be
    ///   presented.
    func applicableMoreOptionsActionKinds( // swiftlint:disable:this cyclomatic_complexity
        hasPremium: Bool,
    ) -> [MoreOptionsActionKind] {
        guard !isDecryptionFailure else { return [] }

        var kinds: [MoreOptionsActionKind] = [.view]
        if deletedDate == nil { kinds.append(.edit) }

        switch type {
        case .card:
            if copyableFields.contains(.cardNumber) { kinds.append(.copyCardNumber) }
            if copyableFields.contains(.cardSecurityCode) { kinds.append(.copySecurityCode) }
        case let .login(loginListView):
            if copyableFields.contains(.loginUsername) { kinds.append(.copyUsername) }
            if copyableFields.contains(.loginPassword) { kinds.append(.copyPassword) }
            if copyableFields.contains(.loginTotp), hasPremium || organizationUseTotp {
                kinds.append(.copyTotp)
            }
            if let uri = loginListView.uris?.first?.uri, URL(string: uri) != nil {
                kinds.append(.launch)
            }
        case .identity:
            break
        case .secureNote:
            if copyableFields.contains(.secureNotes) { kinds.append(.copyNotes) }
        case .sshKey:
            if copyableFields.contains(.sshKey) {
                kinds.append(.copyPublicKey)
                if viewPassword { kinds.append(.copyPrivateKey) }
                kinds.append(.copyFingerprint)
            }
        case .bankAccount:
            if copyableFields.contains(.bankAccountAccountNumber) { kinds.append(.copyAccountNumber) }
            if copyableFields.contains(.bankAccountRoutingNumber) { kinds.append(.copyRoutingNumber) }
        case .driversLicense:
            if copyableFields.contains(.driversLicenseLicenseNumber) { kinds.append(.copyLicenseNumber) }
        case .passport:
            if copyableFields.contains(.passportPassportNumber) { kinds.append(.copyPassportNumber) }
        }

        if canBeArchived { kinds.append(.archive) }
        if canBeUnarchived { kinds.append(.unarchive) }
        return kinds
    }

    /// Whether the cipher belongs to a group.
    /// - Parameter group: The group to filter.
    /// - Returns: `true` if the cipher belongs to the group, `false` otherwise.
    func belongsToGroup(_ group: VaultListGroup) -> Bool {
        switch group {
        case .archive:
            archivedDate != nil
        case .bankAccount:
            type.isBankAccount
        case .card:
            type.isCard
        case let .collection(id, _, _):
            collectionIds.contains(id)
        case .driversLicense:
            type == .driversLicense
        case let .folder(id, _):
            folderId == id
        case .identity:
            type == .identity
        case .login:
            type.isLogin
        case .noFolder:
            folderId == nil
        case .passport:
            type == .passport
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

    // swiftlint:disable:next function_body_length
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
        case .bankAccount:
            .bankAccount(
                BankAccountListView(
                    accountNumber: nil,
                    accountType: nil,
                ),
            )
        case .driversLicense:
            .driversLicense
        case .passport:
            .passport
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
