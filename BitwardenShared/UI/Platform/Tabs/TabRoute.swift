import BitwardenKit
import BitwardenResources
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
        case .generator:
            SharedAsset.Icons.TabBar.generatorIdle.image
        case .send:
            SharedAsset.Icons.TabBar.sendIdle.image
        case .settings:
            SharedAsset.Icons.TabBar.settingsIdle.image
        case .vault:
            SharedAsset.Icons.TabBar.vaultIdle.image
        }
    }

    public var index: Int {
        switch self {
        case .vault:
            0
        case .send:
            1
        case .generator:
            2
        case .settings:
            3
        }
    }

    public var selectedImage: UIImage? {
        switch self {
        case .generator:
            SharedAsset.Icons.TabBar.generatorActive.image
        case .send:
            SharedAsset.Icons.TabBar.sendActive.image
        case .settings:
            SharedAsset.Icons.TabBar.settingsActive.image
        case .vault:
            SharedAsset.Icons.TabBar.vaultActive.image
        }
    }

    public var title: String {
        switch self {
        case .generator:
            Localizations.generator
        case .send:
            Localizations.send
        case .settings:
            Localizations.settings
        case .vault:
            Localizations.myVault
        }
    }
}
