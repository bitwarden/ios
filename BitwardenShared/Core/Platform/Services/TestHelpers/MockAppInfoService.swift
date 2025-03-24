@testable import BitwardenShared

class MockAppInfoService: AppInfoService {
    var appInfoString = """
    © Bitwarden Inc. 2015–2025

    Version: 1.0 (1)
    📱 iPhone14,2 🍏 iOS 16.4 📦 Production
    """
    var copyrightString = "© Bitwarden Inc. 2015–2025"
    var versionString = "1.0 (1)"
}
