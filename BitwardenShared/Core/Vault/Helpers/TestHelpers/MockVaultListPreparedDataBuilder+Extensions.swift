import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

extension MockVaultListPreparedDataBuilder {
    func setUpCallOrderHelper() -> MockCallOrderHelper { // swiftlint:disable:this function_body_length
        let helper = MockCallOrderHelper()

        addCipherDecryptionFailureClosure = { _ -> VaultListPreparedDataBuilder in
            helper.recordCall("addCipherDecryptionFailure")
            return self
        }
        addFavoriteItemClosure = { _ -> VaultListPreparedDataBuilder in
            helper.recordCall("addFavoriteItem")
            return self
        }
        addFolderItemClosure = { _, _, _ -> VaultListPreparedDataBuilder in
            helper.recordCall("addFolderItem")
            return self
        }
        addItemClosure = { _, _ -> VaultListPreparedDataBuilder in
            helper.recordCall("addItemForGroup")
            return self
        }
        addItemWithMatchResultCipherClosure = { _, _ -> VaultListPreparedDataBuilder in
            helper.recordCall("addItemWithMatchResultCipher")
            return self
        }
        addNoFolderItemClosure = { _ -> VaultListPreparedDataBuilder in
            helper.recordCall("addNoFolderItem")
            return self
        }
        incrementCipherTypeCountClosure = { _ -> VaultListPreparedDataBuilder in
            helper.recordCall("incrementCipherTypeCount")
            return self
        }
        incrementCipherDeletedCountClosure = { () -> VaultListPreparedDataBuilder in
            helper.recordCall("incrementCipherDeletedCount")
            return self
        }
        incrementCollectionCountClosure = { _ -> VaultListPreparedDataBuilder in
            helper.recordCall("incrementCollectionCount")
            return self
        }
        incrementTOTPCountClosure = { _ async -> VaultListPreparedDataBuilder in
            helper.recordCall("incrementTOTPCount")
            return self
        }
        prepareCollectionsClosure = { _, _ -> VaultListPreparedDataBuilder in
            helper.recordCall("prepareCollections")
            return self
        }
        prepareFoldersClosure = { _, _ -> VaultListPreparedDataBuilder in
            helper.recordCall("prepareFolders")
            return self
        }
        prepareRestrictItemsPolicyOrganizationsClosure = { _ -> VaultListPreparedDataBuilder in
            helper.recordCall("prepareRestrictItemsPolicyOrganizations")
            return self
        }

        return helper
    }

    func setUpFluentReturn() {
        addCipherDecryptionFailureReturnValue = self
        addFavoriteItemReturnValue = self
        addFolderItemReturnValue = self
        addItemReturnValue = self
        addNoFolderItemReturnValue = self
        incrementCipherTypeCountReturnValue = self
        incrementCipherDeletedCountReturnValue = self
        incrementCollectionCountReturnValue = self
        incrementTOTPCountReturnValue = self
        prepareCollectionsReturnValue = self
        prepareFoldersReturnValue = self
        prepareRestrictItemsPolicyOrganizationsReturnValue = self
    }
}
