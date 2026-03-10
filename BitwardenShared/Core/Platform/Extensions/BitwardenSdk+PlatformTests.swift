// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class BitwardenErrorTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:errorUserInfo` gets the appropriate user info based on the message
    /// of the internal `BitwardenSdk.BitwardenError`.
    func test_errorUserInfo() {
        let expectedMessage = "Crypto(BitwardenSdk.CryptoError.Fingerprint(message: \"internal error\"))"
        let error = BitwardenSdk.BitwardenError.Crypto(CryptoError.Fingerprint(message: "internal error"))
        let nsError = error as NSError
        let userInfo = nsError.userInfo
        XCTAssertEqual(userInfo["SpecificError"] as? String, expectedMessage)
    }
}

// MARK: - AcquiredCookieCodableTests

class AcquiredCookieCodableTests: BitwardenTestCase {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    /// `encode(to:)` produces JSON with `name` and `value` keys.
    func test_encode() throws {
        let cookie = AcquiredCookie(name: "session", value: "abc123")
        let data = try encoder.encode(cookie)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"name\":\"session\""))
        XCTAssertTrue(json.contains("\"value\":\"abc123\""))
    }

    /// `init(from:)` decodes `name` and `value` from JSON.
    func test_decode() throws {
        let json = #"{"name":"session","value":"abc123"}"#.data(using: .utf8)!
        let cookie = try decoder.decode(AcquiredCookie.self, from: json)
        XCTAssertEqual(cookie.name, "session")
        XCTAssertEqual(cookie.value, "abc123")
    }

    /// Encoding then decoding produces an equal value.
    func test_roundTrip() throws {
        let cookie = AcquiredCookie(name: "myName", value: "myValue")
        let data = try encoder.encode(cookie)
        let decoded = try decoder.decode(AcquiredCookie.self, from: data)
        XCTAssertEqual(decoded.name, cookie.name)
        XCTAssertEqual(decoded.value, cookie.value)
    }
}

// MARK: - SsoCookieVendorConfigCodableTests

class SsoCookieVendorConfigCodableTests: BitwardenTestCase {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    /// `encode(to:)` includes all non-nil fields.
    func test_encode_allFields() throws {
        let config = SsoCookieVendorConfig(
            idpLoginUrl: "https://idp.example.com",
            cookieName: "bwauth",
            cookieDomain: "example.com",
            cookieValue: [AcquiredCookie(name: "n", value: "v")],
        )
        let data = try encoder.encode(config)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"idpLoginUrl\""))
        XCTAssertTrue(json.contains("\"cookieName\""))
        XCTAssertTrue(json.contains("\"cookieDomain\""))
        XCTAssertTrue(json.contains("\"cookieValue\""))
    }

    /// `encode(to:)` omits nil fields when using `encodeIfPresent`.
    func test_encode_nilFields() throws {
        let config = SsoCookieVendorConfig(
            idpLoginUrl: nil,
            cookieName: nil,
            cookieDomain: nil,
            cookieValue: nil,
        )
        let data = try encoder.encode(config)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertFalse(json.contains("\"idpLoginUrl\""))
        XCTAssertFalse(json.contains("\"cookieName\""))
        XCTAssertFalse(json.contains("\"cookieDomain\""))
        XCTAssertFalse(json.contains("\"cookieValue\""))
    }

    /// `init(from:)` decodes all fields from JSON.
    func test_decode_allFields() throws {
        let json = """
        {
            "idpLoginUrl": "https://idp.example.com",
            "cookieName": "bwauth",
            "cookieDomain": "example.com",
            "cookieValue": [{"name": "n", "value": "v"}]
        }
        """.data(using: .utf8)!

        let config = try decoder.decode(SsoCookieVendorConfig.self, from: json)

        XCTAssertEqual(config.idpLoginUrl, "https://idp.example.com")
        XCTAssertEqual(config.cookieName, "bwauth")
        XCTAssertEqual(config.cookieDomain, "example.com")
        XCTAssertEqual(config.cookieValue?.first?.name, "n")
        XCTAssertEqual(config.cookieValue?.first?.value, "v")
    }

    /// `init(from:)` sets all optional fields to `nil` when absent from JSON.
    func test_decode_nilFields() throws {
        let json = "{}".data(using: .utf8)!
        let config = try decoder.decode(SsoCookieVendorConfig.self, from: json)
        XCTAssertNil(config.idpLoginUrl)
        XCTAssertNil(config.cookieName)
        XCTAssertNil(config.cookieDomain)
        XCTAssertNil(config.cookieValue)
    }
}

