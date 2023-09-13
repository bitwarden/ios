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
        case .generator: return Asset.Images.restart.image
        case .send: return Asset.Images.send.image
        case .settings: return Asset.Images.gear.image
        case .vault: return Asset.Images.locked.image
        }
    }

    public var selectedImage: UIImage? {
        switch self {
        case .generator: return Asset.Images.restartFilled.image
        case .send: return Asset.Images.sendFilled.image
        case .settings: return Asset.Images.gearFilled.image
        case .vault: return Asset.Images.lockedFilled.image
        }
    }

    public var title: String {
        switch self {
        case .generator: return Localizations.generator
        case .send: return Localizations.send
        case .settings: return Localizations.settings
        case .vault: return Localizations.myVault
        }
    }
}
