import XCTest

@testable import BitwardenShared

class SecretVerificationRequestModelTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(type:)` with `.authRequestAccessCode` sets `authRequestAccessCode`
    /// and nils the other properties.
    func test_init_authRequestAccessCode() {
        let subject = SecretVerificationRequestModel(type: .authRequestAccessCode("ACCESS_CODE"))

        XCTAssertEqual(subject.authRequestAccessCode, "ACCESS_CODE")
        XCTAssertNil(subject.masterPasswordHash)
        XCTAssertNil(subject.otp)
    }

    /// `init(type:)` with `.masterPasswordHash` sets `masterPasswordHash`
    /// and nils the other properties.
    func test_init_masterPasswordHash() {
        let subject = SecretVerificationRequestModel(type: .masterPasswordHash("PASSWORD_HASH"))

        XCTAssertNil(subject.authRequestAccessCode)
        XCTAssertEqual(subject.masterPasswordHash, "PASSWORD_HASH")
        XCTAssertNil(subject.otp)
    }

    /// `init(type:)` with `.otp` sets `otp` and nils the other properties.
    func test_init_otp() {
        let subject = SecretVerificationRequestModel(type: .otp("123456"))

        XCTAssertNil(subject.authRequestAccessCode)
        XCTAssertNil(subject.masterPasswordHash)
        XCTAssertEqual(subject.otp, "123456")
    }
}
