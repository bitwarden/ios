import BitwardenSdk

/// An enumeration of groups of items displayed in the vault list.
///
public enum VaultListGroup: Equatable, Hashable {
    // MARK: Cipher Types

    /// A group of card type ciphers.
    case card

    /// A group of identity type ciphers.
    case identity

    /// A group of login type ciphers.
    case login

    /// A group of secure note type ciphers.
    case secureNote

    /// A group of TOTP Enabled login types.
    case totp

    // MARK: Collections

    /// A group of ciphers within a collection.
    case collection(id: String, name: String, organizationId: String)

    // MARK: Folders

    /// A group of ciphers within a folder.
    case folder(id: String, name: String)

    // MARK: Trash

    /// A group of ciphers in the trash.
    case trash
}

extension VaultListGroup {
    /// The collection's ID, if the group is a collection.
    var collectionId: String? {
        guard case let .collection(collectionId, _, _) = self else { return nil }
        return collectionId
    }

    /// The folder's ID, if the group is a collection.
    var folderId: String? {
        guard case let .folder(folderId, _) = self else { return nil }
        return folderId
    }

    /// The display name for the group.
    var name: String {
        switch self {
        case .card:
            return Localizations.typeCard
        case let .collection(_, name, _):
            return name
        case let .folder(_, name):
            return name
        case .identity:
            return Localizations.typeIdentity
        case .login:
            return Localizations.typeLogin
        case .secureNote:
            return Localizations.typeSecureNote
        case .totp:
            return Localizations.verificationCodes
        case .trash:
            return Localizations.trash
        }
    }

    /// The navigation title for the group.
    var navigationTitle: String {
        switch self {
        case .card:
            return Localizations.cards
        case let .collection(_, name, _):
            return name
        case let .folder(_, name):
            return name
        case .identity:
            return Localizations.identities
        case .login:
            return Localizations.logins
        case .secureNote:
            return Localizations.secureNotes
        case .totp:
            return Localizations.verificationCodes
        case .trash:
            return Localizations.trash
        }
    }

    /// The organization's ID of the collection, if the group is a collection.
    var organizationId: String? {
        guard case let .collection(_, _, organizationId) = self else { return nil }
        return organizationId
    }
}
