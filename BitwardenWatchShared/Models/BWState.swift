import Foundation

// MARK: - BWState

/// The state of the watch app.
///
public enum BWState: Int, Codable {
    case valid = 0
    case needLogin = 1
    case needPremium = 2
    case needSetup = 3
    case need2FAItem = 4
    case syncing = 5
    case needDeviceOwnerAuth = 7
    case debug = 255

    public var isDestructive: Bool {
        self == .needSetup || self == .needLogin || self == .needPremium || self == .need2FAItem
    }
}
