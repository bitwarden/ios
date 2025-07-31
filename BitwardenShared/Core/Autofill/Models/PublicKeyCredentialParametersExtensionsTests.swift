import BitwardenSdk
import XCTest

@testable import BitwardenShared

class PublicKeyCredentialParametersExtensionsTests: BitwardenTestCase {
    let publicKeyType = "public-key"

    // MARK: Tests

    /// `es256Algorithm` returns -7.
    func test_es256Algorithm() throws {
        XCTAssertEqual(PublicKeyCredentialParameters.es256Algorithm, -7)
    }

    /// `rs256Algorithm` returns -257.
    func test_rs256Algorithm() throws {
        XCTAssertEqual(PublicKeyCredentialParameters.rs256Algorithm, -257)
    }

    /// `static es256()` returns an object with "public-key" and ES256 algorithm (-7).
    func test_es256() throws {
        let result = PublicKeyCredentialParameters.es256()
        XCTAssertEqual(result.ty, publicKeyType)
        XCTAssertEqual(result.alg, -7)
    }

    /// `static rs256()` returns an object with "public-key" and RS256 algorithm (-257).
    func test_rs256() throws {
        let result = PublicKeyCredentialParameters.rs256()
        XCTAssertEqual(result.ty, publicKeyType)
        XCTAssertEqual(result.alg, -257)
    }
}
