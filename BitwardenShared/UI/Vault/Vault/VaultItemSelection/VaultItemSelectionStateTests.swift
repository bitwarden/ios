import XCTest

@testable import BitwardenShared

class VaultItemSelectionStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `ciphersMatchingName` returns the issuer from an OTPAuth key.
    func test_ciphersMatchingName_issuer() {
        let subject = VaultItemSelectionState(iconBaseURL: nil, totpKeyModel: .fixtureExample)
        XCTAssertEqual(subject.ciphersMatchingName, "Example")
    }

    /// `ciphersMatchingName` returns `nil` when an OTPAuth key has no issuer or account name.
    func test_ciphersMatchingName_minimum() {
        let subject = VaultItemSelectionState(iconBaseURL: nil, totpKeyModel: .fixtureMinimum)
        XCTAssertNil(subject.ciphersMatchingName)
    }

    /// `ciphersMatchingName` returns `nil` when the `totpKeyModel` is based on a standard code type.
    func test_ciphersMatchingName_standard() {
        let subject = VaultItemSelectionState(iconBaseURL: nil,
                                              totpKeyModel: TOTPKeyModel(authenticatorKey: .standardTotpKey))
        XCTAssertNil(subject.ciphersMatchingName)
    }

    /// `ciphersMatchingName` returns `nil` when the `totpKeyModel` is based on a SteamURI code type.
    func test_ciphersMatchingName_steamURI() {
        let subject = VaultItemSelectionState(iconBaseURL: nil,
                                              totpKeyModel: TOTPKeyModel(authenticatorKey: .steamUriKey))
        XCTAssertNil(subject.ciphersMatchingName)
    }
}
