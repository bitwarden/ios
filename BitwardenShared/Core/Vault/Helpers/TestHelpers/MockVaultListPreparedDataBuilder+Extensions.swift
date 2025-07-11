import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

extension MockVaultListPreparedDataBuilder {
    func setUpCallOrderHelper() -> MockCallOrderHelper {
        let helper = MockCallOrderHelper()

        addFavoriteItemCipherClosure = { _ -> VaultListPreparedDataBuilder in
            helper.recordCall("addFavoriteItem")
            return self
        }
        addFolderItemCipherFilterFoldersClosure = { _, _, _ -> VaultListPreparedDataBuilder in
            helper.recordCall("addFolderItem")
            return self
        }
        addItemForGroupWithClosure = { _, _ -> VaultListPreparedDataBuilder in
            helper.recordCall("addItemForGroup")
            return self
        }
        addNoFolderItemCipherClosure = { _ -> VaultListPreparedDataBuilder in
            helper.recordCall("addNoFolderItem")
            return self
        }
        incrementCipherTypeCountCipherClosure = { _ -> VaultListPreparedDataBuilder in
            helper.recordCall("incrementCipherTypeCount")
            return self
        }
        incrementCipherDeletedCountClosure = { () -> VaultListPreparedDataBuilder in
            helper.recordCall("incrementCipherDeletedCount")
            return self
        }
        incrementCollectionCountCipherClosure = { _ -> VaultListPreparedDataBuilder in
            helper.recordCall("incrementCollectionCount")
            return self
        }
        incrementTOTPCountCipherClosure = { _ async -> VaultListPreparedDataBuilder in
            helper.recordCall("incrementTOTPCount")
            return self
        }
        prepareCollectionsCollectionsFilterTypeClosure = { _, _ -> VaultListPreparedDataBuilder in
            helper.recordCall("prepareCollections")
            return self
        }
        prepareFoldersFoldersFilterTypeClosure = { _, _ -> VaultListPreparedDataBuilder in
            helper.recordCall("prepareFolders")
            return self
        }

        return helper
    }

    func setUpFluentReturn() {
        addFavoriteItemCipherReturnValue = self
        addFolderItemCipherFilterFoldersReturnValue = self
        addItemForGroupWithReturnValue = self
        addNoFolderItemCipherReturnValue = self
        incrementCipherTypeCountCipherReturnValue = self
        incrementCipherDeletedCountReturnValue = self
        incrementCollectionCountCipherReturnValue = self
        incrementTOTPCountCipherReturnValue = self
        prepareCollectionsCollectionsFilterTypeReturnValue = self
        prepareFoldersFoldersFilterTypeReturnValue = self
    }
}
