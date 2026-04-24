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
        switch group {
        case .bankAccount:
            self = .bankAccount
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
    /// The cipher types that the user can use to create a cipher when the new item types feature
    /// flag is disabled. This is the pre-feature-flag baseline set.
    static let canCreateCasesBase: [CipherType] = [.login, .card, .identity, .secureNote, .sshKey]

    /// The cipher types that the user can use to create a cipher when the new item types feature
    /// flag is enabled. Extends the base set with the new types introduced by PM-32009.
    static let canCreateCasesWithNewItemTypes: [CipherType] = canCreateCasesBase + [.bankAccount]

    /// These are the cases of `CipherType` that the user can use to create a cipher when the new
    /// item types feature flag is disabled. Callers that have access to the feature flag state
    /// should use `canCreateCases(isNewItemTypesEnabled:)` to get the full list.
    static let canCreateCases: [CipherType] = [.login, .card, .identity, .secureNote]

    /// The allowed custom field types per cipher type.
    var allowedFieldTypes: [FieldType] {
        switch self {
        case .bankAccount, .card, .identity, .login:
            [.text, .hidden, .boolean, .linked]
        case .secureNote, .sshKey:
            [.text, .hidden, .boolean]
        }
    }
}

extension CipherType {
    /// Returns the cipher types that the user can create, gated by the new item types feature flag.
    ///
    /// - Parameter isNewItemTypesEnabled: Whether the `newItemTypes` feature flag is enabled.
    /// - Returns: The creatable cipher types. When the flag is enabled, the new types (Bank
    ///   Account) are appended to the base list.
    ///
    static func canCreateCases(isNewItemTypesEnabled: Bool) -> [CipherType] {
        isNewItemTypesEnabled ? canCreateCasesWithNewItemTypes : canCreateCasesBase
    }
}
