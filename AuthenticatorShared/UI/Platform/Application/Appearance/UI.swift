import BitwardenResources
import Foundation
import SwiftUI
import UIKit

// swiftlint:disable type_name

/// Utility and factory methods for building out user interfaces.
///
public enum UI {
    // MARK: Utilities

    /// App-wide flag that allows disabling UI animations for testing.
    public static var animated = true

    /// The language code at initialization.
    public static var initialLanguageCode: String? {
        get {
            Resources.initialLanguageCode
        }
        set {
            Resources.initialLanguageCode = newValue
        }
    }

    #if DEBUG
    /// App-wide flag that allows overriding the OS level sizeCategory for testing.
    public static var sizeCategory: UIContentSizeCategory?
    #endif

    // MARK: Factories

    /// Returns the specified duration when `UI.animated` is `true`, or `0.0` when `UI.animated`
    /// is `false`.
    ///
    /// - Parameter duration: The animation `TimeInterval` when `UI.animation` is `true`.
    ///
    /// - Returns: The duration based on whether animations are disabled or not.
    ///
    public static func duration(_ duration: TimeInterval) -> TimeInterval {
        animated ? duration : 0.0
    }

    /// Returns a `DispatchTime` with the number of seconds added to `DispatchTime.now` when
    /// `UI.animation` is `true` or `DispatchTime.now` when `UI.animation` is `false`.
    ///
    /// - Parameter after: The number of seconds to add to `DispatchTime.now` when `UI.animation` is
    ///     `true`.
    ///
    /// - Returns: The `DispatchTime` with `after` seconds added to it if animations are enabled or
    ///     `DispatchTime.now` if not.
    ///
    public static func after(_ after: TimeInterval) -> DispatchTime {
        animated ? .now() + after : .now()
    }

    /// Sets up the default global appearances used throughout the app.
    ///
    public static func applyDefaultAppearances() {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.backgroundColor = Asset.Colors.primaryContrastBitwarden.color
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance

        UIBarButtonItem.appearance().tintColor = Asset.Colors.primaryBitwarden.color

        // Make the tab bar opaque.
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = Asset.Colors.primaryBitwarden.color

        UISearchBar.appearance().tintColor = Asset.Colors.primaryBitwarden.color
        // Explicitly tint the image so that it does not assume the tint color assigned to the entire search bar.
        let image = Asset.Images.cancelRound.image
        let tintedImage = image.withTintColor(Asset.Colors.textSecondary.color, renderingMode: .alwaysOriginal)
        UISearchBar.appearance().setImage(tintedImage, for: .clear, state: .normal)
        UISearchBar.appearance().setImage(Asset.Images.magnifyingGlass.image, for: .search, state: .normal)

        // Adjust the appearance of `UITextView` for `BitwardenMultilineTextField` instances on
        // iOS 15.
        UITextView.appearance().isScrollEnabled = false
        UITextView.appearance().backgroundColor = .clear
        UITextView.appearance().textContainerInset = .zero
        UITextView.appearance().textContainer.lineFragmentPadding = 0

        UIPageControl.appearance().currentPageIndicatorTintColor = Asset.Colors.primaryBitwarden.color
    }

    /// Override SwiftGen's lookup function in order to determine the language manually.
    public static func localizationFunction(key: String, table: String, fallbackValue: String) -> String {
        if let languageCode = initialLanguageCode,
           let path = Bundle(for: AppProcessor.self).path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: fallbackValue, table: table)
        }
        return Bundle.main.localizedString(forKey: key, value: fallbackValue, table: table)
    }
}

// swiftlint:enable type_name
