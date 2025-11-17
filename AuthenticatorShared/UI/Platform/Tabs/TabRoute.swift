import BitwardenKit
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
        case .itemList: "VerificationCodesTabButton"
        case .settings: "SettingsTabButton"
        }
    }
}

// MARK: - TabRepresentable

extension TabRoute: TabRepresentable {
    public var image: UIImage? {
        switch self {
        case .itemList: SharedAsset.Icons.recoveryCodes.image
        case .settings: SharedAsset.Icons.gearFilled24.image
        }
    }

    public var index: Int {
        switch self {
        case .itemList: 0
        case .settings: 1
        }
    }

    public var selectedImage: UIImage? {
        switch self {
        case .itemList: SharedAsset.Icons.recoveryCodes.image
        case .settings: SharedAsset.Icons.gearFilled24.image
        }
    }

    public var title: String {
        switch self {
        case .itemList: Localizations.verificationCodes
        case .settings: Localizations.settings
        }
    }
}