// MARK: - BootstrapConfigCodableTests

class BootstrapConfigCodableTests: BitwardenTestCase {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    /// `encode(to:)` for `.direct` produces `{"type":"direct"}`.
    func test_encode_direct() throws {
        let data = try encoder.encode(BootstrapConfig.direct)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"type\":\"direct\""))
        XCTAssertFalse(json.contains("ssoCookieVendor"))
    }

    /// `encode(to:)` for `.ssoCookieVendor` includes both `type` and `ssoCookieVendor` keys.
    func test_encode_ssoCookieVendor() throws {
        let config = SsoCookieVendorConfig(
            idpLoginUrl: "https://idp.example.com",
            cookieName: nil,
            cookieDomain: nil,
            cookieValue: nil,
        )
        let data = try encoder.encode(BootstrapConfig.ssoCookieVendor(config))
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"type\":\"ssoCookieVendor\""))
        XCTAssertTrue(json.contains("\"ssoCookieVendor\""))
    }

    /// `init(from:)` decodes `{"type":"direct"}` to `.direct`.
    func test_decode_direct() throws {
        let json = #"{"type":"direct"}"#.data(using: .utf8)!
        let config = try decoder.decode(BootstrapConfig.self, from: json)
        if case .direct = config {} else {
            XCTFail("Expected .direct, got \(config)")
        }
    }

    /// `init(from:)` decodes a `ssoCookieVendor` type to `.ssoCookieVendor`.
    func test_decode_ssoCookieVendor() throws {
        let json = """
        {
            "type": "ssoCookieVendor",
            "ssoCookieVendor": {
                "idpLoginUrl": "https://idp.example.com",
                "cookieName": "bwauth",
                "cookieDomain": "example.com"
            }
        }
        """.data(using: .utf8)!

        let config = try decoder.decode(BootstrapConfig.self, from: json)

        guard case let .ssoCookieVendor(vendorConfig) = config else {
            XCTFail("Expected .ssoCookieVendor, got \(config)")
            return
        }
        XCTAssertEqual(vendorConfig.idpLoginUrl, "https://idp.example.com")
        XCTAssertEqual(vendorConfig.cookieName, "bwauth")
        XCTAssertEqual(vendorConfig.cookieDomain, "example.com")
    }

    /// Encoding then decoding `.direct` round-trips correctly.
    func test_roundTrip_direct() throws {
        let data = try encoder.encode(BootstrapConfig.direct)
        let decoded = try decoder.decode(BootstrapConfig.self, from: data)
        if case .direct = decoded {} else {
            XCTFail("Expected .direct after round-trip, got \(decoded)")
        }
    }

    /// Encoding then decoding `.ssoCookieVendor` round-trips correctly.
    func test_roundTrip_ssoCookieVendor() throws {
        let config = SsoCookieVendorConfig(
            idpLoginUrl: "https://idp.example.com",
            cookieName: "bwauth",
            cookieDomain: "example.com",
            cookieValue: nil,
        )
        let original = BootstrapConfig.ssoCookieVendor(config)
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(BootstrapConfig.self, from: data)

        guard case let .ssoCookieVendor(decodedConfig) = decoded else {
            XCTFail("Expected .ssoCookieVendor after round-trip, got \(decoded)")
            return
        }
        XCTAssertEqual(decodedConfig.idpLoginUrl, "https://idp.example.com")
        XCTAssertEqual(decodedConfig.cookieName, "bwauth")
    }
}

// MARK: - ServerCommunicationConfigCodableTests

