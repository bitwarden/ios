import TestHelpers
import XCTest

@testable import BitwardenKit

class ConfigResponseModelTests: BitwardenTestCase {
    // MARK: Tests

    /// `init` stores all provided fields.
    func test_init_withAllFields() {
        let bootstrap = CommunicationBootstrapSettingsResponseModel(
            type: "ssoCookieVendor",
            idpLoginUrl: "https://idp.example.com",
            cookieName: "bwauth",
            cookieDomain: "example.com",
        )
        let communication = CommunicationSettingsResponseModel(bootstrap: bootstrap)
        let subject = ConfigResponseModel(
            communication: communication,
            environment: nil,
            featureStates: ["flag": .bool(true)],
            gitHash: "abc123",
            server: nil,
            version: "2024.5.0",
        )

        XCTAssertNotNil(subject.communication)
        XCTAssertEqual(subject.communication?.bootstrap.type, "ssoCookieVendor")
        XCTAssertEqual(subject.gitHash, "abc123")
        XCTAssertEqual(subject.version, "2024.5.0")
    }

    /// `init` stores `nil` when `communication` is omitted.
    func test_init_withNilCommunication() {
        let subject = ConfigResponseModel(
            communication: nil,
            environment: nil,
            featureStates: nil,
            gitHash: nil,
            server: nil,
            version: "2024.5.0",
        )

        XCTAssertNil(subject.communication)
    }

    /// `JSONResponse` decoding includes the `communication` field with `ssoCookieVendor` bootstrap.
    func test_jsonDecoding_withCommunication() throws {
        let json = """
        {
            "version": "2024.5.0",
            "gitHash": "abc123",
            "communication": {
                "bootstrap": {
                    "type": "ssoCookieVendor",
                    "idpLoginUrl": "https://idp.example.com",
                    "cookieName": "bwauth",
                    "cookieDomain": "example.com"
                }
            }
        }
        """.data(using: .utf8)!

        let subject = try JSONDecoder.defaultDecoder.decode(ConfigResponseModel.self, from: json)

        XCTAssertEqual(subject.communication?.bootstrap.type, "ssoCookieVendor")
        XCTAssertEqual(subject.communication?.bootstrap.idpLoginUrl, "https://idp.example.com")
        XCTAssertEqual(subject.communication?.bootstrap.cookieName, "bwauth")
        XCTAssertEqual(subject.communication?.bootstrap.cookieDomain, "example.com")
    }

    /// `JSONResponse` decoding sets `communication` to `nil` when the key is absent.
    func test_jsonDecoding_withoutCommunication() throws {
        let json = """
        {
            "version": "2024.5.0",
            "gitHash": "abc123"
        }
        """.data(using: .utf8)!

        let subject = try JSONDecoder.defaultDecoder.decode(ConfigResponseModel.self, from: json)

        XCTAssertNil(subject.communication)
    }

    /// `JSONResponse` decoding handles a `direct` bootstrap type correctly.
    func test_jsonDecoding_withDirectBootstrap() throws {
        let json = """
        {
            "version": "2024.5.0",
            "gitHash": "abc123",
            "communication": {
                "bootstrap": {
                    "type": "direct"
                }
            }
        }
        """.data(using: .utf8)!

        let subject = try JSONDecoder.defaultDecoder.decode(ConfigResponseModel.self, from: json)

        XCTAssertEqual(subject.communication?.bootstrap.type, "direct")
        XCTAssertNil(subject.communication?.bootstrap.idpLoginUrl)
        XCTAssertNil(subject.communication?.bootstrap.cookieName)
        XCTAssertNil(subject.communication?.bootstrap.cookieDomain)
    }

    /// `CommunicationBootstrapSettingsResponseModel` stores all fields.
    func test_communicationBootstrapSettingsResponseModel_init() {
        let subject = CommunicationBootstrapSettingsResponseModel(
            type: "ssoCookieVendor",
            idpLoginUrl: "https://idp.example.com",
            cookieName: "session",
            cookieDomain: "example.com",
        )

        XCTAssertEqual(subject.type, "ssoCookieVendor")
        XCTAssertEqual(subject.idpLoginUrl, "https://idp.example.com")
        XCTAssertEqual(subject.cookieName, "session")
        XCTAssertEqual(subject.cookieDomain, "example.com")
    }

    /// `CommunicationSettingsResponseModel` stores its bootstrap.
    func test_communicationSettingsResponseModel_init() {
        let bootstrap = CommunicationBootstrapSettingsResponseModel(
            type: "direct",
            idpLoginUrl: nil,
            cookieName: nil,
            cookieDomain: nil,
        )
        let subject = CommunicationSettingsResponseModel(bootstrap: bootstrap)

        XCTAssertEqual(subject.bootstrap.type, "direct")
    }
}
