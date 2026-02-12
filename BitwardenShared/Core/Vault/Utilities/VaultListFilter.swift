// MARK: - VaultListFilter

/// The filter to be used when getting the vault list.
public struct VaultListFilter: Sendable, Equatable {
    /// The vault filter type.
    let filterType: VaultFilterType

    /// The vault list group to filter.
    let group: VaultListGroup?

    /// The mode in which the autofill list is presented.
    let mode: AutofillListMode?

    /// Options to configure the vault list behavior.
    let options: VaultListOptions

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
    ///   - filterType: The vault filter type.
    ///   - group: The vault list group to filter.
    ///   - mode: The mode in which the autofill list is presented.
    ///   - options: Options to configure the vault list behavior.
    ///   - rpID: The relying party identifier of the Fido2 request.
    ///   - searchText: The search text to use as the query to filter ciphers.
    ///   - uri: The URI used to filter ciphers that have a matching URI
    init(
        filterType: VaultFilterType = .allVaults,
        group: VaultListGroup? = nil,
        mode: AutofillListMode? = nil,
        options: VaultListOptions = [],
        rpID: String? = nil,
        searchText: String? = nil,
        uri: String? = nil,
    ) {
        self.filterType = filterType
        self.group = group
        self.mode = mode
        self.options = options
        self.rpID = rpID
        self.searchText = searchText?.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        self.uri = uri
    }
}

// MARK: - VaultListOptions

/// Options to configure the vault list behavior.
public struct VaultListOptions: OptionSet, Sendable {
    /// Whether to add the TOTP group to the vault list.
    static let addTOTPGroup = VaultListOptions(rawValue: 1 << 0)

    /// Whether to add the hidden items group to the vault list.
    static let addHiddenItemsGroup = VaultListOptions(rawValue: 1 << 1)

    /// Whether the vault list is being displayed in picker mode.
    static let isInPickerMode = VaultListOptions(rawValue: 1 << 2)

    public let rawValue: UInt

    /// Initializes a `VaultListOptions` with a `rawValue`
    /// - Parameter rawValue: The raw value for the option.
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}
