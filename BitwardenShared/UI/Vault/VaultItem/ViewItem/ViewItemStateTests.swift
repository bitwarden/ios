import XCTest

@testable import BitwardenShared

// MARK: - ViewItemStateTests

class ViewItemStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `canClone` is true when the cipher belongs to user but not organization.
    func test_canClone() {
        let subject = ViewItemState(
            loadingState: .data(
                CipherItemState(
                    existing: .fixture(
                        id: "id",
                        reprompt: .password
                    ),
                    hasPremium: true
                )!
            ),
            hasVerifiedMasterPassword: false
        )
        XCTAssertTrue(subject.canClone)
    }

    /// `canClone` is false when the cipher belongs to an organization.
    func test_canClone_cipher_belongToOrg() {
        let subject = ViewItemState(
            loadingState: .data(
                CipherItemState(
                    existing: .fixture(
                        id: "id",
                        organizationId: "1234123",
                        reprompt: .password
                    ),
                    hasPremium: true
                )!
            ),
            hasVerifiedMasterPassword: false
        )
        XCTAssertFalse(subject.canClone)
    }

    /// `isMasterPasswordRequired` is false when the user has no password.
    func test_isMasterPasswordRequired_repromptOff_noPassword() {
        let subject = ViewItemState(
            loadingState: .data(
                CipherItemState(
                    existing: .fixture(
                        id: "id",
                        reprompt: .password
                    ),
                    hasPremium: true
                )!
            ),
            hasMasterPassword: false,
            hasVerifiedMasterPassword: false
        )
        XCTAssertFalse(subject.isMasterPasswordRequired)
    }

    /// `isMasterPasswordRequired` is true when the reprompt is on and the master password has not
    /// been verified yet.
    func test_isMasterPasswordRequired_repromptOn_unverifiedPassword() {
        let subject = ViewItemState(
            loadingState: .data(
                CipherItemState(
                    existing: .fixture(
                        id: "id",
                        reprompt: .password
                    ),
                    hasPremium: true
                )!
            ),
            hasVerifiedMasterPassword: false
        )
        XCTAssertTrue(subject.isMasterPasswordRequired)
    }

    /// `isMasterPasswordRequired` is false when the reprompt is on and the master password has been
    /// verified.
    func test_isMasterPasswordRequired_repromptOn_verifiedPassword() {
        let subject = ViewItemState(
            loadingState: .data(
                CipherItemState(
                    existing: .fixture(
                        id: "id",
                        reprompt: .password
                    ),
                    hasPremium: true
                )!
            ),
            hasVerifiedMasterPassword: true
        )
        XCTAssertFalse(subject.isMasterPasswordRequired)
    }

    /// `isMasterPasswordRequired` is false when the reprompt is off and the master password has not
    /// been verified yet.
    func test_isMasterPasswordRequired_repromptOff_unverifiedPassword() {
        let subject = ViewItemState(
            loadingState: .data(
                CipherItemState(
                    existing: .fixture(
                        id: "id",
                        reprompt: .none
                    ),
                    hasPremium: true
                )!
            ),
            hasVerifiedMasterPassword: false
        )
        XCTAssertFalse(subject.isMasterPasswordRequired)
    }

    /// `isMasterPasswordRequired` is false when the reprompt is off and the master password has
    /// been verified.
    func test_isMasterPasswordRequired_repromptOff_verifiedPassword() {
        let subject = ViewItemState(
            loadingState: .data(
                CipherItemState(
                    existing: .fixture(
                        id: "id",
                        reprompt: .none
                    ),
                    hasPremium: true
                )!
            ),
            hasVerifiedMasterPassword: true
        )
        XCTAssertFalse(subject.isMasterPasswordRequired)
    }
}
