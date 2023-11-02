/// An enum describing the type of data contained in a cipher.
///
enum CipherType: Int, Codable {
    /// A login containing a username and password.
    case login = 1

    /// A secure note.
    case secureNote = 2

    /// A credit/debit card.
    case card = 3

    /// Personal information for filling out forms.
    case identity = 4
}

extension CipherType {
    /// Creates a new `CipherType` from the associated `VaultListGroup`.
    ///
    /// - Parameter group: The `VaultListGroup` to use to create this `CipherType`.
    ///
    init?(group: VaultListGroup?) {
        guard let group else { return nil }
        switch group {
        case .card:
            self = .card
        case .identity:
            self = .identity
        case .login:
            self = .login
        case .secureNote:
            self = .secureNote
        case .folder,
             .trash:
            return nil
        }
    }
}

extension CipherType: CaseIterable {
    static var allCases: [CipherType] = [.login, .card, .identity, .secureNote]
}

extension CipherType: Menuable {
    var localizedName: String {
        switch self {
        case .card: return Localizations.typeCard
        case .identity: return Localizations.typeIdentity
        case .login: return Localizations.typeLogin
        case .secureNote: return Localizations.typeSecureNote
        }
    }
}
