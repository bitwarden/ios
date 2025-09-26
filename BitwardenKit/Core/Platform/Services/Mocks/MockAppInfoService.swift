import BitwardenKit

public class MockAppInfoService: AppInfoService {
    public var appInfoString = """
    © Bitwarden Inc. 2015–2025

    📝 Bitwarden 1.0 (1)
    📦 Bundle: com.8bit.bitwarden
    📱 Device: iPhone14,2
    🍏 System: iOS 16.4
    """
    public var appInfoWithoutCopyrightString = """
    📝 Bitwarden 1.0 (1)
    📦 Bundle: com.8bit.bitwarden
    📱 Device: iPhone14,2
    🍏 System: iOS 16.4
    """
    public var copyrightString = "© Bitwarden Inc. 2015–2025"
    public var versionString = "1.0 (1)"

    public init() {}
}
