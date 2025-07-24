// swiftlint:disable:this file_name

import BitwardenResources
import BitwardenSdk
import Foundation
import XCTest

@testable import BitwardenShared

/// `CipherItemState` tests focused on the header state of the item view.
class CipherItemStateHeaderTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Tests

    /// `getter:belongsToMultipleCollections` returns `false` when cipher belongs to no collections.
    func test_belongsToMultipleCollections_empty() throws {
        let cipher = CipherView.fixture(collectionIds: [])
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertFalse(state.belongsToMultipleCollections)
    }

    /// `getter:belongsToMultipleCollections` returns `false` when cipher belongs to one collection.
    func test_belongsToMultipleCollections_one() throws {
        let cipher = CipherView.fixture(collectionIds: ["1"])
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertFalse(state.belongsToMultipleCollections)
    }

    /// `getter:belongsToMultipleCollections` returns `true` when cipher belongs to two collections.
    func test_belongsToMultipleCollections_true() throws {
        let cipher = CipherView.fixture(collectionIds: ["1", "2"])
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.belongsToMultipleCollections)
    }

    /// `cipherCollections` returns all the collections that the cipher belongs to.
    func test_cipherCollections_withResults() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: ["2", "3"]
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.allUserCollections = [
            CollectionView.fixture(id: "1"),
            CollectionView.fixture(id: "2"),
            CollectionView.fixture(id: "3"),
            CollectionView.fixture(id: "4"),
            CollectionView.fixture(id: "5"),
        ]
        XCTAssertEqual(state.cipherCollections.map(\.id), ["2", "3"])
    }

    /// `cipherCollections` returns empty if there are no collection ids on the state.
    func test_cipherCollections_empty() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: []
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.allUserCollections = [
            CollectionView.fixture(id: "1"),
            CollectionView.fixture(id: "2"),
            CollectionView.fixture(id: "3"),
            CollectionView.fixture(id: "4"),
            CollectionView.fixture(id: "5"),
        ]
        XCTAssertTrue(state.cipherCollections.isEmpty)
    }

    /// `cipherCollections` returns all collections that the cipher belongs to when
    /// is showing multiple collections.
    func test_cipherCollectionsToDisplay_allCollections() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: ["2", "3"]
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.isShowingMultipleCollections = true
        state.allUserCollections = [
            CollectionView.fixture(id: "1"),
            CollectionView.fixture(id: "2"),
            CollectionView.fixture(id: "3"),
            CollectionView.fixture(id: "4"),
            CollectionView.fixture(id: "5"),
        ]
        XCTAssertEqual(state.cipherCollectionsToDisplay.map(\.id), ["2", "3"])
    }

    /// `cipherCollections` returns the first collection that the cipher belongs to when
    /// is not showing multiple collections.
    func test_cipherCollectionsToDisplay_oneResult() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: ["2", "3"]
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.isShowingMultipleCollections = false
        state.allUserCollections = [
            CollectionView.fixture(id: "1"),
            CollectionView.fixture(id: "2"),
            CollectionView.fixture(id: "3"),
            CollectionView.fixture(id: "4"),
            CollectionView.fixture(id: "5"),
        ]
        XCTAssertEqual(state.cipherCollectionsToDisplay.map(\.id), ["2"])
    }

    /// `cipherCollectionsToDisplay` returns empty when no cipher collections.
    func test_cipherCollectionsToDisplay_empty() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: []
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.allUserCollections = [
            CollectionView.fixture(id: "1"),
            CollectionView.fixture(id: "2"),
            CollectionView.fixture(id: "3"),
            CollectionView.fixture(id: "4"),
            CollectionView.fixture(id: "5"),
        ]
        XCTAssertTrue(state.cipherCollectionsToDisplay.isEmpty)
    }

    /// `collectionsForOwner` contains collections that are not read-only
    func test_collectionsForOwner() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: ["1", "2", "3"],
            login: .fixture(),
            organizationId: "Org1"
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.ownershipOptions = [.organization(id: "Org1", name: "Organization 1")]
        state.allUserCollections = [
            CollectionView.fixture(id: "1", organizationId: "Org1", manage: true, readOnly: false),
            CollectionView.fixture(id: "2", organizationId: "Org1", manage: false, readOnly: false),
            CollectionView.fixture(id: "3", organizationId: "Org1", manage: false, readOnly: true),
        ]
        XCTAssertEqual(state.collectionsForOwner.map(\.id), ["1", "2"])
    }

    /// `getter:isShowingMultipleCollections` `false` when not showing collections.
    func test_isShowingMultipleCollections_empty() throws {
        let state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        XCTAssertFalse(state.isShowingMultipleCollections)
    }

    /// `getter:multipleCollectionsDisplayButtonTitle` returns "Show more" when 1 collection is shown.
    func test_multipleCollectionsDisplayButtonTitle_one() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(collectionIds: ["1", "2"]), hasPremium: true))
        state.allUserCollections = [CollectionView.fixture(id: "1")]
        XCTAssertEqual(state.multipleCollectionsDisplayButtonTitle, Localizations.showMore)
    }

    /// `getter:multipleCollectionsDisplayButtonTitle` returns "Show less" when multiple collections are shown.
    func test_multipleCollectionsDisplayButtonTitle_multiple() throws {
        var state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    collectionIds: ["1", "2"]
                ),
                hasPremium: true
            )
        )
        state.allUserCollections = [
            CollectionView.fixture(id: "1"),
            CollectionView.fixture(id: "2"),
            CollectionView.fixture(id: "3"),
        ]
        state.isShowingMultipleCollections = true
        XCTAssertEqual(state.multipleCollectionsDisplayButtonTitle, Localizations.showLess)
    }

    /// `getter:multipleCollectionsDisplayButtonTitle` returns "" when no collections are shown.
    func test_multipleCollectionsDisplayButtonTitle_empty() throws {
        let state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        XCTAssertEqual(state.multipleCollectionsDisplayButtonTitle, "")
    }

    /// `getter:shouldDisplayFolder` returns `true` when there's a folder and doesn't belong to multiple collections.
    func test_shouldDisplayFolder_trueFolderNoMultipleCollections() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        state.folderName = "Folder"
        XCTAssertTrue(state.shouldDisplayFolder)
    }

    /// `getter:shouldDisplayFolder` returns `true` when there's a folder, belongs to multiple collections
    /// and is showing them.
    func test_shouldDisplayFolder_trueFolderMultipleCollectionsShowing() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(collectionIds: ["1", "2"]), hasPremium: true))
        state.isShowingMultipleCollections = true
        state.folderName = "Folder"
        XCTAssertTrue(state.shouldDisplayFolder)
    }

    /// `getter:shouldDisplayFolder` returns `false` when folder is `nil`.
    func test_shouldDisplayFolder_falseNil() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        state.folderName = nil
        XCTAssertFalse(state.shouldDisplayFolder)
    }

    /// `getter:shouldDisplayFolder` returns `false` when folder is empty.
    func test_shouldDisplayFolder_falseEmptyFolder() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        state.folderName = ""
        XCTAssertFalse(state.shouldDisplayFolder)
    }

    /// `getter:shouldDisplayFolder` returns `false` when there's a folder, belongs to multiple collections
    /// and is not showing them.
    func test_shouldDisplayFolder_falseBelongsMultipleCollectionNotShowing() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(collectionIds: ["1", "2"]), hasPremium: true))
        state.isShowingMultipleCollections = false
        state.folderName = "Folder"
        XCTAssertFalse(state.shouldDisplayFolder)
    }

    /// `getter:shouldDisplayNoFolder` returns `true` when there's no organization, no folder and no collections.
    func test_shouldDisplayNoFolder_true() throws {
        let state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        XCTAssertTrue(state.shouldDisplayNoFolder)
    }

    /// `getter:shouldDisplayNoFolder` returns `false` when cipher belongs to an organization.
    func test_shouldDisplayNoFolder_falseOrganization() throws {
        let state = try XCTUnwrap(CipherItemState(existing: .fixture(organizationId: "1"), hasPremium: true))
        XCTAssertFalse(state.shouldDisplayNoFolder)
    }

    /// `getter:shouldDisplayNoFolder` returns `false` when cipher belongs to a folder.
    func test_shouldDisplayNoFolder_falseFolder() throws {
        let state = try XCTUnwrap(CipherItemState(existing: .fixture(folderId: "1"), hasPremium: true))
        XCTAssertFalse(state.shouldDisplayNoFolder)
    }

    /// `getter:shouldDisplayNoFolder` returns `false` when cipher belongs to a collection.
    func test_shouldDisplayNoFolder_falseCollections() throws {
        let state = try XCTUnwrap(CipherItemState(existing: .fixture(collectionIds: ["1"]), hasPremium: true))
        XCTAssertFalse(state.shouldDisplayNoFolder)
    }

    /// `getter:shouldDisplayNoFolder` returns `false` when cipher belongs to an organization, a folder
    /// and a collection.
    func test_shouldDisplayNoFolder_falseBelongsAll() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    collectionIds: ["1"],
                    folderId: "2",
                    organizationId: "3"
                ),
                hasPremium: true
            )
        )
        XCTAssertFalse(state.shouldDisplayNoFolder)
    }

    /// `getter:shouldUseCustomPlaceholderContent` returns `false` when cipher is card and its brand is not `.other`.
    func test_shouldUseCustomPlaceholderContent_false() throws {
        let brandValues = CardComponent.Brand.allCases.filter { $0 != .other }
        for brand in brandValues {
            let state = try XCTUnwrap(
                CipherItemState(
                    existing: .fixture(
                        card: .fixture(brand: brand.rawValue),
                        type: .card
                    ),
                    hasPremium: true
                )
            )
            XCTAssertFalse(state.shouldUseCustomPlaceholderContent)
        }
    }

    /// `getter:shouldUseCustomPlaceholderContent` returns `true` when cipher is card and its brand is `.other`.
    func test_shouldUseCustomPlaceholderContent_trueBrandOther() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    card: .fixture(brand: "Other"),
                    type: .card
                ),
                hasPremium: true
            )
        )
        XCTAssertTrue(state.shouldUseCustomPlaceholderContent)
    }

    /// `getter:shouldUseCustomPlaceholderContent` returns `true` when cipher is card and its brand is not defined.
    func test_shouldUseCustomPlaceholderContent_trueNoBrand() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    card: .fixture(brand: nil),
                    type: .card
                ),
                hasPremium: true
            )
        )
        XCTAssertTrue(state.shouldUseCustomPlaceholderContent)
    }

    /// `getter:shouldUseCustomPlaceholderContent` returns `true` when cipher is card and its brand
    /// can't be converted to a `CardComponent.Brand`.
    func test_shouldUseCustomPlaceholderContent_trueSomethingNotABrand() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    card: .fixture(brand: "something-that-is-not-a-card-brand"),
                    type: .card
                ),
                hasPremium: true
            )
        )
        XCTAssertTrue(state.shouldUseCustomPlaceholderContent)
    }

    /// `getter:shouldUseCustomPlaceholderContent` returns `true` when cipher is not a card
    func test_shouldUseCustomPlaceholderContent_trueNotACard() throws {
        let types: [BitwardenSdk.CipherType] = [.identity, .login, .secureNote, .sshKey]
        for type in types {
            let state = try XCTUnwrap(
                CipherItemState(
                    existing: .fixture(
                        type: type
                    ),
                    hasPremium: true
                )
            )
            XCTAssertTrue(state.shouldUseCustomPlaceholderContent)
        }
    }

    /// `getter:totalHeaderAdditionalItems` returns 0 when cipher doesn't belong to an organzation.
    func test_totalHeaderAdditionalItems_noOrganization() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(),
                hasPremium: true
            )
        )
        XCTAssertEqual(state.totalHeaderAdditionalItems, 0)
    }

    /// `getter:totalHeaderAdditionalItems` returns 1 when cipher belongs to an organzation
    /// but not to collections nor folder.
    func test_totalHeaderAdditionalItems_organizationButNoCollectionNoFolder() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(organizationId: "1"),
                hasPremium: true
            )
        )
        XCTAssertEqual(state.totalHeaderAdditionalItems, 1)
    }

    /// `getter:totalHeaderAdditionalItems` returns 4 when cipher belongs to an organzation
    /// and to 3 collections but not to a folder.
    func test_totalHeaderAdditionalItems_organizationCollectionsNoFolder() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(collectionIds: ["1", "2", "3"], organizationId: "1"),
                hasPremium: true
            )
        )
        XCTAssertEqual(state.totalHeaderAdditionalItems, 4)
    }

    /// `getter:totalHeaderAdditionalItems` returns 5 when cipher belongs to an organzation,
    /// to 3 collections and a folder.
    func test_totalHeaderAdditionalItems_organizationCollectionsFolder() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    collectionIds: ["1", "2", "3"],
                    folderId: "4",
                    organizationId: "1"
                ),
                hasPremium: true
            )
        )
        XCTAssertEqual(state.totalHeaderAdditionalItems, 5)
    }

    /// `getter:totalHeaderAdditionalItems` returns 2 when cipher belongs to an organzation,
    /// no collections and a folder.
    func test_totalHeaderAdditionalItems_organizationFolderAndNoCollections() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    folderId: "4",
                    organizationId: "1"
                ),
                hasPremium: true
            )
        )
        XCTAssertEqual(state.totalHeaderAdditionalItems, 2)
    }
}
