// MARK: - DeviceType

/// The type of device used to access the vault.
///
public enum DeviceType: Int, Codable, Hashable, Sendable {
    case android = 0
    case iOS = 1
    case chromeExtension = 2
    case firefoxExtension = 3
    case operaExtension = 4
    case edgeExtension = 5
    case windowsDesktop = 6
    case macOsDesktop = 7
    case linuxDesktop = 8
    case chromeBrowser = 9
    case firefoxBrowser = 10
    case operaBrowser = 11
    case edgeBrowser = 12
    case ieBrowser = 13
    case unknownBrowser = 14
    case androidAmazon = 15
    case uwp = 16
    case safariBrowser = 17
    case vivaldiBrowser = 18
    case vivaldiExtension = 19
    case safariExtension = 20
    case sdk = 21
    case server = 22
    case windowsCLI = 23
    case macOsCLI = 24
    case linuxCLI = 25
    case duckDuckGoBrowser = 26

    // MARK: Initialization

    /// Initializes a `DeviceType` from a raw integer value, falling back to `.unknownBrowser`
    /// for values not yet recognized by the client.
    public init(_ rawValue: Int) {
        self = DeviceType(rawValue: rawValue) ?? .unknownBrowser
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        self = DeviceType(rawValue: rawValue) ?? .unknownBrowser
    }
}
