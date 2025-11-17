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
    public nonisolated(unsafe) static var animated = true

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
    public nonisolated(unsafe) static var sizeCategory: UIContentSizeCategory?
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
    @MainActor
    public static func applyDefaultAppearances() { // swiftlint:disable:this function_body_length
        let bodyFont = UIFontMetrics(forTextStyle: .body).scaledFont(
            for: FontFamily.DMSans.regular.font(size: 15),
        )
        let bodyBoldFont = UIFontMetrics(forTextStyle: .body).scaledFont(
            for: FontFamily.DMSans.bold.font(size: 15),
        )
        let largeTitleFont = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(
            for: FontFamily.DMSans.bold.font(size: 26),
        )
        let iconBadgeBackground = SharedAsset.Colors.iconBadgeBackground.color
        let iconBadgeTextAttributes: [NSAttributedString.Key: Any] = [
            .font: FontFamily.DMSans.bold.font(size: 12),
            .foregroundColor: SharedAsset.Colors.iconBadgeForeground.color,
        ]

        let navigationBarAppearance = UINavigationBarAppearance()
        if #unavailable(iOS 26) {
            // With Liquid Glass, we no longer make the navigation bar distinct with its own color
            navigationBarAppearance.backgroundColor = SharedAsset.Colors.backgroundSecondary.color
        }
        navigationBarAppearance.buttonAppearance.normal.titleTextAttributes = [.font: bodyFont]
        navigationBarAppearance.largeTitleTextAttributes = [.font: largeTitleFont]
        navigationBarAppearance.titleTextAttributes = [.font: bodyBoldFont]
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance

        UIPageControl.appearance().currentPageIndicatorTintColor = SharedAsset.Colors.textPrimary.color
        UIPageControl.appearance().pageIndicatorTintColor = SharedAsset.Colors.textPrimary.color.withAlphaComponent(0.3)

        UIBarButtonItem.appearance().tintColor = SharedAsset.Colors.textInteraction.color

        // Make the tab bar opaque.
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = SharedAsset.Colors.backgroundSecondary.color
        tabBarAppearance.compactInlineLayoutAppearance.normal.badgeBackgroundColor = iconBadgeBackground
        tabBarAppearance.compactInlineLayoutAppearance.normal.badgeTextAttributes = iconBadgeTextAttributes
        tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: SharedAsset.Colors.iconSecondary.color,
        ]
        tabBarAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: SharedAsset.Colors.iconPrimary.color,
        ]
        tabBarAppearance.inlineLayoutAppearance.normal.badgeBackgroundColor = iconBadgeBackground
        tabBarAppearance.inlineLayoutAppearance.normal.badgeTextAttributes = iconBadgeTextAttributes
        tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: SharedAsset.Colors.iconSecondary.color,
        ]
        tabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: SharedAsset.Colors.iconPrimary.color,
        ]
        tabBarAppearance.stackedLayoutAppearance.normal.badgeBackgroundColor = iconBadgeBackground
        tabBarAppearance.stackedLayoutAppearance.normal.badgeTextAttributes = iconBadgeTextAttributes
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: SharedAsset.Colors.iconSecondary.color,
        ]
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: SharedAsset.Colors.iconPrimary.color,
        ]
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = SharedAsset.Colors.iconSecondary.color
        UITabBar.appearance().unselectedItemTintColor = SharedAsset.Colors.iconPrimary.color

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = Localizations.cancel
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(
            [.font: FontFamily.DMSans.regular.font(size: 15)],
            for: .normal,
        )

        UISearchBar.appearance().tintColor = SharedAsset.Colors.textInteraction.color
        // Explicitly tint the image so that it does not assume the tint color assigned to the entire search bar.
        let image = SharedAsset.Icons.circleX16.image
        let tintedImage = image.withTintColor(SharedAsset.Colors.textSecondary.color, renderingMode: .alwaysOriginal)
        UISearchBar.appearance().setImage(tintedImage, for: .clear, state: .normal)
        UISearchBar.appearance().setImage(SharedAsset.Icons.search16.image, for: .search, state: .normal)

        // Adjust the appearance of `UITextView` for `BitwardenUITextField` instances on iOS 15.
        UITextView.appearance().isScrollEnabled = false
        UITextView.appearance().backgroundColor = .clear
        UITextView.appearance().textContainerInset = .zero
        UITextView.appearance().textContainer.lineFragmentPadding = 0
    }
}

// swiftlint:enable type_name
