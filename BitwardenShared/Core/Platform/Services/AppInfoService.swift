import BitwardenKit
import UIKit

// MARK: - AppAdditionalInfo

/// Protocol for additional info used by the `AppInfoService`.
///
protocol AppAdditionalInfo {
    /// CI Build information.
    var ciBuildInfo: KeyValuePairs<String, String> { get }
}

// MARK: - DefaultAppAdditionalInfo

/// Default implementation of `AppAdditionalInfo`.
///
struct DefaultAppAdditionalInfo: AppAdditionalInfo {
    var ciBuildInfo: KeyValuePairs<String, String> {
        CIBuildInfo.info
    }
}

// MARK: - AppInfoService

/// A protocol for a service that can provide formatted information about the app and the device
/// it's running on.
///
protocol AppInfoService {
    /// A formatted string containing detailed information about the app and device.
    var appInfoString: String { get }

    /// The app's formatted copyright string.
    var copyrightString: String { get }

    /// The app's formatted version string.
    var versionString: String { get }
}

// MARK: - DefaultAppInfoService

/// The default implementation of `AppInfoService`.
///
class DefaultAppInfoService: AppInfoService {
    // MARK: Properties

    /// Additional build details to include in the app info string.
    private let appAdditionalInfo: AppAdditionalInfo

    /// The app's bundle.
    private let bundle: BundleProtocol

    /// An object used to retrieve information about this device.
    private let systemDevice: SystemDevice

    /// The service used to get the present time.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initialize a `DefaultAppInfoService`.
    ///
    /// - Parameters:
    ///   - additionalInfo: Additional build details to include in the app info string.
    ///   - bundle: The app's bundle.
    ///   - systemDevice: An object used to retrieve information about this device.
    ///   - timeProvider: The service used to get the present time.
    ///
    init(
        appAdditionalInfo: AppAdditionalInfo = DefaultAppAdditionalInfo(),
        bundle: BundleProtocol = Bundle.main,
        systemDevice: SystemDevice = UIDevice.current,
        timeProvider: TimeProvider = CurrentTime()
    ) {
        self.appAdditionalInfo = appAdditionalInfo
        self.bundle = bundle
        self.systemDevice = systemDevice
        self.timeProvider = timeProvider
    }
}

// MARK: - DefaultAppInfoService + AppInfoService

extension DefaultAppInfoService {
    var appInfoString: String {
        var buildVariant = switch bundle.bundleIdentifier {
        case "com.8bit.bitwarden.beta": "Beta"
        case "com.8bit.bitwarden": "Production"
        default: "Unknown"
        }
        buildVariant = "📦 \(buildVariant)"
        let hardwareInfo = "📱 \(systemDevice.modelIdentifier)"
        let osInfo = "🍏 \(systemDevice.systemName) \(systemDevice.systemVersion)"
        let deviceInfo = "\(hardwareInfo) \(osInfo) \(buildVariant)"
        var infoParts = [
            copyrightString,
            "",
            versionString,
            deviceInfo,
        ]
        if !appAdditionalInfo.ciBuildInfo.isEmpty {
            infoParts.append(
                contentsOf: appAdditionalInfo.ciBuildInfo
                    .filter { !$0.value.isEmpty }
                    .map { key, value in
                        "\(key) \(value)"
                    }
            )
        }
        return infoParts.joined(separator: "\n")
    }

    var copyrightString: String {
        "© Bitwarden Inc. 2015\(String.enDash)\(Calendar.current.component(.year, from: timeProvider.presentTime))"
    }

    var versionString: String {
        "\(Localizations.version): \(bundle.appVersion) (\(bundle.buildNumber))"
    }
}
