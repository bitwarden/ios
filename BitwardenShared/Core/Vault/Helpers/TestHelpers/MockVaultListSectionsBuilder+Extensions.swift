@testable import BitwardenShared
@testable import BitwardenSharedMocks

extension MockVaultListSectionsBuilder {
    func setUpCallOrderHelper() -> MockCallOrderHelper {
        let helper = MockCallOrderHelper()

        addAutofillPasswordsSectionClosure = { () -> VaultListSectionsBuilder in
            helper.recordCall("addAutofillPasswordsSection")
            return self
        }
        addAutofillCombinedMultipleSectionClosure = { (_: String?, _: String?) -> VaultListSectionsBuilder in
            helper.recordCall("addAutofillCombinedMultipleSection")
            return self
        }
        addAutofillCombinedSingleSectionClosure = { () -> VaultListSectionsBuilder in
            helper.recordCall("addAutofillCombinedSingleSection")
            return self
        }
        addCipherDecryptionFailureIdsClosure = { () -> VaultListSectionsBuilder in
            helper.recordCall("addCipherDecryptionFailureIds")
            return self
        }
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
        addHiddenItemsSectionClosure = { () -> VaultListSectionsBuilder in
            helper.recordCall("addHiddenItemsSection")
            return self
        }
        addTypesSectionClosure = { () -> VaultListSectionsBuilder in
            helper.recordCall("addTypesSection")
            return self
        }
        addFoldersSectionClosure = { (_: String?) throws -> VaultListSectionsBuilder in
            helper.recordCall("addFoldersSection")
            return self
        }
        addCollectionsSectionClosure = { (_: String?) throws -> VaultListSectionsBuilder in
            helper.recordCall("addCollectionsSection")
            return self
        }
        addSearchResultsSectionClosure = { _ -> VaultListSectionsBuilder in
            helper.recordCall("addSearchResultsSection")
            return self
        }

        return helper
    }
}