class ServerCommunicationConfigCodableTests: BitwardenTestCase {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    /// `encode(to:)` for a `.direct` bootstrap produces the expected JSON.
    func test_encode_direct() throws {
        let subject = ServerCommunicationConfig(bootstrap: .direct)
        let data = try encoder.encode(subject)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"bootstrap\""))
        XCTAssertTrue(json.contains("\"type\":\"direct\""))
    }

    /// `encode(to:)` for a `.ssoCookieVendor` bootstrap encodes the nested config.
    func test_encode_ssoCookieVendor() throws {
        let config = SsoCookieVendorConfig(
            idpLoginUrl: "https://idp.example.com",
            cookieName: nil,
            cookieDomain: nil,
            cookieValue: nil,
        )
        let subject = ServerCommunicationConfig(bootstrap: .ssoCookieVendor(config))
        let data = try encoder.encode(subject)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"bootstrap\""))
        XCTAssertTrue(json.contains("\"type\":\"ssoCookieVendor\""))
    }

    /// `init(from:)` decodes a `direct` bootstrap.
    func test_decode_direct() throws {
        let json = #"{"bootstrap":{"type":"direct"}}"#.data(using: .utf8)!
        let subject = try decoder.decode(ServerCommunicationConfig.self, from: json)
        if case .direct = subject.bootstrap {} else {
            XCTFail("Expected .direct bootstrap, got \(subject.bootstrap)")
        }
    }

    /// `init(from:)` decodes a `ssoCookieVendor` bootstrap.
    func test_decode_ssoCookieVendor() throws {
        let json = """
        {
            "bootstrap": {
                "type": "ssoCookieVendor",
                "ssoCookieVendor": {
                    "idpLoginUrl": "https://idp.example.com",
                    "cookieName": "bwauth",
                    "cookieDomain": "example.com"
                }
            }
        }
        """.data(using: .utf8)!

        let subject = try decoder.decode(ServerCommunicationConfig.self, from: json)

        guard case let .ssoCookieVendor(config) = subject.bootstrap else {
            XCTFail("Expected .ssoCookieVendor bootstrap, got \(subject.bootstrap)")
            return
        }
        XCTAssertEqual(config.idpLoginUrl, "https://idp.example.com")
    }

    /// `init(communicationSettings:)` produces `.direct` when bootstrap type is `"direct"`.
    func test_init_communicationSettings_direct() {
        let settings = ServerCommunicationSettings(
            bootstrap: ServerCommunicationBootstrapSettings(
                type: "direct",
                idpLoginUrl: nil,
                cookieName: nil,
                cookieDomain: nil,
            ),
        )
        let subject = ServerCommunicationConfig(communicationSettings: settings)

        if case .direct = subject.bootstrap {} else {
            XCTFail("Expected .direct bootstrap, got \(subject.bootstrap)")
        }
    }

    /// `init(communicationSettings:)` produces `.ssoCookieVendor` when bootstrap type matches.
    func test_init_communicationSettings_ssoCookieVendor() {
        let settings = ServerCommunicationSettings(
            bootstrap: ServerCommunicationBootstrapSettings(
                type: "ssoCookieVendor",
                idpLoginUrl: "https://idp.example.com",
                cookieName: "bwauth",
                cookieDomain: "example.com",
            ),
        )
        let subject = ServerCommunicationConfig(communicationSettings: settings)

        guard case let .ssoCookieVendor(config) = subject.bootstrap else {
            XCTFail("Expected .ssoCookieVendor bootstrap, got \(subject.bootstrap)")
            return
        }
        XCTAssertEqual(config.idpLoginUrl, "https://idp.example.com")
        XCTAssertEqual(config.cookieName, "bwauth")
        XCTAssertEqual(config.cookieDomain, "example.com")
        XCTAssertNil(config.cookieValue)
    }

    /// `init(communicationSettings:)` falls back to `.direct` for unknown bootstrap types.
    func test_init_communicationSettings_unknownType_treatedAsDirect() {
        let settings = ServerCommunicationSettings(
            bootstrap: ServerCommunicationBootstrapSettings(
                type: "unknownBootstrapType",
                idpLoginUrl: nil,
                cookieName: nil,
                cookieDomain: nil,
            ),
        )
        let subject = ServerCommunicationConfig(communicationSettings: settings)

        if case .direct = subject.bootstrap {} else {
            XCTFail("Expected .direct fallback for unknown type, got \(subject.bootstrap)")
        }
    }

    /// `updateCookieValue(from:)` copies the `cookieValue` from the `from` config.
    func test_updateCookieValue_bothSsoCookieVendor() {
        let selfConfig = SsoCookieVendorConfig(
            idpLoginUrl: "https://self-idp.com",
            cookieName: "selfCookie",
            cookieDomain: "self.com",
            cookieValue: nil,
        )
        let fromConfig = SsoCookieVendorConfig(
            idpLoginUrl: "https://from-idp.com",
            cookieName: "fromCookie",
            cookieDomain: "from.com",
            cookieValue: [AcquiredCookie(name: "acquired", value: "tokenValue")],
        )
        let selfComm = ServerCommunicationConfig(bootstrap: .ssoCookieVendor(selfConfig))
        let fromComm = ServerCommunicationConfig(bootstrap: .ssoCookieVendor(fromConfig))

        let result = selfComm.updateCookieValue(from: fromComm)

        guard case let .ssoCookieVendor(resultConfig) = result.bootstrap else {
            XCTFail("Expected .ssoCookieVendor in result, got \(result.bootstrap)")
            return
        }
        // Self's identity fields are preserved.
        XCTAssertEqual(resultConfig.idpLoginUrl, "https://self-idp.com")
        XCTAssertEqual(resultConfig.cookieName, "selfCookie")
        XCTAssertEqual(resultConfig.cookieDomain, "self.com")
        // Cookie value comes from `from`.
        XCTAssertEqual(resultConfig.cookieValue?.first?.name, "acquired")
        XCTAssertEqual(resultConfig.cookieValue?.first?.value, "tokenValue")
    }

    /// `updateCookieValue(from:)` returns `from` unchanged when `self` bootstrap is `.direct`.
    func test_updateCookieValue_selfDirect_returnsFromConfig() {
        let selfComm = ServerCommunicationConfig(bootstrap: .direct)
        let fromConfig = SsoCookieVendorConfig(
            idpLoginUrl: "https://from-idp.com",
            cookieName: nil,
            cookieDomain: nil,
            cookieValue: [AcquiredCookie(name: "n", value: "v")],
        )
        let fromComm = ServerCommunicationConfig(bootstrap: .ssoCookieVendor(fromConfig))

        let result = selfComm.updateCookieValue(from: fromComm)

        guard case let .ssoCookieVendor(resultConfig) = result.bootstrap else {
            XCTFail("Expected .ssoCookieVendor in result, got \(result.bootstrap)")
            return
        }
        XCTAssertEqual(resultConfig.idpLoginUrl, "https://from-idp.com")
    }

    /// `updateCookieValue(from:)` returns `from` unchanged when `from` bootstrap is `.direct`.
    func test_updateCookieValue_fromDirect_returnsFromConfig() {
        let selfConfig = SsoCookieVendorConfig(
            idpLoginUrl: "https://self-idp.com",
            cookieName: nil,
            cookieDomain: nil,
            cookieValue: nil,
        )
        let selfComm = ServerCommunicationConfig(bootstrap: .ssoCookieVendor(selfConfig))
        let fromComm = ServerCommunicationConfig(bootstrap: .direct)

        let result = selfComm.updateCookieValue(from: fromComm)

        if case .direct = result.bootstrap {} else {
            XCTFail("Expected .direct in result when from is .direct, got \(result.bootstrap)")
        }
    }
}

