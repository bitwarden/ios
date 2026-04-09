import BitwardenResources
import SwiftUI

/// Helper functions extended off the `View` protocol for supporting buttons and menus in toolbars.
///
public extension View {
    // MARK: Buttons

    /// Returns a toolbar button configured for adding an item.
    ///
    /// - Parameters:
    ///   - hidden: Whether to hide the toolbar item.
    ///   - action: The action to perform when the button is tapped.
    /// - Returns: A `Button` configured for adding an item.
    ///
    func addToolbarButton(hidden: Bool = false, action: @escaping () -> Void) -> some View {
        toolbarButton(asset: SharedAsset.Icons.plus16, label: Localizations.add, action: action)
            .hidden(hidden)
            .accessibilityIdentifier("AddItemButton")
    }

    /// Returns a toolbar button configured for navigating back within a view flow.
    ///
    /// - Parameters:
    ///   - hidden: Whether to hide the toolbar item.
    ///   - action: The action to perform when the button is tapped.
    /// - Returns: A `Button` configured for navigating back.
    ///
    func backToolbarButton(hidden: Bool = false, action: @escaping () -> Void) -> some View {
        if #available(iOS 26, *) {
            return Button(action: action) {
                Label(Localizations.back, systemImage: "chevron.backward")
            }
            .hidden(hidden)
            .accessibilityIdentifier("BackButton")
            .accessibilityLabel(Localizations.back)
        }
        return Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                Text(Localizations.back)
            }
        }
        .buttonStyle(.toolbar)
        .hidden(hidden)
        .accessibilityIdentifier("BackButton")
    }

    /// Returns a toolbar button configured for cancelling an operation in a view.
    ///
    /// - Parameters:
    ///   - hidden: Whether to hide the toolbar item.
    ///   - action: The action to perform when the button is tapped.
    /// - Returns: A `Button` configured for cancelling an operation in a view.
    ///
    func cancelToolbarButton(hidden: Bool = false, action: @escaping () -> Void) -> some View {
        if #available(iOS 26, *) {
            return Button(role: .cancel, action: action)
                .hidden(hidden)
                .accessibilityIdentifier("CancelButton")
                .accessibilityLabel(Localizations.cancel)
        }
        return toolbarButton(Localizations.cancel, action: action)
            .hidden(hidden)
            .accessibilityIdentifier("CancelButton")
    }

    /// Returns a toolbar button configured for closing a view.
    ///
    /// - Parameter action: The action to perform when the button is tapped.
    /// - Returns: A `Button` configured for closing a view.
    ///
    func closeToolbarButton(action: @escaping () -> Void) -> some View {
        if #available(iOS 26, *) {
            return Button(role: .close, action: action)
                .accessibilityIdentifier("CloseButton")
                .accessibilityLabel(Localizations.close)
        }
        return toolbarButton(Localizations.close, action: action)
            .accessibilityIdentifier("CloseButton")
    }

    /// Returns a toolbar button configured for editing an item.
    ///
    /// - Parameter action: The action to perform when the button is tapped.
    /// - Returns: A `Button` configured for closing a view.
    ///
    func editToolbarButton(action: @escaping () -> Void) -> some View {
        toolbarButton(Localizations.edit, action: action)
            .accessibilityIdentifier("EditItemButton")
    }

    /// Returns a `Button` that displays a text label for use in a toolbar, highlighting the primary action.
    ///
    /// - Parameters:
    ///   - label: The label associated with the image, used as an accessibility label.
    ///   - action: The action to perform when the button is tapped.
    /// - Returns: A `Button` for displaying an image in a toolbar.
    ///
    func primaryActionToolbarButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .styleGuide(.body, weight: .semibold)
        }
        .buttonStyle(.toolbar)
        // Ideally we would set both `minHeight` and `minWidth` to 44. Setting `minWidth` causes
        // padding to be applied equally on both sides of the image. This results in extra padding
        // along the margin though.
        .frame(minHeight: 44)
    }

    /// Returns a `Button` that displays a text label for use in a toolbar, highlighting the primary action.
    ///
    /// - Parameters:
    ///   - label: The label associated with the image, used as an accessibility label.
    ///   - action: The action to perform when the button is tapped.
    /// - Returns: A `Button` for displaying an image in a toolbar.
    ///
    func primaryActionToolbarButton(_ label: String, action: @escaping () async -> Void) -> some View {
        AsyncButton(action: action) {
            Text(label)
                .styleGuide(.body, weight: .semibold)
        }
        .buttonStyle(.toolbar)
        // Ideally we would set both `minHeight` and `minWidth` to 44. Setting `minWidth` causes
        // padding to be applied equally on both sides of the image. This results in extra padding
        // along the margin though.
        .frame(minHeight: 44)
    }

    /// Returns a toolbar button configured for saving an item.
    ///
    /// - Parameter action: The action to perform when the save button is tapped.
    /// - Returns: A `Button` configured for saving an item.
    ///
    func saveToolbarButton(action: @escaping () async -> Void) -> some View {
        if #available(iOS 26, *) {
            return Button(role: .confirm) {
                Task {
                    await action()
                }
            }
            .accessibilityIdentifier("SaveButton")
            .accessibilityLabel(Localizations.save)
        }
        return toolbarButton(Localizations.save, action: action)
            .accessibilityIdentifier("SaveButton")
    }

    /// Returns a `Button` that displays an image for use in a toolbar.
    ///
    /// - Parameters:
    ///   - asset: The image asset to show in the button.
    ///   - label: The label associated with the image, used as an accessibility label.
    ///   - action: The action to perform when the button is tapped.
    /// - Returns: A `Button` for displaying an image in a toolbar.
    ///
    func toolbarButton(asset: SharedImageAsset, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(asset: asset, label: Text(label))
                .imageStyle(.toolbarIcon)
        }
        .buttonStyle(.toolbar)
        // Ideally we would set both `minHeight` and `minWidth` to 44. Setting `minWidth` causes
        // padding to be applied equally on both sides of the image. This results in extra padding
        // along the margin though.
        .frame(minHeight: 44)
    }

    /// Returns a `Button` that displays a text label for use in a toolbar.
    ///
    /// - Parameters:
    ///   - label: The label associated with the image, used as an accessibility label.
    ///   - action: The action to perform when the button is tapped.
    /// - Returns: A `Button` for displaying an image in a toolbar.
    ///
    func toolbarButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.toolbar)
            // Ideally we would set both `minHeight` and `minWidth` to 44. Setting `minWidth` causes
            // padding to be applied equally on both sides of the image. This results in extra padding
            // along the margin though.
            .frame(minHeight: 44)
            .fixedSize()
    }

    /// Returns a `Button` that displays a text label for use in a toolbar.
    ///
    /// - Parameters:
    ///   - label: The label to display in the button.
    ///   - action: The action to perform when the button is tapped.
    /// - Returns: A `Button` for displaying a text label in a toolbar.
    ///
    func toolbarButton(_ label: String, action: @escaping () async -> Void) -> some View {
        AsyncButton(label, action: action)
            .buttonStyle(.toolbar)
            // Ideally we would set both `minHeight` and `minWidth` to 44. Setting `minWidth` causes
            // padding to be applied equally on both sides of the image. This results in extra padding
            // along the margin though.
            .frame(minHeight: 44)
            .fixedSize()
    }

    // MARK: Menus

    /// Returns a `Menu` for use in a toolbar.
    ///
    /// - Parameter content: The content to display in the menu when the more icon is tapped.
    /// - Returns: A `Menu` for use in a toolbar.
    ///
    func optionsToolbarMenu(@ViewBuilder content: () -> some View) -> some View {
        Menu {
            content()
        } label: {
            Image(asset: SharedAsset.Icons.ellipsisVertical24, label: Text(Localizations.options))
                .imageStyle(.toolbarIcon)
                .accessibilityIdentifier("HeaderBarOptionsButton")
        }
        // Ideally we would set both `minHeight` and `minWidth` to 44. Setting `minWidth` causes
        // padding to be applied equally on both sides of the image. This results in extra padding
        // along the margin though.
        .frame(height: 44)
    }

    // MARK: Toolbar Items

    /// A `ToolbarItem` for views with an add button.
    ///
    /// - Parameters:
    ///   - hidden: Whether to hide the toolbar item.
    ///   - action: The action to perform when the add button is tapped.
    /// - Returns: A `ToolbarItem` with an add button.
    ///
    func addToolbarItem(hidden: Bool = false, _ action: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            addToolbarButton(hidden: hidden, action: action)
        }
    }

    /// A `ToolbarItem` for views with a cancel text button.
    ///
    /// - Parameters:
    ///   - hidden: Whether to hide the toolbar item.
    ///   - action: The action to perform when the cancel button is tapped.
    /// - Returns: A `ToolbarItem` with a dismiss button.
    ///
    func cancelToolbarItem(hidden: Bool = false, _ action: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !hidden {
                cancelToolbarButton(hidden: hidden, action: action)
            }
        }
    }

    /// A `ToolbarItem` for views with a close text button.
    ///
    /// - Parameters:
    ///   - hidden: Whether to hide the toolbar item.
    ///   - action: The action to perform when the close button is tapped.
    /// - Returns: A `ToolbarItem` with a dismiss button.
    ///
    func closeToolbarItem(hidden: Bool = false, _ action: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !hidden {
                closeToolbarButton(action: action)
            }
        }
    }

    /// A `ToolbarItem` for views with a more button.
    ///
    /// - Parameter content: The content to display in the menu when the more icon is tapped.
    /// - Returns: A `ToolbarItem` with a more button that shows a menu.
    ///
    func optionsToolbarItem(@ViewBuilder _ content: () -> some View) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            optionsToolbarMenu(content: content)
        }
    }

    /// A `ToolbarItem` for views with a save button.
    ///
    /// - Parameter action: The action to perform when the save button is tapped.
    /// - Returns: A `ToolbarItem` with a save button.
    ///
    func saveToolbarItem(_ action: @escaping () async -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            saveToolbarButton(action: action)
        }
    }

    /// A `ToolbarContent` that adjusts the navigation bar to display a large title on the leading
    /// edge of the navigation bar and hides the centered title. This has the appearance of a large
    /// title navigation bar without the extra padding above the title and overall height similar to
    /// an inline navigation bar title.
    ///
    /// - Parameters:
    ///   - title: The navigation bar's title.
    ///   - hidden: Whether the navigation bar updates should be hidden.
    /// - Returns: A `ToolbarContent` that adjusts the navigation bar to display a large title on
    ///     the leading edge.
    ///
    @ToolbarContentBuilder
    func largeNavigationTitleToolbarItem(_ title: String, hidden: Bool = false) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !hidden, !shouldHideLargeNavigationToolbarItem {
                Text(title)
                    .styleGuide(.largeTitle, weight: .semibold)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("HeaderBarPageTitle")
            }
        }

        ToolbarItem(placement: .principal) {
            if !hidden, !shouldHideLargeNavigationToolbarItem {
                // Hide the centered navigation title view with an empty view.
                Text("")
                    .accessibilityHidden(true)
            }
        }
    }

    /// A `ToolbarItemGroup` consisting of two items, alfa and bravo, that change position depending on
    /// the version of iOS being used.
    ///
    /// On iOS versions before 26, the order is alfa - bravo.
    ///
    /// On iOS versions from 26 on, the order is bravo - alfa.
    ///
    /// - Parameters:
    ///   - placement: The toolbar item placement for the `ToolbarItemGroup`
    ///   - alfa: The item that goes on the left before iOS 26
    ///   - bravo: The item that goes on the left from iOS 26 onward
    func versionDependentOrderingToolbarItemGroup(
        placement: ToolbarItemPlacement = .topBarTrailing,
        @ViewBuilder alfa: () -> some View,
        @ViewBuilder bravo: () -> some View,
    ) -> some ToolbarContent {
        ToolbarItemGroup(placement: placement) {
            if #unavailable(iOS 26) {
                bravo()
            }
            alfa()
            if #available(iOS 26, *) {
                bravo()
            }
        }
    }
}

// MARK: Private

extension View {
    /// Whether the navigation bar's large title displayed on the leading edge should be hidden.
    /// iPadOS 18+ moves the tab bar into the navigation bar. Since the selected tab matches the
    /// navigation bar's title both don't need to be displayed. This fixes an issue where even
    /// though the navigation bar was displayed inline, there was still extra padding in the
    /// navigation bar where the centered title would be displayed below the tab bar.
    ///
    /// As well, because iOS 26 (with Liquid Glass) changes how toolbar items are displayed, we
    /// should revert to native behavior, and only have the title centered.
    private var shouldHideLargeNavigationToolbarItem: Bool {
        guard #available(iOS 18, *) else { return false }
        guard #unavailable(iOS 26) else { return true }
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
