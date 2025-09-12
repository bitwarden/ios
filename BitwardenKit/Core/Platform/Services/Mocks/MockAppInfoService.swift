import BitwardenKit

public class MockAppInfoService: AppInfoService {
    public var appInfoString = """
    © Bitwarden Inc. 2015–2025

    Version: 1.0 (1)
    📱 iPhone14,2 🍏 iOS 16.4 📦 Production
    """
    public var appInfoWithoutCopyrightString = """
    Version: 1.0 (1)
    📱 iPhone14,2 🍏 iOS 16.4 📦 Production
    """
    public var copyrightString = "© Bitwarden Inc. 2015–2025"
    public var versionString = "1.0 (1)"

    public init() {}
}
