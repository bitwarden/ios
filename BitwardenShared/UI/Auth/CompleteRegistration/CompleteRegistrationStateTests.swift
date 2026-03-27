import XCTest

@testable import BitwardenShared

class CompleteRegistrationStateTests: BitwardenTestCase {
    func test_doesMasterPasswordMatchHint_whenMatching_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordText = "12345678901"
        subject.retypePasswordText = "12345678901"
        subject.passwordHintText = "12345678901"

        XCTAssertFalse(subject.doesMasterPasswordMatchHint)
    }

    func test_doesMasterPasswordMatchHint_whenWhitespaceDifference_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordText = "12345678901"
        subject.retypePasswordText = "12345678901"
        subject.passwordHintText = "12345678901 "

        XCTAssertFalse(subject.doesMasterPasswordMatchHint)
    }

    func test_doesMasterPasswordMatchHint_whenValidHint_returnsTrue() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordText = "12345678901"
        subject.retypePasswordText = "12345678901"
        subject.passwordHintText = "hint"

        XCTAssertFalse(subject.doesMasterPasswordMatchHint)
    }

    func test_isContinueButtonEnabled_whenPasswordEmpty_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordText = ""
        subject.retypePasswordText = ""

        XCTAssertFalse(subject.continueButtonEnabled)
    }

    func test_isContinueButtonEnabled_whenPasswordShort_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordText = "12345678901"
        subject.retypePasswordText = "12345678901"

        XCTAssertFalse(subject.continueButtonEnabled)
    }

    func test_isContinueButtonEnabled_validPassword_returnsTrue() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordText = "123456789012"
        subject.retypePasswordText = "123456789012"

        XCTAssertTrue(subject.continueButtonEnabled)
    }

    func test_isWeakPassword_whenScoreIsNil_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordStrengthScore = nil

        XCTAssertFalse(subject.isWeakPassword)
    }

    func test_isWeakPassword_whenScoreJustBelowThreshold_returnsTrue() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordStrengthScore = 2

        XCTAssertTrue(subject.isWeakPassword)
    }

    func test_isWeakPassword_whenScoreAtThreshold_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordStrengthScore = 3

        XCTAssertFalse(subject.isWeakPassword)
    }

    func test_isWeakPassword_whenScoreAboveThreshold_returnsFalse() {
        var subject = CompleteRegistrationState(
            emailVerificationToken: "",
            userEmail: "email@example.com",
        )

        subject.passwordStrengthScore = 5

        XCTAssertFalse(subject.isWeakPassword)
    }
}
