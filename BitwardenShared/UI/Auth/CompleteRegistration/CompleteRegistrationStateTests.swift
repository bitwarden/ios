import XCTest

@testable import BitwardenShared

class CompleteRegistrationStateTests: BitwardenTestCase {
    /// `doesMasterPasswordMatchHint` returns `true` if the password and hint match.
    func test_doesMasterPasswordMatchHint_whenMatching_returnsTrue() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )
        subject.passwordText = "123456789012"
        subject.retypePasswordText = "123456789012"
        subject.passwordHintText = "123456789012"

        XCTAssertTrue(subject.doesMasterPasswordMatchHint)
    }

    /// `doesMasterPasswordMatchHint` returns `true` if the password and hint match after
    /// trimming whitespace from the hint.
    func test_doesMasterPasswordMatchHint_whenWhitespaceDifference_returnsTrue() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )
        subject.passwordText = "123456789012"
        subject.retypePasswordText = "123456789012"
        subject.passwordHintText = "123456789012 "

        XCTAssertTrue(subject.doesMasterPasswordMatchHint)
    }

    /// `doesMasterPasswordMatchHint` returns `false` if the password and hint do not match.
    func test_doesMasterPasswordMatchHint_whenValidHint_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )
        subject.passwordText = "123456789012"
        subject.retypePasswordText = "123456789012"
        subject.passwordHintText = "hint"

        XCTAssertFalse(subject.doesMasterPasswordMatchHint)
    }

    /// `continueButtonEnabled` returns `false` when password is empty.
    func test_isContinueButtonEnabled_whenPasswordEmpty_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordText = ""
        subject.retypePasswordText = ""

        XCTAssertFalse(subject.continueButtonEnabled)
    }

    /// `continueButtonEnabled` returns `false` when password is too short.
    func test_isContinueButtonEnabled_whenPasswordShort_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordText = "12345678901"
        subject.retypePasswordText = "12345678901"

        XCTAssertFalse(subject.continueButtonEnabled)
    }

    /// `continueButtonEnabled` returns `true` when password is valid .
    func test_isContinueButtonEnabled_validPassword_returnsTrue() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordText = "123456789012"
        subject.retypePasswordText = "123456789012"

        XCTAssertTrue(subject.continueButtonEnabled)
    }

    /// `isWeakPassword` returns `false` when strength score is `nil`.
    func test_isWeakPassword_whenScoreIsNil_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordStrengthScore = nil

        XCTAssertFalse(subject.isWeakPassword)
    }

    /// `isWeakPassword` returns `true` when strength score is below threshold.
    func test_isWeakPassword_whenScoreJustBelowThreshold_returnsTrue() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordStrengthScore = 2

        XCTAssertTrue(subject.isWeakPassword)
    }

    /// `isWeakPassword` returns `false` when strength score is equal to threshold.
    func test_isWeakPassword_whenScoreAtThreshold_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordStrengthScore = 3

        XCTAssertFalse(subject.isWeakPassword)
    }

    /// `isWeakPassword` returns `false` when strength score is above threshold.
    func test_isWeakPassword_whenScoreAboveThreshold_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordStrengthScore = 5

        XCTAssertFalse(subject.isWeakPassword)
    }
}
