#if DEBUG
import BitwardenSdk
import Foundation
import XCTest

@testable import BitwardenShared

class Fido2DebuggingUtilsTests: BitwardenTestCase {
    // MARK: Tests

    /// `static describeAuthDataFlags(_:)` returns the formatted string successfully for the flags.
    func test_describeAuthDataFlags() {
        var authData: [UInt8] = []
        // add some 32 bytes
        let firstPart = Data((0 ..< 32).map { _ in 1 })
        authData.append(contentsOf: firstPart)
        authData.append(217)

        let result = Fido2DebuggingUtils.describeAuthDataFlags(Data(authData))
        XCTAssertEqual(result, "Flags: UP: 1 - UV: 0 - BE: 1 - BS: 1 - AD: 1 - ED: 1")
    }

    /// `static describe(request:)` returns a string with the formatted description of the request
    /// when optionals are not filled.
    func test_describe_makeCredentialRequest_withoutOptionals() {
        let request = MakeCredentialRequest(
            clientDataHash: Data((0 ..< 32).map { _ in 1 }),
            rp: PublicKeyCredentialRpEntity(id: "someApp.com", name: nil),
            user: PublicKeyCredentialUserEntity(
                id: Data((0 ..< 32).map { _ in 1 }),
                displayName: "userDisplay",
                name: "user"
            ),
            pubKeyCredParams: [PublicKeyCredentialParameters(ty: "public-key", alg: -7)],
            excludeList: nil,
            options: Options(rk: true, uv: .preferred),
            extensions: nil
        )

        // swiftlint:disable:next line_length
        let expectedResult = "ClientDataHash: 0101010101010101010101010101010101010101010101010101010101010101\nRP -> Id: someApp.com \nRP -> Name: nil \nUser -> Id: 0101010101010101010101010101010101010101010101010101010101010101\nUser -> Name: user \nUser -> DisplayName: userDisplay \nPubKeyCredParams: [BitwardenSdk.PublicKeyCredentialParameters(ty: \"public-key\", alg: -7)]\nExcludeList: nil \nOptions -> RK: true \nOptions -> UV: preferred\nExtensions: nil \n"

        let result = Fido2DebuggingUtils.describe(request: request)
        XCTAssertEqual(result, expectedResult)
    }

    /// `static describe(request:)` returns a string with the formatted description of the request
    /// when everything is filled
    func test_describe_makeCredentialRequest_full() {
        let request = MakeCredentialRequest(
            clientDataHash: Data((0 ..< 32).map { _ in 1 }),
            rp: PublicKeyCredentialRpEntity(id: "someApp.com", name: "App name"),
            user: PublicKeyCredentialUserEntity(
                id: Data((0 ..< 32).map { _ in 1 }),
                displayName: "userDisplay",
                name: "user"
            ),
            pubKeyCredParams: [PublicKeyCredentialParameters(ty: "public-key", alg: -7)],
            excludeList: [
                PublicKeyCredentialDescriptor(
                    ty: "public-key",
                    id: Data((0 ..< 32).map { _ in 1 }),
                    transports: ["transport"]
                ),
            ],
            options: Options(rk: true, uv: .preferred),
            extensions: "some extension"
        )

        // swiftlint:disable:next line_length
        let expectedResult = "ClientDataHash: 0101010101010101010101010101010101010101010101010101010101010101\nRP -> Id: someApp.com \nRP -> Name: App name \nUser -> Id: 0101010101010101010101010101010101010101010101010101010101010101\nUser -> Name: user \nUser -> DisplayName: userDisplay \nPubKeyCredParams: [BitwardenSdk.PublicKeyCredentialParameters(ty: \"public-key\", alg: -7)]\nExcludeList: [BitwardenSdk.PublicKeyCredentialDescriptor(ty: \"public-key\", id: 32 bytes, transports: Optional([\"transport\"]))] \nOptions -> RK: true \nOptions -> UV: preferred\nExtensions: some extension \n"

        let result = Fido2DebuggingUtils.describe(request: request)
        XCTAssertEqual(result, expectedResult)
    }

    /// `static describe(result:)` returns a string with the formatted description of the result.
    func test_describe_makeCredentialResult() {
        let makeCredentialMocker = MakeCredentialResult(
            authenticatorData: Data((0 ..< 40).map { _ in 1 }),
            attestationObject: Data((0 ..< 50).map { _ in 2 }),
            credentialId: Data((0 ..< 32).map { _ in 3 })
        )

        // swiftlint:disable:next line_length
        let expectedResultDescription = "CredentialId: 0303030303030303030303030303030303030303030303030303030303030303\nAuthenticatorData: 01010101010101010101010101010101010101010101010101010101010101010101010101010101\nAttestationObject: 0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202\n"

        let resultDescription = Fido2DebuggingUtils.describe(result: makeCredentialMocker)
        XCTAssertEqual(resultDescription, expectedResultDescription)
    }
}
#endif
