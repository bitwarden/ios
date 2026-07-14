import BitwardenKit
import BitwardenResources
import Testing

@testable import BitwardenShared

// MARK: - DeviceTypeCategoryTests

struct DeviceTypeCategoryTests {
    // MARK: Tests

    /// `displayName` returns the localized string for each category.
    @Test(arguments: [
        (DeviceTypeCategory.cli, Localizations.cli),
        (DeviceTypeCategory.desktop, Localizations.desktop),
        (DeviceTypeCategory.extension, Localizations.browserExtension),
        (DeviceTypeCategory.mobile, Localizations.mobile),
        (DeviceTypeCategory.sdk, Localizations.sdk),
        (DeviceTypeCategory.server, Localizations.server),
        (DeviceTypeCategory.unknown, Localizations.unknown),
        (DeviceTypeCategory.webApp, Localizations.webVaultDeviceType),
    ])
    func displayName(category: DeviceTypeCategory, expected: String) {
        #expect(category.displayName == expected)
    }
}

// MARK: - DeviceType Extension Tests

struct DeviceTypeCategoryDeviceTypeExtensionTests {
    // MARK: Tests

    /// `category` returns the correct category for each device type.
    @Test(arguments: [
        (DeviceType.android, DeviceTypeCategory.mobile),
        (.androidAmazon, .mobile),
        (.iOS, .mobile),
        (.chromeExtension, .extension),
        (.edgeExtension, .extension),
        (.firefoxExtension, .extension),
        (.operaExtension, .extension),
        (.safariExtension, .extension),
        (.vivaldiExtension, .extension),
        (.chromeBrowser, .webApp),
        (.duckDuckGoBrowser, .webApp),
        (.edgeBrowser, .webApp),
        (.firefoxBrowser, .webApp),
        (.ieBrowser, .webApp),
        (.operaBrowser, .webApp),
        (.safariBrowser, .webApp),
        (.vivaldiBrowser, .webApp),
        (.linuxDesktop, .desktop),
        (.macOsDesktop, .desktop),
        (.uwp, .desktop),
        (.windowsDesktop, .desktop),
        (.linuxCLI, .cli),
        (.macOsCLI, .cli),
        (.windowsCLI, .cli),
        (.sdk, .sdk),
        (.server, .server),
        (.unknownBrowser, .unknown),
    ])
    func category(type: DeviceType, expected: DeviceTypeCategory) {
        #expect(type.category == expected)
    }

    /// `platform` returns the correct platform name for each device type.
    @Test(arguments: [
        (DeviceType.android, "Android"),
        (.iOS, "iOS"),
        (.androidAmazon, "Amazon"),
        (.chromeBrowser, "Chrome"),
        (.chromeExtension, "Chrome"),
        (.firefoxBrowser, "Firefox"),
        (.firefoxExtension, "Firefox"),
        (.operaBrowser, "Opera"),
        (.operaExtension, "Opera"),
        (.edgeBrowser, "Edge"),
        (.edgeExtension, "Edge"),
        (.vivaldiBrowser, "Vivaldi"),
        (.vivaldiExtension, "Vivaldi"),
        (.safariBrowser, "Safari"),
        (.safariExtension, "Safari"),
        (.ieBrowser, "Internet Explorer"),
        (.duckDuckGoBrowser, "DuckDuckGo"),
        (.unknownBrowser, ""),
        (.windowsCLI, "Windows"),
        (.windowsDesktop, "Windows"),
        (.macOsCLI, "macOS"),
        (.macOsDesktop, "macOS"),
        (.linuxCLI, "Linux"),
        (.linuxDesktop, "Linux"),
        (.uwp, "Windows UWP"),
        (.sdk, ""),
        (.server, ""),
    ])
    func platform(type: DeviceType, expected: String) {
        #expect(type.platform == expected)
    }

    /// `displayName` combines the category and platform for types with a non-empty platform.
    @Test
    func displayName_withPlatform() {
        #expect(DeviceType.iOS.displayName == Localizations.deviceDisplayName(Localizations.mobile, "iOS"))
    }

    /// `displayName` falls back to the category's display name when the platform is empty.
    @Test
    func displayName_emptyPlatform() {
        #expect(DeviceType.sdk.displayName == Localizations.sdk)
        #expect(DeviceType.server.displayName == Localizations.server)
        #expect(DeviceType.unknownBrowser.displayName == Localizations.unknown)
    }
}
