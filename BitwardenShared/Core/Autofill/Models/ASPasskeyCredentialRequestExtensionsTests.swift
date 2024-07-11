import AuthenticationServices
import BitwardenSdk
import XCTest

@testable import BitwardenShared

@available(iOS 17.0, *)
class ASPasskeyCredentialRequestExtensionsTests: BitwardenTestCase { // swiftlint:disable:this type_name
    // MARK: Tests

    /// `getPublicKeyCredentialParams` returns ES256 and RS256 when
    /// supported algorithms is empty.
    func test_getPublicKeyCredentialParams_empty() throws {
        let subject = ASPasskeyCredentialRequest(
            credentialIdentity: .fixture(),
            clientDataHash: Data(capacity: 16),
            userVerificationPreference: .discouraged,
            supportedAlgorithms: [ASCOSEAlgorithmIdentifier]([])
        )
        let result = subject.getPublicKeyCredentialParams()
        XCTAssert(result.count == 2)
        XCTAssert(result.allSatisfy { $0.ty == "public-key" })
        XCTAssert(result[0].alg == PublicKeyCredentialParameters.es256Algorithm)
        XCTAssert(result[1].alg == PublicKeyCredentialParameters.rs256Algorithm)
    }

    /// `getPublicKeyCredentialParams` returns ES256 when
    /// supported algorithms contains ES256.
    func test_getPublicKeyCredentialParams_es256() throws {
        let subject = ASPasskeyCredentialRequest(
            credentialIdentity: .fixture(),
            clientDataHash: Data(capacity: 16),
            userVerificationPreference: .discouraged,
            supportedAlgorithms: [
                ASCOSEAlgorithmIdentifier(rawValue: -257),
                ASCOSEAlgorithmIdentifier.ES256,
                ASCOSEAlgorithmIdentifier(rawValue: 0),
            ]
        )
        let result = subject.getPublicKeyCredentialParams()
        XCTAssert(result.count == 1)
        XCTAssert(result.allSatisfy { $0.ty == "public-key" })
        XCTAssert(result[0].alg == PublicKeyCredentialParameters.es256Algorithm)
    }

    /// `getPublicKeyCredentialParams` returns empty when
    /// supported algorithms is not empty but doesn't contain ES256.
    func test_getPublicKeyCredentialParams_noES256() throws {
        let subject = ASPasskeyCredentialRequest(
            credentialIdentity: .fixture(),
            clientDataHash: Data(capacity: 16),
            userVerificationPreference: .discouraged,
            supportedAlgorithms: [ASCOSEAlgorithmIdentifier(rawValue: 0)]
        )
        let result = subject.getPublicKeyCredentialParams()
        XCTAssertTrue(result.isEmpty)
    }
}
