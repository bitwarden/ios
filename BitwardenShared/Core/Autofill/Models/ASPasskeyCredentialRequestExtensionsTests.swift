import AuthenticationServices
import BitwardenKit
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class ASPasskeyCredentialRequestExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `excludedCredentialsList()` gets the excluded credential list using the
    /// `PublicKeyCredentialDescriptor`.
    func test_excludedCredentialsList() throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("Skipped on iOS < 17.0")
        }
        let data = Data(repeating: 2, count: 16)
        let request = MockASPasskeyCredentialRequest(
            credentialIdentity: .fixture(),
            clientDataHash: Data(capacity: 16),
            userVerificationPreference: .preferred,
            supportedAlgorithms: [-7]
        )
        request.setExcludedCredentials([
            ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: data),
        ])
        let excludedList = request.excludedCredentialsList()
        guard #available(iOS 18.0, *) else {
            XCTAssertNil(excludedList)
            return
        }
        XCTAssertEqual(excludedList?.count, 1)

        let excludedCredential = try XCTUnwrap(excludedList?.first)
        XCTAssertEqual(excludedCredential.id, data)
        XCTAssertEqual(excludedCredential.ty, Constants.defaultFido2PublicKeyCredentialType)
        XCTAssertNil(excludedCredential.transports)
    }

    /// `excludedCredentialsList()` returns `nil` when the request excluded credentials are empty.
    func test_excludedCredentialsList_nilWhenEmpty() throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("Skipped on iOS < 17.0")
        }
        let request = MockASPasskeyCredentialRequest(
            credentialIdentity: .fixture(),
            clientDataHash: Data(capacity: 16),
            userVerificationPreference: .preferred,
            supportedAlgorithms: [-7]
        )
        request.setExcludedCredentials([])
        let excludedList = request.excludedCredentialsList()
        XCTAssertNil(excludedList)
    }

    /// `excludedCredentialsList()` returns `nil` when the request excluded credentials are `nil`.
    func test_excludedCredentialsList_nilWhenNil() throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("Skipped on iOS < 17.0")
        }
        let request = MockASPasskeyCredentialRequest(
            credentialIdentity: .fixture(),
            clientDataHash: Data(capacity: 16),
            userVerificationPreference: .preferred,
            supportedAlgorithms: [-7]
        )
        request.setExcludedCredentials(nil)
        let excludedList = request.excludedCredentialsList()
        XCTAssertNil(excludedList)
    }

    /// `getPublicKeyCredentialParams` returns ES256 and RS256 when
    /// supported algorithms is empty.
    func test_getPublicKeyCredentialParams_empty() throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("Skipped on iOS < 17.0")
        }
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
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("Skipped on iOS < 17.0")
        }
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
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("Skipped on iOS < 17.0")
        }
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
