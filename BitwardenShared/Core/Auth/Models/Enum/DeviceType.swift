import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - DeviceTypeCategory

/// The category of a device type.
///
enum DeviceTypeCategory: String, Sendable {
    case mobile
    case `extension`
    case webApp
    case desktop
    case cli
    case sdk
    case server

    /// The localized display name for the category.
    var displayName: String {
        switch self {
        case .mobile:
            Localizations.mobile
        case .extension:
            Localizations.browserExtension
        case .webApp:
            Localizations.webVault
        case .desktop:
            Localizations.desktop
        case .cli:
            Localizations.cli
        case .sdk:
            Localizations.sdk
        case .server:
            Localizations.server
        }
    }
}

// MARK: - DeviceType Extension

extension DeviceType {
    // MARK: Known Device Type Values

    static let android: DeviceType = 0
    static let iOS: DeviceType = 1
    static let chromeExtension: DeviceType = 2
    static let firefoxExtension: DeviceType = 3
    static let operaExtension: DeviceType = 4
    static let edgeExtension: DeviceType = 5
    static let windowsDesktop: DeviceType = 6
    static let macOsDesktop: DeviceType = 7
    static let linuxDesktop: DeviceType = 8
    static let chromeBrowser: DeviceType = 9
    static let firefoxBrowser: DeviceType = 10
    static let operaBrowser: DeviceType = 11
    static let edgeBrowser: DeviceType = 12
    static let ieBrowser: DeviceType = 13
    static let unknownBrowser: DeviceType = 14
    static let androidAmazon: DeviceType = 15
    static let uwp: DeviceType = 16
    static let safariBrowser: DeviceType = 17
    static let vivaldiBrowser: DeviceType = 18
    static let vivaldiExtension: DeviceType = 19
    static let safariExtension: DeviceType = 20
    static let sdk: DeviceType = 21
    static let server: DeviceType = 22
    static let windowsCLI: DeviceType = 23
    static let macOsCLI: DeviceType = 24
    static let linuxCLI: DeviceType = 25
    static let duckDuckGoBrowser: DeviceType = 26

    // MARK: Properties

    /// The category of the device type.
    var category: DeviceTypeCategory {
        switch self {
        case Self.android, Self.androidAmazon, Self.iOS:
            .mobile
        case Self.chromeExtension, Self.edgeExtension, Self.firefoxExtension, Self.operaExtension,
             Self.safariExtension, Self.vivaldiExtension:
            .extension
        case Self.chromeBrowser, Self.duckDuckGoBrowser, Self.edgeBrowser, Self.firefoxBrowser,
             Self.ieBrowser, Self.operaBrowser, Self.safariBrowser, Self.unknownBrowser, Self.vivaldiBrowser:
            .webApp
        case Self.linuxDesktop, Self.macOsDesktop, Self.uwp, Self.windowsDesktop:
            .desktop
        case Self.linuxCLI, Self.macOsCLI, Self.windowsCLI:
            .cli
        case Self.sdk:
            .sdk
        case Self.server:
            .server
        default:
            .mobile
        }
    }

    /// The platform name for the device type.
    var platform: String {
        switch self {
        case Self.android:
            "Android"
        case Self.iOS:
            "iOS"
        case Self.androidAmazon:
            "Amazon"
        case Self.chromeBrowser, Self.chromeExtension:
            "Chrome"
        case Self.firefoxBrowser, Self.firefoxExtension:
            "Firefox"
        case Self.operaBrowser, Self.operaExtension:
            "Opera"
        case Self.edgeBrowser, Self.edgeExtension:
            "Edge"
        case Self.vivaldiBrowser, Self.vivaldiExtension:
            "Vivaldi"
        case Self.safariBrowser, Self.safariExtension:
            "Safari"
        case Self.ieBrowser:
            "IE"
        case Self.duckDuckGoBrowser:
            "DuckDuckGo"
        case Self.unknownBrowser:
            Localizations.unknown
        case Self.windowsCLI, Self.windowsDesktop:
            "Windows"
        case Self.macOsCLI, Self.macOsDesktop:
            "macOS"
        case Self.linuxCLI, Self.linuxDesktop:
            "Linux"
        case Self.uwp:
            "Windows UWP"
        case Self.sdk, Self.server:
            ""
        default:
            Localizations.unknown
        }
    }

    /// The display name for the device type, combining category and platform.
    var displayName: String {
        if platform.isEmpty {
            return category.displayName
        }
        return "\(category.displayName) - \(platform)"
    }
}
