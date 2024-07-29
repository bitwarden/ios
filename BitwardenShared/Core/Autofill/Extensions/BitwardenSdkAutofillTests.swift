// swiftlint:disable:this file_name

import AuthenticationServices
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - GetAssertionRequest

class GetAssertionRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(fido2RequestParameters:)` initializes correctly
    func test_init_fido2RequestParameters() {
        let allowedCredentials = [
            Data(repeating: 2, count: 32),
            Data(repeating: 5, count: 32),
        ]
        let passkeyParameters = MockPasskeyCredentialRequestParameters(allowedCredentials: allowedCredentials)

        let request = GetAssertionRequest(fido2RequestParameters: passkeyParameters)

        XCTAssertEqual(request.clientDataHash, passkeyParameters.clientDataHash)
        XCTAssertEqual(request.rpId, passkeyParameters.relyingPartyIdentifier)
        XCTAssertFalse(request.options.rk)
        XCTAssertEqual(request.options.uv, .preferred)
        XCTAssertNil(request.extensions)
        XCTAssertEqual(
            request.allowList,
            allowedCredentials.map { credentialId in
                PublicKeyCredentialDescriptor(
                    ty: "public-key",
                    id: credentialId,
                    transports: nil
                )
            }
        )
    }

    /// `init(passkeyRequest:credentialIdentity:)` initializes correctly
    @available(iOS 17.0, *)
    func test_init_passkeyRequest_credentialIdentity() {
        let passkeyRequest = ASPasskeyCredentialRequest.fixture()
        guard let credentialIdentity = passkeyRequest.credentialIdentity as? ASPasskeyCredentialIdentity else {
            XCTFail("Credential identity is not ASPasskeyCredentialIdentity.")
            return
        }

        let request = GetAssertionRequest(passkeyRequest: passkeyRequest, credentialIdentity: credentialIdentity)

        XCTAssertEqual(request.clientDataHash, passkeyRequest.clientDataHash)
        XCTAssertEqual(request.rpId, credentialIdentity.relyingPartyIdentifier)
        XCTAssertFalse(request.options.rk)
        XCTAssertEqual(request.options.uv, .discouraged)
        XCTAssertNil(request.extensions)
        XCTAssertEqual(
            request.allowList,
            [
                PublicKeyCredentialDescriptor(
                    ty: "public-key",
                    id: credentialIdentity.credentialID,
                    transports: nil
                ),
            ]
        )
    }
}

// MARK: - MakeCredentialRequestTests

class MakeCredentialRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `debugDescription()` returns a string with the formatted description of the request
    /// when optionals are not filled.
    func test_debugDescription_withoutOptionals() {
        let request = MakeCredentialRequest(
            clientDataHash: Data(repeating: 1, count: 32),
            rp: PublicKeyCredentialRpEntity(id: "someApp.com", name: nil),
            user: PublicKeyCredentialUserEntity(
                id: Data(repeating: 1, count: 32),
                displayName: "userDisplay",
                name: "user"
            ),
            pubKeyCredParams: [PublicKeyCredentialParameters(ty: "public-key", alg: -7)],
            excludeList: nil,
            options: Options(rk: true, uv: .preferred),
            extensions: nil
        )

        let expectedResult =
            """
            ClientDataHash: 0101010101010101010101010101010101010101010101010101010101010101
            RP -> Id: someApp.com
            RP -> Name: nil
            User -> Id: 0101010101010101010101010101010101010101010101010101010101010101
            User -> Name: user
            User -> DisplayName: userDisplay
            PubKeyCredParams: [BitwardenSdk.PublicKeyCredentialParameters(ty: "public-key", alg: -7)]
            ExcludeList: nil
            Options -> RK: true
            Options -> UV: preferred
            Extensions: nil
            """

        XCTAssertEqual(String(reflecting: request), expectedResult)
    }

    /// `debugDescription()` returns a string with the formatted description of the request
    /// when everything is filled
    func test_debugDescription_full() {
        let request = MakeCredentialRequest(
            clientDataHash: Data(repeating: 1, count: 32),
            rp: PublicKeyCredentialRpEntity(id: "someApp.com", name: "App name"),
            user: PublicKeyCredentialUserEntity(
                id: Data(repeating: 1, count: 32),
                displayName: "userDisplay",
                name: "user"
            ),
            pubKeyCredParams: [PublicKeyCredentialParameters(ty: "public-key", alg: -7)],
            excludeList: [
                PublicKeyCredentialDescriptor(
                    ty: "public-key",
                    id: Data(repeating: 1, count: 32),
                    transports: ["transport"]
                ),
            ],
            options: Options(rk: true, uv: .preferred),
            extensions: "some extension"
        )

        // swiftlint:disable line_length
        let expectedResult =
            """
            ClientDataHash: 0101010101010101010101010101010101010101010101010101010101010101
            RP -> Id: someApp.com
            RP -> Name: App name
            User -> Id: 0101010101010101010101010101010101010101010101010101010101010101
            User -> Name: user
            User -> DisplayName: userDisplay
            PubKeyCredParams: [BitwardenSdk.PublicKeyCredentialParameters(ty: \"public-key\", alg: -7)]
            ExcludeList: [BitwardenSdk.PublicKeyCredentialDescriptor(ty: \"public-key\", id: 32 bytes, transports: Optional([\"transport\"]))]
            Options -> RK: true
            Options -> UV: preferred
            Extensions: some extension
            """
        // swiftlint:enable line_length

        XCTAssertEqual(String(reflecting: request), expectedResult)
    }
}

// MARK: - MakeCredentialResultTests

class MakeCredentialResultTests: BitwardenTestCase {
    // MARK: Tests

    /// `debugDescription()` returns a string with the formatted description of the result.
    func test_debugDescription() {
        let result = MakeCredentialResult(
            authenticatorData: Data(repeating: 1, count: 40),
            attestationObject: Data(repeating: 2, count: 42),
            credentialId: Data(repeating: 3, count: 32)
        )

        let expectedResult =
            """
            AuthenticatorData: 01010101010101010101010101010101010101010101010101010101010101010101010101010101
            AttestationObject: 020202020202020202020202020202020202020202020202020202020202020202020202020202020202
            CredentialId: 0303030303030303030303030303030303030303030303030303030303030303
            """

        XCTAssertEqual(String(reflecting: result), expectedResult)
    }
}

// MARK: - UvTests

class UvTests: BitwardenTestCase {
    // MARK: Tests

    /// `init` discouraged maps.
    func test_init_discouraged() throws {
        XCTAssertEqual(
            Uv(preference: ASAuthorizationPublicKeyCredentialUserVerificationPreference.discouraged),
            Uv.discouraged
        )
    }

    /// `init` preferred maps.
    func test_init_preferred() throws {
        XCTAssertEqual(
            Uv(preference: ASAuthorizationPublicKeyCredentialUserVerificationPreference.preferred),
            Uv.preferred
        )
    }

    /// `init` required maps.
    func test_init_required() throws {
        XCTAssertEqual(
            Uv(preference: ASAuthorizationPublicKeyCredentialUserVerificationPreference.required),
            Uv.required
        )
    }

    /// `init` with unknown AS preference maps to required.
    func test_init_unknown() throws {
        XCTAssertEqual(
            Uv(preference: ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: "unknown value")),
            Uv.required
        )
    }
}
