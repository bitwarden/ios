import AuthenticationServices
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class ASAuthorizationPublicKeyCredentialUserVerificationPreferenceTests: BitwardenTestCase { // swiftlint:disable:this line_length type_name
    // MARK: Tests

    /// `toSdkUserVerificationPreference` discouraged maps.
    func test_toSdkUserVerificationPreference_discouraged() throws {
        XCTAssertEqual(
            ASAuthorizationPublicKeyCredentialUserVerificationPreference.discouraged.toSdkUserVerificationPreference(),
            Uv.discouraged
        )
    }

    /// `toSdkUserVerificationPreference` preferred maps.
    func test_toSdkUserVerificationPreference_preferred() throws {
        XCTAssertEqual(
            ASAuthorizationPublicKeyCredentialUserVerificationPreference.preferred.toSdkUserVerificationPreference(),
            Uv.preferred
        )
    }

    /// `toSdkUserVerificationPreference` required maps.
    func test_toSdkUserVerificationPreference_required() throws {
        XCTAssertEqual(
            ASAuthorizationPublicKeyCredentialUserVerificationPreference.required.toSdkUserVerificationPreference(),
            Uv.required
        )
    }

    /// `toSdkUserVerificationPreference` with unknown AS preference maps to required.
    func test_toSdkUserVerificationPreference_unknown() throws {
        XCTAssertEqual(
            ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: "unknown value")
                .toSdkUserVerificationPreference(),
            Uv.required
        )
    }
}
