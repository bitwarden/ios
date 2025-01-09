import BitwardenSdk
import Foundation
import XCTest

@testable import BitwardenShared

class CipherItemStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(cloneItem: hasPremium)` returns a cloned CipherItemState.
    func test_init_clone() {
        let cipher = CipherView.loginFixture(login: .fixture(fido2Credentials: [.fixture()]))
        let state = CipherItemState(cloneItem: cipher, hasPremium: true)
        XCTAssertEqual(state.name, "\(cipher.name) - \(Localizations.clone)")
        XCTAssertNil(state.cipher.id)
        XCTAssertEqual(state.accountHasPremium, true)
        XCTAssertEqual(state.allowTypeSelection, false)
        XCTAssertEqual(state.cardItemState, cipher.cardItemState())
        XCTAssertEqual(state.configuration, .add)
        XCTAssertEqual(state.customFieldsState, .init(cipherType: .login, customFields: cipher.customFields))
        XCTAssertEqual(state.folderId, cipher.folderId)
        XCTAssertEqual(state.identityState, cipher.identityItemState())
        XCTAssertEqual(state.isFavoriteOn, cipher.favorite)
        XCTAssertEqual(state.isMasterPasswordRePromptOn, cipher.reprompt == .password)
        XCTAssertEqual(state.loginState, cipher.loginItemState(excludeFido2Credentials: true, showTOTP: true))
        XCTAssertTrue(state.loginState.fido2Credentials.isEmpty)
        XCTAssertEqual(state.notes, cipher.notes ?? "")
        XCTAssertEqual(state.sshKeyState, cipher.sshKeyItemState())
        XCTAssertEqual(state.type, .init(type: cipher.type))
        XCTAssertEqual(state.updatedDate, cipher.revisionDate)
    }

    /// `init(existing:hasPremium:)` sets `loginState.isTOTPAvailable` to false if the user doesn't
    /// have premium and the organization doesn't use TOTP.
    func test_init_existing_isTOTPAvailable_notAvailable() throws {
        let cipher = CipherView.loginFixture(login: .fixture())
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: false))
        XCTAssertFalse(state.loginState.isTOTPAvailable)
    }

    /// `init(existing:hasPremium:)` sets `loginState.isTOTPAvailable` to true if the user has premium.
    func test_init_existing_isTOTPAvailable_premium() throws {
        let cipher = CipherView.loginFixture(login: .fixture())
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.loginState.isTOTPAvailable)
    }

    /// `init(existing:hasPremium:)` sets `loginState.isTOTPAvailable` to true if the organization uses TOTP.
    func test_init_existing_isTOTPAvailable_organizationUseTotp() throws {
        let cipher = CipherView.loginFixture(login: .fixture(), organizationUseTotp: true)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: false))
        XCTAssertTrue(state.loginState.isTOTPAvailable)
    }

    /// `canBeDeleted` is true
    /// if the cipher does not belong to a collection
    func test_canBeDeleted_notCollection() throws {
        let cipher = CipherView.loginFixture(login: .fixture())
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.canBeDeleted)

        state.collections = [CollectionView.fixture()]
        XCTAssertTrue(state.canBeDeleted)
    }

    /// `canBeDeleted` is true
    ///  if the cipher belongs to a collection
    ///  and the user has manage permissions for that collection
    func test_canBeDeleted_canManageOneCollection() throws {
        let cipher = CipherView.loginFixture(collectionIds: ["1"], login: .fixture())
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.collections = [CollectionView.fixture(id: "1", manage: true)]
        XCTAssertTrue(state.canBeDeleted)
    }

    /// `canBeDeleted` is false
    /// if the cipher belongs to a collection
    /// and the user does not have manage permissions for that collection
    func test_canBeDeleted_cannotManageOneCollection() throws {
        let cipher = CipherView.loginFixture(collectionIds: ["1"], login: .fixture())
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.collections = [CollectionView.fixture(id: "1", manage: false)]
        XCTAssertFalse(state.canBeDeleted)
    }

    /// `canBeDeleted` is false
    /// if the cipher belongs to multiple collections
    /// and the user does not have manage permissions for any of those collections
    func test_canBeDeleted_cannotManageAnyCollection() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: ["1", "2"],
            login: .fixture()
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.collections = [
            CollectionView.fixture(id: "1", manage: false),
            CollectionView.fixture(id: "2", manage: false),
        ]
        XCTAssertFalse(state.canBeDeleted)
    }

    /// `canBeDeleted` is true
    /// if the cipher belongs to multiple collections
    /// and the user has manage permissions for any of those collections
    func test_canBeDeleted_canManageAnyCollection() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: ["1", "2"],
            login: .fixture()
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.collections = [
            CollectionView.fixture(id: "1", manage: true),
            CollectionView.fixture(id: "2", manage: false),
        ]
        XCTAssertTrue(state.canBeDeleted)
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
        state.collections = [
            CollectionView.fixture(id: "1", organizationId: "Org1", manage: true, readOnly: false),
            CollectionView.fixture(id: "2", organizationId: "Org1", manage: false, readOnly: false),
            CollectionView.fixture(id: "3", organizationId: "Org1", manage: false, readOnly: true),
        ]
        XCTAssertEqual(state.collectionsForOwner.map(\.id), ["1", "2"])
    }

    /// `shouldShowLearnNewLoginActionCard` should be `true`, if the cipher is a login type and configuration is `.add`.
    func test_shouldShowLearnNewLoginActionCard_True() {
        let cipher = CipherView.loginFixture(login: .fixture(fido2Credentials: [.fixture()]))
        var state = CipherItemState(cloneItem: cipher, hasPremium: true)
        state.isLearnNewLoginActionCardEligible = true
        XCTAssertTrue(state.shouldShowLearnNewLoginActionCard)
    }

    /// `shouldShowLearnNewLoginActionCard` should be `false`, if the cipher is not a login type.
    func test_shouldShowLearnNewLoginActionCard_False() {
        let cipher = CipherView.cardFixture(card: .fixture(
            code: "123",
            number: "123456789"
        ))
        var state = CipherItemState(cloneItem: cipher, hasPremium: true)
        state.isLearnNewLoginActionCardEligible = true
        XCTAssertFalse(state.shouldShowLearnNewLoginActionCard)
    }

    /// `shouldShowLearnNewLoginActionCard` should be `false`, if the configuration is not `.add`.
    func test_shouldShowLearnNewLoginActionCard_False_Config() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: ["1", "2"],
            login: .fixture()
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.isLearnNewLoginActionCardEligible = true
        XCTAssertFalse(state.shouldShowLearnNewLoginActionCard)
    }
}
