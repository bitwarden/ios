/// Data model for an item displayed in the vault list.
///
struct VaultListItem: Equatable, Identifiable {
    // MARK: Types

    /// An enumeration for the type of item being displayed by this item.
    enum ItemType: Equatable {
        /// The wrapped item is a cipher.
        case cipher(CipherDetailsResponseModel)

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
    /// Initialize a `VaultListItem` from a `CipherDetailsResponseModel`.
    ///
    /// - Parameter responseModel: The `CipherDetailsResponseModel` used to initialize the
    ///     `VaultListItem`.
    ///
    init(cipherDetailResponseModel responseModel: CipherDetailsResponseModel) {
        self.init(id: responseModel.id, itemType: .cipher(responseModel))
    }
}
