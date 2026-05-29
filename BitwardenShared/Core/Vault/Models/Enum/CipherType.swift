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

    /// A driver's license.
    case driversLicense = 7

    /// A passport.
    case passport = 8
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
        case .driversLicense:
            self = .driversLicense
        case .passport:
            self = .passport
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
    public static let allCases: [CipherType] = [
        .login,
        .card,
        .identity,
        .secureNote,
        .sshKey,
        .bankAccount,
        .driversLicense,
        .passport,
    ]
}

extension CipherType: Menuable {
    public var localizedName: String {
        switch self {
        case .bankAccount: Localizations.bankAccount
        case .card: Localizations.typeCard
        case .driversLicense: Localizations.license
        case .identity: Localizations.typeIdentity
        case .login: Localizations.typeLogin
        case .passport: Localizations.passport
        case .secureNote: Localizations.typeSecureNote
        case .sshKey: Localizations.sshKey
        }
    }
}

extension CipherType {
    /// These are the cases of `CipherType` that the user can use to create a cipher.
    static let canCreateCases: [CipherType] = [.login, .card, .identity, .secureNote, .driversLicense]

    /// The cases of `CipherType` that are gated behind the `.newItemTypes` feature flag.
    /// While the flag is disabled these types are hidden from vault list/search assembly.
    static let newItemTypesGatedCases: [CipherType] = [.bankAccount, .driversLicense, .passport]

    /// The allowed custom field types per cipher type.
    var allowedFieldTypes: [FieldType] {
        switch self {
        case .card, .identity, .login:
            [.text, .hidden, .boolean, .linked]
        case .bankAccount, .driversLicense, .passport, .secureNote, .sshKey:
            [.text, .hidden, .boolean]
        }
    }
}
