import BitwardenSdk
import Foundation
import XCTest

@testable import BitwardenShared

class CipherItemStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(cloneItem: hasPremium)` returns a cloned CipherItemState.
    func test_init_clone() {
        let cipher = CipherView.loginFixture()
        let state = CipherItemState(cloneItem: cipher, hasPremium: true)
        XCTAssertEqual(state.name, "\(cipher.name) - \(Localizations.clone)")
        XCTAssertNil(state.cipher.id)
        XCTAssertEqual(state.accountHasPremium, true)
        XCTAssertEqual(state.allowTypeSelection, false)
        XCTAssertEqual(state.cardItemState, cipher.cardItemState())
        XCTAssertEqual(state.configuration, .add)
        XCTAssertEqual(state.customFields, cipher.customFields)
        XCTAssertEqual(state.folderId, cipher.folderId)
        XCTAssertEqual(state.identityState, cipher.identityItemState())
        XCTAssertEqual(state.isFavoriteOn, cipher.favorite)
        XCTAssertEqual(state.isMasterPasswordRePromptOn, cipher.reprompt == .password)
        XCTAssertEqual(state.loginState, cipher.loginItemState(showTOTP: true))
        XCTAssertEqual(state.notes, cipher.notes ?? "")
        XCTAssertEqual(state.type, .init(type: cipher.type))
        XCTAssertEqual(state.updatedDate, cipher.revisionDate)
    }
}
