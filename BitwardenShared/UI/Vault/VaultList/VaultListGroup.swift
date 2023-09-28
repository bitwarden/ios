import BitwardenSdk

/// An enumeration of groups of items displayed in the vault list.
///
enum VaultListGroup: Equatable, Hashable {
    // MARK: Cipher Types

    /// A group of card type ciphers.
    case card

    /// A group of identity type ciphers.
    case identity

    /// A group of login type ciphers.
    case login

    /// A group of secure note type ciphers.
    case secureNote

    // MARK: Folders

    /// A group of ciphers within a folder.
    case folder(FolderView)

    // MARK: Trash

    /// A group of ciphers in the trash.
    case trash
}

extension VaultListGroup {
    /// The display name for the group.
    var name: String {
        switch self {
        case .card:
            return Localizations.typeCard
        case let .folder(folder):
            return folder.name
        case .identity:
            return Localizations.typeIdentity
        case .login:
            return Localizations.typeLogin
        case .secureNote:
            return Localizations.typeSecureNote
        case .trash:
            return Localizations.trash
        }
    }
}
