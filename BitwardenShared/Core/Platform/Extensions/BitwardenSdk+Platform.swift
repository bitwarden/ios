// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - BitwardenSdk.AcquiredCookie

extension BitwardenSdk.AcquiredCookie: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let value = try container.decode(String.self, forKey: .value)
        self.init(name: name, value: value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
    }
}

// MARK: - BitwardenSdk.BitwardenError

extension BitwardenSdk.BitwardenError: @retroactive CustomNSError {
    /// The user-info dictionary.
    public var errorUserInfo: [String: Any] {
        ["SpecificError": String(describing: self)]
    }
}

// MARK: - BitwardenSdk.BootstrapConfig

extension BitwardenSdk.BootstrapConfig: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case ssoCookieVendor
    }

    enum BootstrapType: String, Codable {
        case direct
        case ssoCookieVendor
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BootstrapType.self, forKey: .type)

        switch type {
        case .direct:
            self = .direct
        case .ssoCookieVendor:
            let config = try container.decode(SsoCookieVendorConfig.self, forKey: .ssoCookieVendor)
            self = .ssoCookieVendor(config)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .direct:
            try container.encode(BootstrapType.direct, forKey: .type)
        case let .ssoCookieVendor(config):
            try container.encode(BootstrapType.ssoCookieVendor, forKey: .type)
            try container.encode(config, forKey: .ssoCookieVendor)
        }
    }
}

// MARK: - BitwardenSdk.ServerCommunicationConfig

extension BitwardenSdk.ServerCommunicationConfig: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case bootstrap
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let bootstrap = try container.decode(BootstrapConfig.self, forKey: .bootstrap)
        self.init(bootstrap: bootstrap)
    }

    init(communicationSettings: CommunicationSettings) {
        guard communicationSettings.bootstrap == "ssoCookieVendor",
              let ssoCookieVendor = communicationSettings.ssoCookieVendor else {
            self.init(bootstrap: .direct)
            return
        }

        self.init(
            bootstrap: .ssoCookieVendor(
                SsoCookieVendorConfig(
                    idpLoginUrl: ssoCookieVendor.idpLoginUrl,
                    cookieName: ssoCookieVendor.cookieName,
                    cookieDomain: ssoCookieVendor.cookieDomain,
                    cookieValue: nil,
                ),
            ),
        )
    }

    // MARK: Methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bootstrap, forKey: .bootstrap)
    }

    /// Updates the `cookieValue` taken from another `ServerCommunicationConfig`.
    /// - Parameter config: The config to get the `cookieValue` from.
    /// - Returns: A new `ServerCommunicationConfig` similar to this one
    /// with the cookie value updated from the parameter.
    func updateCookieValue(from config: ServerCommunicationConfig) -> ServerCommunicationConfig {
        guard case let .ssoCookieVendor(fromSSOCookieConfig) = config.bootstrap,
              case let .ssoCookieVendor(currentCookieConfig) = bootstrap else {
            return config
        }

        return ServerCommunicationConfig(
            bootstrap: .ssoCookieVendor(
                SsoCookieVendorConfig(
                    idpLoginUrl: currentCookieConfig.idpLoginUrl,
                    cookieName: currentCookieConfig.cookieName,
                    cookieDomain: currentCookieConfig.cookieDomain,
                    cookieValue: fromSSOCookieConfig.cookieValue,
                )
            ),
        )
    }
}

// MARK: - BitwardenSdk.SsoCookieVendorConfig

extension BitwardenSdk.SsoCookieVendorConfig: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case idpLoginUrl
        case cookieName
        case cookieDomain
        case cookieValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idpLoginUrl = try container.decodeIfPresent(String.self, forKey: .idpLoginUrl)
        let cookieName = try container.decodeIfPresent(String.self, forKey: .cookieName)
        let cookieDomain = try container.decodeIfPresent(String.self, forKey: .cookieDomain)
        let cookieValue = try container.decodeIfPresent([AcquiredCookie].self, forKey: .cookieValue)
        self.init(
            idpLoginUrl: idpLoginUrl,
            cookieName: cookieName,
            cookieDomain: cookieDomain,
            cookieValue: cookieValue
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(idpLoginUrl, forKey: .idpLoginUrl)
        try container.encodeIfPresent(cookieName, forKey: .cookieName)
        try container.encodeIfPresent(cookieDomain, forKey: .cookieDomain)
        try container.encodeIfPresent(cookieValue, forKey: .cookieValue)
    }
}