// MARK: - ServerCommunicationConfigSSOCookieVendorConfigTests

class ServerCommunicationConfigSSOCookieVendorConfigTests: BitwardenTestCase {
    // swiftlint:disable:previous type_name
    /// `ssoCookieVendorConfig` returns the config when bootstrap is `.ssoCookieVendor`.
    func test_ssoCookieVendorConfig_ssoCookieVendor_returnsConfig() {
        let ssoConfig = SsoCookieVendorConfig(
            idpLoginUrl: "https://idp.example.com",
            cookieName: "auth",
            cookieDomain: "example.com",
            cookieValue: nil,
        )
        let subject = ServerCommunicationConfig(bootstrap: .ssoCookieVendor(ssoConfig))

        let result = subject.ssoCookieVendorConfig

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.idpLoginUrl, "https://idp.example.com")
        XCTAssertEqual(result?.cookieName, "auth")
        XCTAssertEqual(result?.cookieDomain, "example.com")
    }

    /// `ssoCookieVendorConfig` returns `nil` when bootstrap is `.direct`.
    func test_ssoCookieVendorConfig_direct_returnsNil() {
        let subject = ServerCommunicationConfig(bootstrap: .direct)

        XCTAssertNil(subject.ssoCookieVendorConfig)
    }
} // swiftlint:disable:this file_length
