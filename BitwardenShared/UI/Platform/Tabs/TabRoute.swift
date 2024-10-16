import UIKit

// MARK: - TabRoute

/// The enumeration of tabs displayed by the application.
///
public enum TabRoute: Equatable, Hashable {
    /// The vault tab.
    case vault(VaultRoute)

    /// The send tab.
    case send

    /// The generator tab.
    case generator(GeneratorRoute)

    /// The settings tab.
    case settings(SettingsRoute)
}

// MARK: - TabRepresentable

extension TabRoute: TabRepresentable {
    public var image: UIImage? {
        switch self {
        case .generator: return Asset.Images.restartFilled.image
        case .send: return Asset.Images.sendFilled.image
        case .settings: return Asset.Images.cogFilled.image
        case .vault: return Asset.Images.lockedFilled.image
        }
    }

    public var index: Int {
        switch self {
        case .vault: return 0
        case .send: return 1
        case .generator: return 2
        case .settings: return 3
        }
    }

    public var selectedImage: UIImage? {
        switch self {
        case .generator: return Asset.Images.restartFilled.image
        case .send: return Asset.Images.sendFilled.image
        case .settings: return Asset.Images.cogFilled.image
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
