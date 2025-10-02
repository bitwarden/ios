import BitwardenResources
import UIKit

// MARK: - TabRoute

/// The enumeration of tabs displayed by the application.
///
public enum TabRoute: Equatable, Hashable {
    /// The verification codes
    case itemList(ItemListRoute)

    /// The settings tab.
    case settings(SettingsRoute)

    public var accessibilityIdentifier: String {
        switch self {
        case .itemList: return "VerificationCodesTabButton"
        case .settings: return "SettingsTabButton"
        }
    }
}

// MARK: - TabRepresentable

extension TabRoute: TabRepresentable {
    public var image: UIImage? {
        switch self {
        case .itemList: return SharedAsset.Icons.recoveryCodes.image
        case .settings: return SharedAsset.Icons.gearFilled24.image
        }
    }

    public var index: Int {
        switch self {
        case .itemList: return 0
        case .settings: return 1
        }
    }

    public var selectedImage: UIImage? {
        switch self {
        case .itemList: return SharedAsset.Icons.recoveryCodes.image
        case .settings: return SharedAsset.Icons.gearFilled24.image
        }
    }

    public var title: String {
        switch self {
        case .itemList: return Localizations.verificationCodes
        case .settings: return Localizations.settings
        }
    }
}
