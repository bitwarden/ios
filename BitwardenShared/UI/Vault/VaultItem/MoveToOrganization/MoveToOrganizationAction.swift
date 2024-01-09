// MARK: - MoveToOrganizationAction

/// Actions that can be processed by a `MoveToOrganizationProcessor`.
///
enum MoveToOrganizationAction: Equatable {
    /// The toggle for including the item in a collection was changed.
    case collectionToggleChanged(Bool, collectionId: String)

    /// The dismiss button was pressed.
    case dismissPressed

    /// The owner field was changed.
    case ownerChanged(CipherOwner)
}
