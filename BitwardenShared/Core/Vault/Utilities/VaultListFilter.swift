// MARK: - VaultListFilter

/// The filter to be used when getting the vault list.
public struct VaultListFilter: Sendable, Equatable {
    /// Whether to add the TOTP group.
    let addTOTPGroup: Bool

    /// Whether to add the trash group.
    let addTrashGroup: Bool

    /// The vault filter type.
    let filterType: VaultFilterType

    /// The vault list group to filter.
    let group: VaultListGroup?

    /// The mode in which the autofill list is presented.
    let mode: AutofillListMode?

    /// The relying party identifier of the Fido2 request.
    let rpID: String?

    /// The search text to use as the query to filter ciphers.
    ///
    /// On init this has been lowercased, whitespaces and new lines trimmed and converted to diacritic insensitive.
    let searchText: String?

    /// The URI used to filter ciphers that have a matching URI.
    let uri: String?

    /// Initializes the filter.
    /// - Parameters:
    ///   - addTOTPGroup: Whether to add the TOTP group.
    ///   - addTrashGroup: Whether to add the trash group.
    ///   - filterType: The vault filter type.
    ///   - group: The vault list group to filter.
    ///   - mode: The mode in which the autofill list is presented.
    ///   - rpID: The relying party identifier of the Fido2 request.
    ///   - searchText: The search text to use as the query to filter ciphers.
    ///   - uri: The URI used to filter ciphers that have a matching URI
    init(
        addTOTPGroup: Bool = true,
        addTrashGroup: Bool = true,
        filterType: VaultFilterType = .allVaults,
        group: VaultListGroup? = nil,
        mode: AutofillListMode? = nil,
        rpID: String? = nil,
        searchText: String? = nil,
        uri: String? = nil,
    ) {
        self.addTOTPGroup = addTOTPGroup
        self.addTrashGroup = addTrashGroup
        self.filterType = filterType
        self.group = group
        self.mode = mode
        self.rpID = rpID
        self.searchText = searchText?.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        self.uri = uri
    }
}
