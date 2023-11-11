import BitwardenSdk

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
    }

    // MARK: Properties

    /// The identifier for the item.
    let id: String

    /// The type of item being displayed by this item.
    let itemType: ItemType
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
            case .folder:
                return Asset.Images.folderClosed
            case .identity:
                return Asset.Images.id
            case .login:
                return Asset.Images.globe
            case .secureNote:
                return Asset.Images.doc
            case .trash:
                return Asset.Images.trash
            }
        }
    }
}
