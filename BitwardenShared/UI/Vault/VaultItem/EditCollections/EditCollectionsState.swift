@preconcurrency import BitwardenSdk

// MARK: - EditCollectionsState

/// An object that defines the current state of a `EditCollectionsView`.
///
struct EditCollectionsState: Equatable, Sendable {
    // MARK: Properties

    /// The cipher being edited.
    var cipher: CipherView

    /// The list of collection IDs that the cipher should be included in.
    var collectionIds: [String] = []

    /// The list of collections for the organization.
    var collections: [CollectionView] = []

    // MARK: Initialization

    /// Initialize an `EditCollectionsState` from a cipher.
    ///
    /// - Parameters:
    ///   - cipher: The cipher used to edit the collections.
    ///   - collections: A list of collections to display in the view. Defaults to an empty list
    ///     and the collections are loaded dynamically.
    ///
    init(cipher: CipherView, collections: [CollectionView] = []) {
        self.cipher = cipher
        collectionIds = cipher.collectionIds
        self.collections = collections
    }

    // MARK: Methods

    /// Toggles whether the cipher is included in the specified collection.
    ///
    /// - Parameters:
    ///   - newValue: Whether the cipher is included in the collection.
    ///   - collectionId: The identifier of the collection.
    ///
    mutating func toggleCollection(newValue: Bool, collectionId: String) {
        if newValue {
            collectionIds.append(collectionId)
        } else {
            collectionIds = collectionIds.filter { $0 != collectionId }
        }
    }
}

extension EditCollectionsState {
    /// The updated cipher with the selected collections.
    var updatedCipher: CipherView {
        cipher.update(collectionIds: collectionIds)
    }
}
