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
}

extension CipherType {
    /// Creates a new `CipherType` from the associated `VaultListGroup`.
    ///
    /// - Parameter group: The `VaultListGroup` to use to create this `CipherType`.
    ///
    init?(group: VaultListGroup) {
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
        case .collection,
             .folder,
             .noFolder,
             .totp,
             .trash:
            return nil
        }
    }
}

extension CipherType: CaseIterable {
    public static let allCases: [CipherType] = [.login, .card, .identity, .secureNote, .sshKey]
}

extension CipherType: Menuable {
    var localizedName: String {
        switch self {
        case .card: return Localizations.typeCard
        case .identity: return Localizations.typeIdentity
        case .login: return Localizations.typeLogin
        case .secureNote: return Localizations.typeSecureNote
        case .sshKey: return Localizations.sshKey
        }
    }
}

extension CipherType {
    /// These are the cases of `CipherType` that the user can use to create a cipher.
    static let canCreateCases: [CipherType] = [.login, .card, .identity, .secureNote]

    /// The allowed custom field types per cipher type.
    var allowedFieldTypes: [FieldType] {
        switch self {
        case .card, .identity, .login:
            return [.text, .hidden, .boolean, .linked]
        case .secureNote, .sshKey:
            return [.text, .hidden, .boolean]
        }
    }
}
