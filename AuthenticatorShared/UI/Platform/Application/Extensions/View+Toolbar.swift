import BitwardenResources
import SwiftUI

/// Helper functions extended off the `View` protocol for supporting buttons and menus in toolbars.
///
extension View {
    // MARK: Buttons

    /// Returns a toolbar button configured for adding an item.
    ///
    /// - Parameters:
    ///   - hidden: Whether to hide the toolbar item.
    ///   - action: The action to perform when the button is tapped.
    /// - Returns: A `Button` configured for adding an item.
    ///
    func addToolbarButton(hidden: Bool = false, action: @escaping () -> Void) -> some View {
        toolbarButton(asset: Asset.Images.plus, label: Localizations.add, action: action)
            .hidden(hidden)
            .accessibilityIdentifier("AddItemButton")
    }

    /// Returns a toolbar button configured for cancelling an operation in a view.
    ///
    /// - Parameter action: The action to perform when the button is tapped.
    /// - Returns: A `Button` configured for cancelling an operation in a view.
    ///
    func cancelToolbarButton(action: @escaping () -> Void) -> some View {
        toolbarButton(asset: Asset.Images.cancel, label: Localizations.cancel, action: action)
            .accessibilityIdentifier("CancelButton")
    }

    /// Returns a toolbar button configured for closing a view.
    ///
    /// - Parameter action: The action to perform when the button is tapped.
    /// - Returns: A `Button` configured for closing a view.
    ///
    func closeToolbarButton(action: @escaping () -> Void) -> some View {
        toolbarButton(asset: Asset.Images.cancel, label: Localizations.close, action: action)
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
            .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
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
            Image(asset: Asset.Images.verticalKabob, label: Text(Localizations.options))
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

    /// A `ToolbarItem` for views with a dismiss button.
    ///
    /// - Parameter action: The action to perform when the dismiss button is tapped.
    /// - Returns: A `ToolbarItem` with a dismiss button.
    ///
    func cancelToolbarItem(_ action: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            cancelToolbarButton(action: action)
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
}
