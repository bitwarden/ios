import BitwardenSdk

/// Data model for an item displayed in the vault list.
///
struct SendListItem: Equatable, Identifiable {
    // MARK: Types

    /// An enumeration for the type of item being displayed by this item.
    enum ItemType: Equatable {
        /// The wrapped item is a cipher.
        case send(BitwardenSdk.SendListView)

        /// The wrapped item is a group of items.
        case group(SendType, Int)
    }

    // MARK: Properties

    /// The identifier for the item.
    let id: String

    /// The type of item being displayed by this item.
    let itemType: ItemType
}

extension SendListItem {
    /// Initialize a `VaultListItem` from a `CipherListView`.
    ///
    /// - Parameter cipherListView: The `CipherListView` used to initialize the `VaultListItem`.
    ///
    init?(sendListView: BitwardenSdk.SendListView) {
        self.init(id: sendListView.id, itemType: .send(sendListView))
    }
}

extension SendListItem {
    /// An image asset for this item that can be used in the UI.
    var icon: ImageAsset {
        switch itemType {
        case let .send(sendListView):
            switch sendListView.type {
            case .file:
                Asset.Images.doc3
            case .text:
                Asset.Images.doc
            }
        case let .group(group, _):
            switch group {
            case .file:
                Asset.Images.doc3
            case .text:
                Asset.Images.doc
            }
        }
    }
}
