import XCTest

@testable import BitwardenShared

// MARK: - ViewItemStateTests

class ViewItemStateTests: BitwardenTestCase {
    // MARK: Tests

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
                    hasPremium: true,
                    totpTime: .currentTime
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
                    hasPremium: true,
                    totpTime: .currentTime
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
                    hasPremium: true,
                    totpTime: .currentTime
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
                    hasPremium: true,
                    totpTime: .currentTime
                )!
            ),
            hasVerifiedMasterPassword: true
        )
        XCTAssertFalse(subject.isMasterPasswordRequired)
    }
}
