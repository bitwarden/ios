// swiftlint:disable:this file_name

import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

extension MockVaultListPreparedDataBuilder {
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
