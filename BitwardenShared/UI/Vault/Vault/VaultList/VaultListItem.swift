@preconcurrency import BitwardenSdk
import Foundation

/// Data model for an item displayed in the vault list.
///
public struct VaultListItem: Equatable, Identifiable, Sendable, VaultItemWithDecorativeIcon {
    // MARK: Types

    /// An enumeration for the type of item being displayed by this item.
    public enum ItemType: Equatable, Sendable {
        /// The wrapped item is a cipher.
        ///
        /// - Parameters
        ///   - CipherListView: The cipher to wrap.
        ///   - Fido2CredentialAutofillView: Additional data from the main Fido2 credential
        ///   of the `CipherListView` to be displayed when needed (Optional).
        ///
        case cipher(CipherListView, Fido2CredentialAutofillView? = nil)

        /// The wrapped item is a group of items.
        case group(VaultListGroup, Int)

        /// A TOTP Code Item.
        ///
        /// - Parameters
        ///   - name: The name of the Cipher, used for sorting.
        ///   - totpModel: The TOTP model for a cipher.
        ///
        case totp(name: String, totpModel: VaultListTOTP)
    }

    // MARK: Static properties

    /// The default sort descriptor to use to order `VaultListItem`s.
    static let defaultSortDescriptor = SortDescriptorWrapper<VaultListItem>(\.sortValue, comparator: .localizedStandard)

    // MARK: Properties

    /// The identifier for the item.
    public let id: String

    /// The type of item being displayed by this item.
    public let itemType: ItemType
}

extension VaultListItem {
    /// What's used to sort `VaultListItem`s depending on its item type.
    var sortValue: String {
        return switch itemType {
        case let .cipher(cipherListView, _):
            cipherListView.name
        case .group:
            ""
        case let .totp(name, model):
            name + (model.cipherListView.type.loginListView?.username ?? "") + "\(model.id)"
        }
    }
}

extension VaultListItem {
    /// Initialize a `VaultListItem` from a `CipherListView`.
    ///
    /// - Parameter cipherListView: The `CipherListView` used to initialize the `VaultListItem`.
    ///
    init?(cipherListView: CipherListView) {
        guard let id = cipherListView.id else { return nil }
        self.init(id: id, itemType: .cipher(cipherListView))
    }

    /// Initialize a `VaultListItem` from a `CipherListView`.
    /// - Parameters:
    ///   - cipherListView: The `CipherListView` used to initialize the `VaultListItem`.
    ///   - fido2CredentialAutofillView: The main Fido2 credential of the `cipherView` prepared for UI display.
    init?(cipherListView: CipherListView, fido2CredentialAutofillView: Fido2CredentialAutofillView) {
        guard let id = cipherListView.id, cipherListView.type.isLogin else { return nil }
        self.init(id: id, itemType: .cipher(cipherListView, fido2CredentialAutofillView))
    }
}

extension VaultListItem {
    var cipherDecorativeIconDataView: CipherDecorativeIconDataView? {
        loginListView
    }

    /// The RpId of the main Fido2 credential.
    var fido2CredentialRpId: String? {
        switch itemType {
        case let .cipher(_, fido2CredentialAutofillView):
            fido2CredentialAutofillView?.rpId ?? nil
        case .group:
            nil
        case .totp:
            nil
        }
    }

    /// An image asset for this item that can be used in the UI.
    var icon: ImageAsset {
        switch itemType {
        case let .cipher(cipherItem, fido2CredentialAutofillView):
            switch cipherItem.type {
            case .card:
                Asset.Images.card24
            case .identity:
                Asset.Images.idCard24
            case .login:
                fido2CredentialAutofillView != nil ? Asset.Images.passkey24 : Asset.Images.globe24
            case .secureNote:
                Asset.Images.file24
            case .sshKey:
                Asset.Images.key24
            }
        case let .group(group, _):
            switch group {
            case .card:
                Asset.Images.card24
            case .collection:
                Asset.Images.collections24
            case .folder,
                 .noFolder:
                Asset.Images.folder24
            case .identity:
                Asset.Images.idCard24
            case .login:
                Asset.Images.globe24
            case .secureNote:
                Asset.Images.file24
            case .sshKey:
                Asset.Images.key24
            case .totp:
                Asset.Images.clock24
            case .trash:
                Asset.Images.trash24
            }
        case .totp:
            Asset.Images.clock24
        }
    }

    /// The accessibility ID for the ciphers icon.
    var iconAccessibilityId: String {
        switch itemType {
        case let .cipher(cipherItem, _):
            switch cipherItem.type {
            case .card:
                return "CardCipherIcon"
            case .identity:
                return "IdentityCipherIcon"
            case .login:
                return "LoginCipherIcon"
            case .secureNote:
                return "SecureNoteCipherIcon"
            case .sshKey:
                return "SSHKeyCipherIcon"
            }
        default:
            return ""
        }
    }

    /// The accessibility ID for each vault item.
    var vaultItemAccessibilityId: String {
        switch itemType {
        case let .group(vaultListGroup, _):
            if vaultListGroup.isFolder {
                return "FolderCell"
            }
            if vaultListGroup.collectionId != nil {
                return "CollectionCell"
            }
            return "ItemFilterCell"
        case .cipher:
            return "CipherCell"
        case .totp:
            return "TOTPCell"
        }
    }

    /// The login view containing the uri's to download the special decorative icon, if applicable.
    var loginListView: BitwardenSdk.LoginListView? {
        switch itemType {
        case let .cipher(cipherView, _):
            return cipherView.type.loginListView
        case .group:
            return nil
        case let .totp(_, totpModel):
            return totpModel.cipherListView.type.loginListView
        }
    }

    /// Whether to show or not the Fido2 credential RpId
    var shouldShowFido2CredentialRpId: Bool {
        switch itemType {
        case let .cipher(cipherView, fido2CredentialAutofillView):
            guard let fido2CredentialRpId, !fido2CredentialRpId.isEmpty else {
                return false
            }
            return fido2CredentialAutofillView != nil && cipherView.name != fido2CredentialRpId
        case .group:
            return false
        case .totp:
            return false
        }
    }

    /// The subtitle to show in the row.
    var subtitle: String? {
        switch itemType {
        case let .cipher(cipherView, fido2CredentialAutofillView):
            fido2CredentialAutofillView?.userNameForUi ?? cipherView.subtitle
        case .group:
            nil
        case .totp:
            nil
        }
    }
}

public struct VaultListTOTP: Equatable, Sendable {
    /// The id of the associated Cipher.
    ///
    let id: String

    /// The `BitwardenSdk.CipherListView` used to populate the view and regenerate codes.
    ///
    let cipherListView: BitwardenSdk.CipherListView

    /// Whether seeing the TOTP code requires a master password.
    let requiresMasterPassword: Bool

    /// The current TOTP code for the cipher.
    ///
    var totpCode: TOTPCodeModel
}
