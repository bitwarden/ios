import BitwardenSdk
import Foundation

/// Data model for an item displayed in the vault list.
///
struct VaultListItem: Equatable, Identifiable {
    // MARK: Types

    /// An enumeration for the type of item being displayed by this item.
    enum ItemType: Equatable {
        /// The wrapped item is a cipher.
        case cipher(CipherListView)

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

    // MARK: Properties

    /// The identifier for the item.
    let id: String

    /// The type of item being displayed by this item.
    let itemType: ItemType
}

extension VaultListItem {
    /// The name of the cipher for TOTP item types, otherwise ""
    ///     Used to sort the TOTP code items after a refresh.
    var name: String {
        guard case let .totp(name, model) = itemType else { return "" }
        return name + (model.loginView.username ?? "\(model.id)")
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
}

extension VaultListItem {
    /// An image asset for this item that can be used in the UI.
    var icon: ImageAsset {
        switch itemType {
        case let .cipher(cipherItem):
            switch cipherItem.type {
            case .card:
                return Asset.Images.creditCard
            case .identity:
                return Asset.Images.id
            case .login:
                return Asset.Images.globe
            case .secureNote:
                return Asset.Images.doc
            }
        case let .group(group, _):
            switch group {
            case .card:
                return Asset.Images.creditCard
            case .collection:
                return Asset.Images.collections
            case .folder:
                return Asset.Images.folderClosed
            case .identity:
                return Asset.Images.id
            case .login:
                return Asset.Images.globe
            case .secureNote:
                return Asset.Images.doc
            case .totp:
                return Asset.Images.clock
            case .trash:
                return Asset.Images.trash
            }
        case .totp:
            return Asset.Images.clock
        }
    }
}

struct VaultListTOTP: Equatable {
    /// The base url used to fetch icons
    ///
    let iconBaseURL: URL

    /// The id of the associated Cipher.
    ///
    let id: String

    /// The `BitwardenSdk.LoginView` used to populate the view.
    ///
    let loginView: BitwardenSdk.LoginView

    /// The current TOTP code for the cipher.
    ///
    var totpCode: TOTPCode
}
