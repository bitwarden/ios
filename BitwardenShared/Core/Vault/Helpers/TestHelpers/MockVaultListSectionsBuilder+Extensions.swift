@testable import BitwardenShared

extension MockVaultListSectionsBuilder {
    func setUpCallOrderHelper() -> MockCallOrderHelper {
        let helper = MockCallOrderHelper()

        addTOTPSectionClosure = { () -> VaultListSectionsBuilder in
            helper.recordCall("addTOTPSection")
            return self
        }
        addFavoritesSectionClosure = { () -> VaultListSectionsBuilder in
            helper.recordCall("addFavoritesSection")
            return self
        }
        addGroupSectionClosure = { () -> VaultListSectionsBuilder in
            helper.recordCall("addGroupSection")
            return self
        }
        addTypesSectionClosure = { () -> VaultListSectionsBuilder in
            helper.recordCall("addTypesSection")
            return self
        }
        addFoldersSectionNestedFolderIdClosure = { (_: String?) throws -> VaultListSectionsBuilder in
            helper.recordCall("addFoldersSection")
            return self
        }
        addCollectionsSectionNestedCollectionIdClosure = { (_: String?) throws -> VaultListSectionsBuilder in
            helper.recordCall("addCollectionsSection")
            return self
        }
        addTrashSectionClosure = { () -> VaultListSectionsBuilder in
            helper.recordCall("addTrashSection")
            return self
        }

        return helper
    }
}
