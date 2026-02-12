// swiftlint:disable:this file_name

import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - WrappedAccountCryptographicStateExtensionsTests

class WrappedAccountCryptographicStateExtensionsTests: BitwardenTestCase {
    // MARK: Properties

    let privateKey = "test-private-key"
    let securityState = "test-security-state"
    let signingKey = "test-signing-key"
    let signedPublicKey = "test-signed-public-key"

    // MARK: Tests

    /// `create(privateKey:securityState:signingKey:signedPublicKey:)` returns V2 when
    /// securityState, signedPublicKey and signingKey are non-nil.
    func test_create_returnsV2_whenAllV2ParametersAreNonNull() {
        let result = WrappedAccountCryptographicState.create(
            privateKey: privateKey,
            securityState: securityState,
            signedPublicKey: signedPublicKey,
            signingKey: signingKey,
        )

        guard case let .v2(
            resultPrivateKey,
            resultSignedPublicKey,
            resultSigningKey,
            resultSecurityState,
        ) = result else {
            XCTFail("Expected V2 state")
            return
        }

        XCTAssertEqual(privateKey, resultPrivateKey)
        XCTAssertEqual(signedPublicKey, resultSignedPublicKey)
        XCTAssertEqual(signingKey, resultSigningKey)
        XCTAssertEqual(securityState, resultSecurityState)
    }

    /// `create(privateKey:securityState:signingKey:signedPublicKey:)` returns V1 when securityState is nil.
    func test_create_returnsV1_whenSecurityStateIsNull() {
        let result = WrappedAccountCryptographicState.create(
            privateKey: privateKey,
            securityState: nil,
            signedPublicKey: signedPublicKey,
            signingKey: signingKey,
        )

        guard case let .v1(resultPrivateKey) = result else {
            XCTFail("Expected V1 state")
            return
        }

        XCTAssertEqual(privateKey, resultPrivateKey)
    }

    /// `create(privateKey:securityState:signingKey:signedPublicKey:)` returns V1 when signedPublicKey is nil.
    func test_create_returnsV1_whenSignedPublicKeyIsNull() {
        let result = WrappedAccountCryptographicState.create(
            privateKey: privateKey,
            securityState: securityState,
            signedPublicKey: nil,
            signingKey: signingKey,
        )

        guard case let .v1(resultPrivateKey) = result else {
            XCTFail("Expected V1 state")
            return
        }

        XCTAssertEqual(privateKey, resultPrivateKey)
    }

    /// `create(privateKey:securityState:signingKey:signedPublicKey:)` returns V1 when signingKey is nil.
    func test_create_returnsV1_whenSigningKeyIsNull() {
        let result = WrappedAccountCryptographicState.create(
            privateKey: privateKey,
            securityState: securityState,
            signedPublicKey: signedPublicKey,
            signingKey: nil,
        )

        guard case let .v1(resultPrivateKey) = result else {
            XCTFail("Expected V1 state")
            return
        }

        XCTAssertEqual(privateKey, resultPrivateKey)
    }

    /// `create(privateKey:securityState:signingKey:signedPublicKey:)` returns V1 when
    /// both securityState and signedPublicKey are nil.
    func test_create_returnsV1_whenSecurityStateAndSignedPublicKeyAreNull() {
        let result = WrappedAccountCryptographicState.create(
            privateKey: privateKey,
            securityState: nil,
            signedPublicKey: nil,
            signingKey: signingKey,
        )

        guard case let .v1(resultPrivateKey) = result else {
            XCTFail("Expected V1 state")
            return
        }

        XCTAssertEqual(privateKey, resultPrivateKey)
    }

    /// `create(privateKey:securityState:signingKey:signedPublicKey:)` returns V1 when
    /// both securityState and signingKey are nil.
    func test_create_returnsV1_whenSecurityStateAndSigningKeyAreNull() {
        let result = WrappedAccountCryptographicState.create(
            privateKey: privateKey,
            securityState: nil,
            signedPublicKey: signedPublicKey,
            signingKey: nil,
        )

        guard case let .v1(resultPrivateKey) = result else {
            XCTFail("Expected V1 state")
            return
        }

        XCTAssertEqual(privateKey, resultPrivateKey)
    }

    /// `create(privateKey:securityState:signingKey:signedPublicKey:)` returns V1 when
    /// both signedPublicKey and signingKey are nil.
    func test_create_returnsV1_whenSignedPublicKeyAndSigningKeyAreNull() {
        let result = WrappedAccountCryptographicState.create(
            privateKey: privateKey,
            securityState: securityState,
            signedPublicKey: nil,
            signingKey: nil,
        )

        guard case let .v1(resultPrivateKey) = result else {
            XCTFail("Expected V1 state")
            return
        }

        XCTAssertEqual(privateKey, resultPrivateKey)
    }
}
