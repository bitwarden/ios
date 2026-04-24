import BitwardenKit
import BitwardenResources

/// An enum describing the type of data contained in a cipher.
///
public enum CipherType: Int, Codable, Sendable {
    /// A login containing a username and password.
    case login = 1

    /// A secure note.
    case secureNote = 2

    /// A credit/debit card.
    case card = 3

    /// Personal information for filling out forms.
    case identity = 4

    /// An SSH key.
    case sshKey = 5

    /// A bank account.
    case bankAccount = 6
}

extension CipherType {
    /// Creates a new `CipherType` from the associated `VaultListGroup`.
    ///
    /// - Parameter group: The `VaultListGroup` to use to create this `CipherType`.
    ///
    init?(group: VaultListGroup) {
        // Note: the `.bankAccount` case on `VaultListGroup` is introduced in
        // PM-32809 Part 2/3 (vault list & repository plumbing). This initializer
        // will grow a matching `case .bankAccount: self = .bankAccount` arm there.
        switch group {
        case .card:
            self = .card
        case .identity:
            self = .identity
        case .login:
            self = .login
        case .secureNote:
            self = .secureNote
        case .sshKey:
            self = .sshKey
        case
            .archive,
            .collection,
            .folder,
            .noFolder,
            .totp,
            .trash:
            return nil
        }
    }
}

extension CipherType: CaseIterable {
    public static let allCases: [CipherType] = [.login, .card, .identity, .secureNote, .sshKey, .bankAccount]
}

extension CipherType: Menuable {
    public var localizedName: String {
        switch self {
        case .bankAccount: Localizations.typeBankAccount
        case .card: Localizations.typeCard
        case .identity: Localizations.typeIdentity
        case .login: Localizations.typeLogin
        case .secureNote: Localizations.typeSecureNote
        case .sshKey: Localizations.sshKey
        }
    }
}

extension CipherType {
    /// The cipher types the user can use to create a cipher when the `newItemTypes` feature
    /// flag is disabled. This is the authoritative "today" set.
    ///
    /// Callers with access to a `ConfigService` should prefer the flag-aware
    /// `canCreateCases(isNewItemTypesEnabled:)` helper; this constant is only appropriate
    /// for seeding default state before the flag value is known.
    static let canCreateCasesBase: [CipherType] = [.login, .card, .identity, .secureNote]

    /// The cipher types the user can use to create a cipher when the `newItemTypes` feature
    /// flag is enabled. Extends the base set with the new types introduced by PM-32009.
    static let canCreateCasesWithNewItemTypes: [CipherType] = canCreateCasesBase + [.bankAccount]

    /// The allowed custom field types per cipher type.
    ///
    /// - Note: Bank Account is limited to `.text`, `.hidden`, `.boolean` — linked fields are
    ///   not part of MVP (US-1.1).
    var allowedFieldTypes: [FieldType] {
        switch self {
        case .card, .identity, .login:
            [.text, .hidden, .boolean, .linked]
        case .bankAccount, .secureNote, .sshKey:
            [.text, .hidden, .boolean]
        }
    }
}

extension CipherType {
    /// The type-agnostic placeholder icon for this cipher type.
    ///
    /// Centralizes icon routing so the final assets from PM-34128 can be swapped in a
    /// single place when design ships. Callers that need a brand-specific icon (e.g.,
    /// card brand icons) should special-case before falling back to this helper.
    ///
    /// - Note: Bank Account currently reuses `card24` until the PM-34128 design work
    ///   delivers a dedicated asset. Driver's License and Passport will join this
    ///   helper in PRs 2 and 3.
    ///
    var iconPlaceholder: SharedImageAsset {
        switch self {
        case .bankAccount:
            // TODO: PM-34128 Swap to the final bank account asset when icon design
            // ships.
            SharedAsset.Icons.card24
        case .card:
            SharedAsset.Icons.card24
        case .identity:
            SharedAsset.Icons.idCard24
        case .login:
            SharedAsset.Icons.globe24
        case .secureNote:
            SharedAsset.Icons.stickyNote24
        case .sshKey:
            SharedAsset.Icons.key24
        }
    }
}

extension CipherType {
    /// Returns the cipher types that the user can create, gated by the new item types feature
    /// flag.
    ///
    /// - Parameter isNewItemTypesEnabled: Whether the `newItemTypes` feature flag is enabled.
    /// - Returns: The creatable cipher types. When the flag is enabled, the new types (Bank
    ///   Account) are appended to the base list.
    ///
    static func canCreateCases(isNewItemTypesEnabled: Bool) -> [CipherType] {
        isNewItemTypesEnabled ? canCreateCasesWithNewItemTypes : canCreateCasesBase
    }
}
