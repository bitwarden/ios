import BitwardenKit
import BitwardenResources

// MARK: - DeviceTypeCategory

/// The category of a device type.
///
enum DeviceTypeCategory: Sendable {
    case cli
    case desktop
    case `extension`
    case mobile
    case sdk
    case server
    case unknown
    case webApp

    /// The localized display name for the category.
    var displayName: String {
        switch self {
        case .cli:
            Localizations.cli
        case .desktop:
            Localizations.desktop
        case .extension:
            Localizations.browserExtension
        case .mobile:
            Localizations.mobile
        case .sdk:
            Localizations.sdk
        case .server:
            Localizations.server
        case .unknown:
            Localizations.unknown
        case .webApp:
            Localizations.webVaultDeviceType
        }
    }
}

// MARK: - DeviceType Extension

extension DeviceType {
    // MARK: Properties

    /// The category of the device type.
    var category: DeviceTypeCategory {
        switch self {
        case .android, .androidAmazon, .iOS:
            .mobile
        case .chromeExtension, .edgeExtension, .firefoxExtension, .operaExtension,
             .safariExtension, .vivaldiExtension:
            .extension
        case .chromeBrowser, .duckDuckGoBrowser, .edgeBrowser, .firefoxBrowser,
             .ieBrowser, .operaBrowser, .safariBrowser, .vivaldiBrowser:
            .webApp
        case .linuxDesktop, .macOsDesktop, .uwp, .windowsDesktop:
            .desktop
        case .linuxCLI, .macOsCLI, .windowsCLI:
            .cli
        case .sdk:
            .sdk
        case .server:
            .server
        case .unknownBrowser:
            .unknown
        }
    }

    /// The platform name for the device type.
    var platform: String {
        switch self {
        case .android:
            "Android"
        case .iOS:
            "iOS"
        case .androidAmazon:
            "Amazon"
        case .chromeBrowser, .chromeExtension:
            "Chrome"
        case .firefoxBrowser, .firefoxExtension:
            "Firefox"
        case .operaBrowser, .operaExtension:
            "Opera"
        case .edgeBrowser, .edgeExtension:
            "Edge"
        case .vivaldiBrowser, .vivaldiExtension:
            "Vivaldi"
        case .safariBrowser, .safariExtension:
            "Safari"
        case .ieBrowser:
            "Internet Explorer"
        case .duckDuckGoBrowser:
            "DuckDuckGo"
        case .unknownBrowser:
            ""
        case .windowsCLI, .windowsDesktop:
            "Windows"
        case .macOsCLI, .macOsDesktop:
            "macOS"
        case .linuxCLI, .linuxDesktop:
            "Linux"
        case .uwp:
            "Windows UWP"
        case .sdk, .server:
            ""
        }
    }

    /// The display name for the device type, combining category and platform.
    var displayName: String {
        guard !platform.isEmpty else {
            return category.displayName
        }
        return Localizations.deviceDisplayName(category.displayName, platform)
    }

    /// A match key used to correlate this device type with a pending login request's
    /// `requestDeviceType` string. Differs from `platform` for extension types so that
    /// e.g. `chromeExtension` ("Chrome Extension") is not confused with `chromeBrowser`
    /// ("Chrome") when both are active simultaneously.
    var pendingRequestMatchKey: String {
        switch self {
        case .chromeExtension:
            "Chrome Extension"
        case .firefoxExtension:
            "Firefox Extension"
        case .operaExtension:
            "Opera Extension"
        case .edgeExtension:
            "Edge Extension"
        case .safariExtension:
            "Safari Extension"
        case .vivaldiExtension:
            "Vivaldi Extension"
        default:
            platform
        }
    }
}
