import BitwardenSdk

// MARK: - MoveToOrganizationState

/// An object that defines the current state of a `MoveToOrganizationView`.
///
struct MoveToOrganizationState: Equatable {
    // MARK: Properties

    /// The cipher to move to an organization.
    var cipher: CipherView

    /// The list of collection IDs that the cipher should be included in.
    var collectionIds: [String] = []

    /// The full list of collections for the user, across all organizations.
    var collections: [CollectionView] = []

    /// The organization ID of the organization that the cipher is moving to.
    var organizationId: String?

    /// The list of ownership options that can be selected for the cipher.
    var ownershipOptions: [CipherOwner] = [] {
        didSet {
            if owner == nil {
                owner = ownershipOptions.first
            }
        }
    }

    // MARK: Computed Properties

    /// The list of collections that can be selected from for the current owner.
    var collectionsForOwner: [CollectionView] {
        guard let owner else { return [] }
        return collections.filter { $0.organizationId == owner.organizationId }
    }

    /// The owner of the cipher.
    var owner: CipherOwner? {
        get {
            ownershipOptions.first { $0.organizationId == organizationId }
        }
        set {
            organizationId = newValue?.organizationId
            collectionIds = []
        }
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

extension MoveToOrganizationState {
    /// The updated cipher with the assigned organization and collections.
    var updatedCipher: CipherView {
        CipherView(
            id: cipher.id,
            organizationId: organizationId,
            folderId: cipher.folderId,
            collectionIds: collectionIds,
            key: cipher.key,
            name: cipher.name,
            notes: cipher.notes,
            type: cipher.type,
            login: cipher.login,
            identity: cipher.identity,
            card: cipher.card,
            secureNote: cipher.secureNote,
            favorite: cipher.favorite,
            reprompt: cipher.reprompt,
            organizationUseTotp: cipher.organizationUseTotp,
            edit: cipher.edit,
            viewPassword: cipher.viewPassword,
            localData: cipher.localData,
            attachments: cipher.attachments,
            fields: cipher.fields,
            passwordHistory: cipher.passwordHistory,
            creationDate: cipher.creationDate,
            deletedDate: cipher.deletedDate,
            revisionDate: cipher.revisionDate
        )
    }
}
