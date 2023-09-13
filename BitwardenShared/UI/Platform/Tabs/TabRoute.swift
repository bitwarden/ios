import UIKit

// MARK: - TabRoute

/// The enumeration of tabs displayed by the application. The raw value must map to the index of the tab as it is
/// displayed within a tab bar controller.
///
public enum TabRoute: Int, Equatable, Hashable {
    /// The generator tab.
    case generator = 2

    /// The send tab.
    case send = 1

    /// The settings tab.
    case settings = 3

    /// The vault tab.
    case vault = 0
}

// MARK: - TabRepresentable

extension TabRoute: TabRepresentable {
    public var image: UIImage? {
        switch self {
        case .generator: return UIImage(systemName: "arrow.triangle.2.circlepath")
        case .send: return UIImage(systemName: "paperplane")
        case .settings: return UIImage(systemName: "gearshape")
        case .vault: return UIImage(systemName: "lock")
        }
    }

    public var selectedImage: UIImage? {
        switch self {
        case .generator: return UIImage(systemName: "arrow.triangle.2.circlepath.circle.fill")
        case .send: return UIImage(systemName: "paperplane.fill")
        case .settings: return UIImage(systemName: "gearshape.fill")
        case .vault: return UIImage(systemName: "lock.fill")
        }
    }

    public var title: String {
        switch self {
        case .generator: return "Generator"
        case .send: return "Send"
        case .settings: return "Settings"
        case .vault: return "My Vault"
        }
    }
}
