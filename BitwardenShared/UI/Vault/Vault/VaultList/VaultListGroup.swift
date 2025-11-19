import BitwardenResources
import BitwardenSdk

/// An enumeration of groups of items displayed in the vault list.
///
public enum VaultListGroup: Equatable, Hashable, Sendable {
    // MARK: Cipher Types

    /// A group of card type ciphers.
    case card

    /// A group of identity type ciphers.
    case identity

    /// A group of login type ciphers.
    case login

    /// A group of secure note type ciphers.
    case secureNote

    /// A group of SSH key type ciphers.
    case sshKey

    /// A group of TOTP Enabled login types.
    case totp

    // MARK: Collections

    /// A group of ciphers within a collection.
    case collection(id: String, name: String, organizationId: String)

    // MARK: Folders

    /// A group of ciphers within a folder.
    case folder(id: String, name: String)

    /// A group of ciphers without a folder
    case noFolder

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

    /// Whether the group is a folder.
    var isFolder: Bool {
        guard case .folder = self else { return false }
        return true
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
            Localizations.typeCard
        case let .collection(_, name, _):
            name
        case let .folder(_, name):
            name
        case .identity:
            Localizations.typeIdentity
        case .login:
            Localizations.typeLogin
        case .secureNote:
            Localizations.typeSecureNote
        case .sshKey:
            Localizations.sshKey
        case .totp:
            Localizations.verificationCodes
        case .trash:
            Localizations.trash
        case .noFolder:
            Localizations.folderNone
        }
    }

    /// The navigation title for the group.
    var navigationTitle: String {
        switch self {
        case .card:
            Localizations.cards
        case let .collection(_, name, _):
            name
        case let .folder(_, name):
            name
        case .identity:
            Localizations.identities
        case .login:
            Localizations.logins
        case .secureNote:
            Localizations.secureNotes
        case .sshKey:
            Localizations.sshKeys
        case .totp:
            Localizations.verificationCodes
        case .trash:
            Localizations.trash
        case .noFolder:
            Localizations.folderNone
        }
    }

    /// The organization's ID of the collection, if the group is a collection.
    var organizationId: String? {
        guard case let .collection(_, _, organizationId) = self else { return nil }
        return organizationId
    }
}
