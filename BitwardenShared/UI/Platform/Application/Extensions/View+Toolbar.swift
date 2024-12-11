import SwiftUI

/// Helper functions extended off the `View` protocol for supporting buttons and menus in toolbars.
///
extension View {
    // MARK: Buttons

    /// Returns a toolbar button configured for cancelling an operation in a view.
    ///
    /// - Parameter action: The action to perform when the button is tapped.
    /// - Returns: A `Button` configured for cancelling an operation in a view.
    ///
    func cancelToolbarButton(action: @escaping () -> Void) -> some View {
        toolbarButton(Localizations.cancel, action: action)
            .accessibilityIdentifier("CancelButton")
    }

    /// Returns a toolbar button configured for closing a view.
    ///
    /// - Parameter action: The action to perform when the button is tapped.
    /// - Returns: A `Button` configured for closing a view.
    ///
    func closeToolbarButton(action: @escaping () -> Void) -> some View {
        toolbarButton(Localizations.close, action: action)
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

    /// Returns a toolbar button configured for saving an item.
    ///
    /// - Parameter action: The action to perform when the save button is tapped.
    /// - Returns: A `Button` configured for saving an item.
    ///
    func saveToolbarButton(action: @escaping () async -> Void) -> some View {
        toolbarButton(Localizations.save, action: action)
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
    func toolbarButton(asset: ImageAsset, label: String, action: @escaping () -> Void) -> some View {
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

    /// Returns a `Button` that displays an image for use in a toolbar.
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
            Image(asset: Asset.Images.ellipsisVertical24, label: Text(Localizations.options))
                .imageStyle(.toolbarIcon)
                .accessibilityIdentifier("HeaderBarOptionsButton")
        }
        // Ideally we would set both `minHeight` and `minWidth` to 44. Setting `minWidth` causes
        // padding to be applied equally on both sides of the image. This results in extra padding
        // along the margin though.
        .frame(height: 44)
    }

    // MARK: Toolbar Items

    /// A `ToolbarItem` for views with a cancel text button.
    ///
    /// - Parameter action: The action to perform when the cancel button is tapped.
    /// - Returns: A `ToolbarItem` with a dismiss button.
    ///
    func cancelToolbarItem(_ action: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            cancelToolbarButton(action: action)
        }
    }

    /// A `ToolbarItem` for views with a close text button.
    ///
    /// - Parameter action: The action to perform when the close button is tapped.
    /// - Returns: A `ToolbarItem` with a dismiss button.
    ///
    func closeToolbarItem(_ action: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            closeToolbarButton(action: action)
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
}
