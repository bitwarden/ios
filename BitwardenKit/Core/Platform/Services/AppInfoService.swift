import BitwardenResources
import UIKit

// MARK: - AppAdditionalInfo

/// Protocol for additional info used by the `AppInfoService`.
///
public protocol AppAdditionalInfo {
    /// CI Build information.
    var ciBuildInfo: KeyValuePairs<String, String> { get }

    /// SDK version information.
    var sdkVersion: String { get }
}

// MARK: - DefaultAppAdditionalInfo

/// Default implementation of `AppAdditionalInfo`.
///
public struct DefaultAppAdditionalInfo: AppAdditionalInfo {
    public var ciBuildInfo: KeyValuePairs<String, String> {
        CIBuildInfo.info
    }

    public var sdkVersion: String {
        SDKVersionInfo.version
    }

    public init() {}
}

// MARK: - HasAppInfoService

/// Protocol for an object that provides an `AppInfoService`.
///
public protocol HasAppInfoService {
    /// The service used by the application to get info about the app and device it's running on.
    var appInfoService: AppInfoService { get }
}

// MARK: - AppInfoService

/// A protocol for a service that can provide formatted information about the app and the device
/// it's running on.
///
public protocol AppInfoService {
    /// A formatted string containing detailed information about the app and device.
    var appInfoString: String { get async }

    /// The `appInfoString` without copyright information.
    var appInfoWithoutCopyrightString: String { get async }

    /// The app's formatted copyright string.
    var copyrightString: String { get }

    /// The app's formatted version string.
    var versionString: String { get }
}

// MARK: - DefaultAppInfoService

/// The default implementation of `AppInfoService`.
///
public class DefaultAppInfoService: AppInfoService {
    // MARK: Properties

    /// Additional build details to include in the app info string.
    private let appAdditionalInfo: AppAdditionalInfo

    /// The app's bundle.
    private let bundle: BundleProtocol

    /// A closure that provides the service to get server-specified configuration when needed.
    /// This is a closure rather than a stored service to avoid circular dependencies.
    private let configServiceProvider: () -> ConfigService?

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
    ///   - configServiceProvider: A closure that provides the service to get server-specified
    ///     configuration when needed. This is lazily evaluated to allow configService to be
    ///     injected after initialization, breaking circular dependencies.
    ///   - systemDevice: An object used to retrieve information about this device.
    ///   - timeProvider: The service used to get the present time.
    ///
    public init(
        appAdditionalInfo: AppAdditionalInfo = DefaultAppAdditionalInfo(),
        bundle: BundleProtocol = Bundle.main,
        configServiceProvider: @escaping () -> ConfigService?,
        systemDevice: SystemDevice = UIDevice.current,
        timeProvider: TimeProvider = CurrentTime(),
    ) {
        self.appAdditionalInfo = appAdditionalInfo
        self.bundle = bundle
        self.configServiceProvider = configServiceProvider
        self.systemDevice = systemDevice
        self.timeProvider = timeProvider
    }
}

// MARK: - DefaultAppInfoService + AppInfoService

public extension DefaultAppInfoService {
    /// A single string containing relevant app information for debugging and logging purposes.
    var appInfoString: String {
        get async {
            await [
                copyrightString,
                "",
                appNameAndVersionString,
                bundleString,
                deviceString,
                systemOSString,
                sdkString,
                serverString,
                additionalInfoString,
            ]
            .compactMap(\.self)
            .joined(separator: "\n")
        }
    }

    /// The application information without including copyright information.
    var appInfoWithoutCopyrightString: String {
        get async {
            await [
                appNameAndVersionString,
                bundleString,
                deviceString,
                systemOSString,
                sdkString,
                serverString,
                additionalInfoString,
            ]
            .compactMap(\.self)
            .joined(separator: "\n")
        }
    }

    /// The copyright information for the app.
    var copyrightString: String {
        "© Bitwarden Inc. 2015\(String.enDash)\(Calendar.current.component(.year, from: timeProvider.presentTime))"
    }

    /// A string providing the app version.
    var versionString: String {
        "\(Localizations.version): \(bundle.appVersion) (\(bundle.buildNumber))"
    }

    // MARK: Private

    /// A string containing any additional build info.
    private var additionalInfoString: String? {
        guard !appAdditionalInfo.ciBuildInfo.isEmpty else { return nil }
        return appAdditionalInfo.ciBuildInfo
            .filter { !$0.value.isEmpty }
            .map { key, value in
                "\(key): \(value)"
            }
            .joined(separator: "\n")
    }

    /// A string containing the app name and version
    private var appNameAndVersionString: String {
        "📝 \(bundle.appName) \(bundle.appVersion) (\(bundle.buildNumber))"
    }

    /// A string containing the bundle info.
    private var bundleString: String {
        "📦 Bundle: \(bundle.bundleIdentifier ?? "Unknown")"
    }

    /// A string containing the device info.
    private var deviceString: String {
        "📱 Device: \(systemDevice.modelIdentifier)"
    }

    /// A string containing the SDK version info.
    private var sdkString: String? {
        let version = appAdditionalInfo.sdkVersion
        guard version != "Unknown", !version.isEmpty else { return nil }
        return "🦀 SDK: \(version)"
    }

    /// A string containing the server version info.
    private var serverString: String? {
        get async {
            guard let configService = configServiceProvider(),
                  let serverConfig = await configService.getConfig() else {
                return nil
            }
            let serverName = serverConfig.server?.name
            let serverVersion = serverConfig.version
            let cloudRegion = serverConfig.environment?.cloudRegion.map { "@ \($0)" }
            return [
                "🌩️ Server:",
                serverName,
                serverVersion,
                cloudRegion,
            ]
            .compactMap(\.self)
            .joined(separator: " ")
        }
    }

    /// A string containing the OS info.
    private var systemOSString: String {
        "🍏 System: \(systemDevice.systemName) \(systemDevice.systemVersion)"
    }
}
