import BitwardenSdk

/// Helper functions for collections.
protocol CollectionHelper { // sourcery: AutoMockable
    /// Orders the collections accordingly.
    /// - Parameter collections: Collections to order.
    /// - Returns: Ordered collections.
    func order(_ collections: [CollectionView]) async throws -> [CollectionView]
}

/// Default implementation of `CollectionHelper`.
struct DefaultCollectionHelper: CollectionHelper {
    // MARK: Properties

    /// The service used to manage syncing and updates to the user's organizations.
    let organizationService: OrganizationService

    // MARK: Methods

    func order(_ collections: [CollectionView]) async throws -> [CollectionView] {
        if collections.count(where: { $0.type == .defaultUserCollection }) <= 1 {
            return collections.sorted(using: CollectionView.defaultSortDescriptor)
        }

        // if there are more than one default user collection, then we need to order
        // them by organization name they belong to.
        let organizations = try await organizationService.fetchAllOrganizations()
        let organizationLookup = Dictionary(uniqueKeysWithValues: organizations.map { ($0.id, $0.name) })

        return collections.sorted { col1, col2 in
            if col1.type.rawValue > col2.type.rawValue {
                return true
            } else if col1.type.rawValue < col2.type.rawValue {
                return false
            }

            if col1.type == .sharedCollection {
                return col1.name.localizedStandardCompare(col2.name) == .orderedAscending
            }

            if let orgName1 = organizationLookup[col1.organizationId],
               let orgName2 = organizationLookup[col2.organizationId] {
                return orgName1.localizedStandardCompare(orgName2) == .orderedAscending
            }

            return false
        }
    }
}
