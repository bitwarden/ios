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

        let tabBarAppearance = UITabBarAppearance()
        let selectedIconColor = Asset.Colors.primaryBitwarden.color
        let textAttributes = [NSAttributedString.Key.foregroundColor: Asset.Colors.primaryBitwarden.color]

        tabBarAppearance.compactInlineLayoutAppearance.selected.iconColor = selectedIconColor
        tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = textAttributes
        tabBarAppearance.inlineLayoutAppearance.selected.iconColor = selectedIconColor
        tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = textAttributes
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedIconColor
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = textAttributes
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        UISearchBar.appearance().setImage(Asset.Images.magnifyingGlass.image, for: .search, state: .normal)
    }
}

// swiftlint:enable type_name
