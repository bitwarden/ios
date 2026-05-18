import BitwardenKit
import Foundation

public class MockAppInfoService: AppInfoService {
    public var appInfoStringValue = """
    © Bitwarden Inc. 2015\(String.enDash)\(Calendar.current.component(.year, from: Date.now))

    📝 Bitwarden 1.0 (1)
    📦 Bundle: com.8bit.bitwarden
    📱 Device: iPhone14,2
    🍏 System: iOS 16.4
    """
    public var appInfoWithoutCopyrightStringValue = """
    📝 Bitwarden 1.0 (1)
    📦 Bundle: com.8bit.bitwarden
    📱 Device: iPhone14,2
    🍏 System: iOS 16.4
    """
    public var copyrightString = """
    © Bitwarden Inc. 2015\(String.enDash)\(Calendar.current.component(.year, from: Date.now))
    """
    public var isBetaBuild = false
    public var versionString = "1.0 (1)"

    public var appInfoString: String {
        get async {
            appInfoStringValue
        }
    }

    public var appInfoWithoutCopyrightString: String {
        get async {
            appInfoWithoutCopyrightStringValue
        }
    }

    public init() {}
}
