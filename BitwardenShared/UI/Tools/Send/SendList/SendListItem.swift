import BitwardenSdk

/// Data model for an item displayed in the vault list.
///
struct SendListItem: Equatable, Identifiable {
    // MARK: Types

    /// An enumeration for the type of item being displayed by this item.
    enum ItemType: Equatable {
        /// The wrapped item is a send.
        case send(BitwardenSdk.SendView)

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
    /// Initialize a `SendListItem` from a `SendView`.
    ///
    /// - Parameter sendView: The `CipherListView` used to initialize the `SendListItem`.
    ///
    init?(sendView: BitwardenSdk.SendView) {
        guard let sendViewId = sendView.id else { return nil }
        self.init(id: sendViewId, itemType: .send(sendView))
    }
}

extension SendListItem {
    /// An image asset for this item that can be used in the UI.
    var icon: ImageAsset {
        switch itemType {
        case let .send(sendView):
            switch sendView.type {
            case .file:
                Asset.Images.doc
            case .text:
                Asset.Images.doc3
            }
        case let .group(group, _):
            switch group {
            case .file:
                Asset.Images.doc
            case .text:
                Asset.Images.doc3
            }
        }
    }
}
