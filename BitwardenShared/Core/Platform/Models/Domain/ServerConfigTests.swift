import BitwardenKit
import Foundation
import XCTest

@testable import BitwardenShared

final class ServerConfigTests: BitwardenTestCase {
    // MARK: Tests

    /// `supportsCipherKeyEncryption()` returns `true` when the server version is equal
    /// to the minimum version that supports cipher key encryption.
    func test_supportsCipherKeyEncryption_equalValidVersion() {
        let model = ConfigResponseModel(
            communication: nil,
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "2024.2.0",
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertTrue(subject.supportsCipherKeyEncryption())
    }

    /// `supportsCipherKeyEncryption()` returns `true` when the server version is greater
    /// than the minimum version that supports cipher key encryption.
    func test_supportsCipherKeyEncryption_greaterValidVersion() {
        let model = ConfigResponseModel(
            communication: nil,
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "2024.3.15",
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertTrue(subject.supportsCipherKeyEncryption())
    }

    /// `supportsCipherKeyEncryption()` returns `false` when the server version is lesser
    /// than the minimum version that supports cipher key encryption.
    func test_supportsCipherKeyEncryption_lesserThanVersion() {
        let model = ConfigResponseModel(
            communication: nil,
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "2023.1.28",
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertFalse(subject.supportsCipherKeyEncryption())
    }

    /// `supportsCipherKeyEncryption()` returns `false` when the server version has wrong format.
    func test_supportsCipherKeyEncryption_wrongFormat() {
        let model = ConfigResponseModel(
            communication: nil,
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "20asdfasdf24.2.0",
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertFalse(subject.supportsCipherKeyEncryption())
    }

    /// `init(date:responseModel:)` maps `communication` to `ServerCommunicationSettings` when present.
    func test_init_withCommunicationSettings_ssoCookieVendor() {
        let bootstrap = CommunicationBootstrapSettingsResponseModel(
            type: "ssoCookieVendor",
            idpLoginUrl: "https://idp.example.com/login",
            cookieName: "bwauth",
            cookieDomain: "example.com",
        )
        let model = ConfigResponseModel(
            communication: CommunicationSettingsResponseModel(bootstrap: bootstrap),
            environment: nil,
            featureStates: [:],
            gitHash: "abc",
            server: nil,
            version: "2024.2.0",
        )

        let subject = ServerConfig(date: Date(), responseModel: model)

        XCTAssertNotNil(subject.communication)
        XCTAssertEqual(subject.communication?.bootstrap.type, "ssoCookieVendor")
        XCTAssertEqual(subject.communication?.bootstrap.idpLoginUrl, "https://idp.example.com/login")
        XCTAssertEqual(subject.communication?.bootstrap.cookieName, "bwauth")
        XCTAssertEqual(subject.communication?.bootstrap.cookieDomain, "example.com")
    }

    /// `init(date:responseModel:)` maps `communication` for a `direct` bootstrap type.
    func test_init_withCommunicationSettings_direct() {
        let bootstrap = CommunicationBootstrapSettingsResponseModel(
            type: "direct",
            idpLoginUrl: nil,
            cookieName: nil,
            cookieDomain: nil,
        )
        let model = ConfigResponseModel(
            communication: CommunicationSettingsResponseModel(bootstrap: bootstrap),
            environment: nil,
            featureStates: [:],
            gitHash: "abc",
            server: nil,
            version: "2024.2.0",
        )

        let subject = ServerConfig(date: Date(), responseModel: model)

        XCTAssertEqual(subject.communication?.bootstrap.type, "direct")
        XCTAssertNil(subject.communication?.bootstrap.idpLoginUrl)
        XCTAssertNil(subject.communication?.bootstrap.cookieName)
        XCTAssertNil(subject.communication?.bootstrap.cookieDomain)
    }

    /// `init(date:responseModel:)` sets `communication` to `nil` when the response model omits it.
    func test_init_withoutCommunicationSettings() {
        let model = ConfigResponseModel(
            communication: nil,
            environment: nil,
            featureStates: [:],
            gitHash: "abc",
            server: nil,
            version: "2024.2.0",
        )

        let subject = ServerConfig(date: Date(), responseModel: model)

        XCTAssertNil(subject.communication)
    }

    /// `ServerCommunicationBootstrapSettings` initialised from a response model maps all fields.
    func test_communicationBootstrapSettings_init_fromResponseModel() {
        let responseModel = CommunicationBootstrapSettingsResponseModel(
            type: "ssoCookieVendor",
            idpLoginUrl: "https://idp.example.com",
            cookieName: "session",
            cookieDomain: "example.com",
        )
        let subject = ServerCommunicationBootstrapSettings(responseModel: responseModel)

        XCTAssertEqual(subject.type, "ssoCookieVendor")
        XCTAssertEqual(subject.idpLoginUrl, "https://idp.example.com")
        XCTAssertEqual(subject.cookieName, "session")
        XCTAssertEqual(subject.cookieDomain, "example.com")
    }

    /// `ServerCommunicationSettings` with equal bootstraps compare as equal.
    func test_communicationSettings_equatable() {
        let bootstrapA = ServerCommunicationBootstrapSettings(
            type: "direct",
            idpLoginUrl: nil,
            cookieName: nil,
            cookieDomain: nil,
        )
        let bootstrapB = ServerCommunicationBootstrapSettings(
            type: "ssoCookieVendor",
            idpLoginUrl: "https://idp.example.com",
            cookieName: "c",
            cookieDomain: "example.com",
        )

        XCTAssertEqual(
            ServerCommunicationSettings(bootstrap: bootstrapA),
            ServerCommunicationSettings(bootstrap: bootstrapA),
        )
        XCTAssertNotEqual(
            ServerCommunicationSettings(bootstrap: bootstrapA),
            ServerCommunicationSettings(bootstrap: bootstrapB),
        )
    }
}
